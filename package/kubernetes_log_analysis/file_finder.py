import os
import glob
import re
from typing import List, Dict, Optional, Tuple
from litellm import completion # Import completion
from . import config # Import config

# Mapping of keywords/query types to relevant files/patterns.
# {resource_name} and {namespace} are placeholders.
QUERY_TO_FILE_MAP: Dict[str, List[str]] = {
    "node_status": [
        "nodes-wide.txt",
        "top-nodes.txt",
        "describe-nodes.txt",
        "events.txt"
    ],
    "pod_status_general": [ # For general pod status across the namespace
        "all-resources.txt", # Contains pod list
        "top-pods.txt",
        "events.txt"
    ],
    "pod_status_specific": [ # For a specific pod's status
        "describe-pods/pod-{resource_name}.txt",
        "events.txt" # LLM can filter events by pod name from this file
    ],
    "pod_logs": [
        "logs/{namespace}/{resource_name}.log",
        "describe-pods/pod-{resource_name}.txt" # Context from describe is often useful
    ],
    "events": [
        "events.txt"
    ],
    "service_status_specific": [
        "describe-services/service-{resource_name}.txt",
        "events.txt"
    ],
    "configmap_details": [
        "describe-configmaps/configmap-{resource_name}.txt",
        "configmaps.txt"
    ],
    "secret_details": [ # Be cautious with secret contents if they were ever dumped
        "describe-secrets/secret-{resource_name}.txt",
        "secrets.txt"
    ],
    # Add more mappings as needed: deployments, statefulsets, pvcs, etc.
}

# Basic regex for Kubernetes resource names (DNS-1123 subdomain)
K8S_RESOURCE_NAME_REGEX = r"[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*"

def _read_and_truncate_file_content(relative_file_path: str, full_file_path: str) -> str:
    """
    Reads file content with specific truncation rules.
    - For files in 'logs/' directory ending with '.log': reads last 500 lines.
    - For 'describe-nodes.txt': truncates if > 100k chars (first 50k, last 50k).
    - For 'describe-pods/', 'describe-services/': truncates if > 150k chars (first 75k, last 75k).
    - Other files are read fully.
    """
    filename_basename = os.path.basename(relative_file_path) 
    
    try:
        # Special handling for log files: last 500 lines
        if "logs/" in relative_file_path.lower() and relative_file_path.lower().endswith(".log"):
            with open(full_file_path, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
            if len(lines) > 500:
                print(f"Info: Reading last 500 lines of {relative_file_path} (total {len(lines)} lines).")
                return "".join(lines[-500:])
            else:
                return "".join(lines)

        # Existing character-based truncation for other large files
        with open(full_file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()

        if "describe-nodes.txt" in filename_basename and len(content) > 100000:
            content = content[:50000] + f"\n... [CONTENT OF {filename_basename} TRUNCATED DUE TO SIZE (over 100k chars)] ...\n" + content[-50000:]
            print(f"Warning: Truncated content of {relative_file_path} (describe-nodes.txt).")
        elif ("describe-pods/" in relative_file_path or "describe-services/" in relative_file_path) and len(content) > 150000:
            content = content[:75000] + f"\n... [CONTENT OF {filename_basename} TRUNCATED DUE TO SIZE (over 150k chars)] ...\n" + content[-75000:]
            print(f"Warning: Truncated content of {relative_file_path} (describe output).")
        
        return content
    except Exception as e:
        print(f"Error reading file {full_file_path}: {e}")
        return f"Error reading file {relative_file_path}: {str(e)}"

def get_all_files_in_log_dir(log_dir: str) -> List[str]:
    all_files = []
    for root, _, files in os.walk(log_dir):
        for file_name in files:
            relative_path = os.path.relpath(os.path.join(root, file_name), log_dir)
            all_files.append(relative_path)
    return all_files

def determine_query_type_and_resource(query: str) -> Tuple[Optional[str], Optional[str], Optional[str]]:
    """
    Determines query type, and optionally a resource name and namespace from the query.
    Returns: (query_type, resource_name, namespace)
    Namespace defaults to "default" if not specified, as k8s-debug.sh often targets one.
    """
    query_lower = query.lower()
    resource_name: Optional[str] = None
    namespace: str = "default" # Default namespace

    # Try to extract namespace first if specified, e.g., "in namespace testns"
    ns_match = re.search(r"in namespace (" + K8S_RESOURCE_NAME_REGEX + r")", query_lower)
    if ns_match:
        namespace = ns_match.group(1)
        query_lower = query_lower.replace(ns_match.group(0), "").strip() # Remove ns part for further parsing

    # Pod specific queries
    pod_match_logs = re.search(r"(?:log|logs|日誌)(?: for| of| for pod| of pod)? (pod )?(" + K8S_RESOURCE_NAME_REGEX + r"(?:-[a-z0-9]{5,10}-[a-z0-9]{5})?)", query_lower)
    if not pod_match_logs: # Try simpler name if generated name fails
         pod_match_logs = re.search(r"(?:log|logs|日誌)(?: for| of| for pod| of pod)? (pod )?(" + K8S_RESOURCE_NAME_REGEX + r")", query_lower)

    pod_match_status = re.search(r"(?:status|狀態|describe|描述)(?: for| of| for pod| of pod)? (pod )?(" + K8S_RESOURCE_NAME_REGEX + r"(?:-[a-z0-9]{5,10}-[a-z0-9]{5})?)", query_lower)
    if not pod_match_status:
        pod_match_status = re.search(r"(?:status|狀態|describe|描述)(?: for| of| for pod| of pod)? (pod )?(" + K8S_RESOURCE_NAME_REGEX + r")", query_lower)

    if pod_match_logs:
        resource_name = pod_match_logs.group(2) # The captured pod name
        return "pod_logs", resource_name, namespace
    if pod_match_status:
        resource_name = pod_match_status.group(2)
        return "pod_status_specific", resource_name, namespace

    # Service specific queries
    svc_match_status = re.search(r"(?:status|狀態|describe|描述)(?: for| of| for service| of service)? (service )?(" + K8S_RESOURCE_NAME_REGEX + r")", query_lower)
    if svc_match_status:
        resource_name = svc_match_status.group(2)
        return "service_status_specific", resource_name, namespace

    # ConfigMap specific queries
    cm_match_details = re.search(r"(?:details|內容|describe|描述)(?: for| of| for configmap| of configmap)? (configmap |cm )?(" + K8S_RESOURCE_NAME_REGEX + r")", query_lower)
    if cm_match_details:
        resource_name = cm_match_details.group(2)
        return "configmap_details", resource_name, namespace
        
    # General queries
    if "node" in query_lower or "節點" in query_lower:
        if "status" in query_lower or "狀態" in query_lower or "describe" in query_lower or "描述" in query_lower:
            return "node_status", None, namespace # Namespace isn't typically used for node-level cluster files
    if "pod" in query_lower: # General pod status if no specific name
        if "status" in query_lower or "狀態" in query_lower:
            return "pod_status_general", None, namespace
    if "event" in query_lower or "事件" in query_lower:
        return "events", None, namespace
    
    return None, None, None # Fallback if no specific type is matched

def find_relevant_files_with_llm(log_dir: str, user_query: str) -> Dict[str, str]:
    """
    Uses an LLM to find relevant files based on the user query and the files available in log_dir.
    """
    all_available_files = get_all_files_in_log_dir(log_dir)
    if not all_available_files:
        print("No files found in the log directory.")
        return {}

    # Prepare prompt for LLM
    # This is a simplified example; prompt engineering is key.
    # Ensure the list of files isn't too long for the context window.
    # You might need to truncate or summarize the file list if it's huge.
    MAX_FILES_IN_PROMPT = 200 # Example limit
    files_for_prompt_str = "\n".join([f"- {f}" for f in all_available_files[:MAX_FILES_IN_PROMPT]])
    if len(all_available_files) > MAX_FILES_IN_PROMPT:
        files_for_prompt_str += "\n... (and more files not listed due to prompt length)"


    system_message_file_finding = (
        "You are an expert Kubernetes assistant. Your task is to identify the most relevant "
        "files from the provided list to answer the user's query about Kubernetes logs. "
        "Respond with a list of file paths, one per line. Only list files that exist in the provided list. "
        "Prioritize files that directly address the query. The user's query is in Chinese, please understand it."
    )
    
    user_prompt_content_file_finding = (
        f"User Query: \"{user_query}\"\n\n"
        f"Available files in the log bundle:\n{files_for_prompt_str}\n\n"
        "Which of these files are most relevant to answer the query? List their paths:"
    )

    messages_for_llm_file_finding = [
        {"role": "system", "content": system_message_file_finding},
        {"role": "user", "content": user_prompt_content_file_finding}
    ]

    selected_file_paths_str = ""
    try:
        # This would be a separate LLM call, potentially using a cheaper/faster model
        # if available and suitable for this classification/selection task.
        # Reusing config.LLM_MODEL for now.
        # Note: The 'analyze_logs_with_llm' function is for the main analysis.
        # You'd call litellm.completion directly here.
        if config.GEMINI_API_KEY:
             os.environ["GOOGLE_API_KEY"] = config.GEMINI_API_KEY # Ensure API key is set

        response = completion(
            model=config.LLM_MODEL, # Or a specific model for this task
            messages=messages_for_llm_file_finding,
            api_key=config.GEMINI_API_KEY # If needed explicitly
        )
        if response.choices and response.choices[0].message and response.choices[0].message.content:
            selected_file_paths_str = response.choices[0].message.content.strip()
        else:
            print(f"Warning: LLM did not return file paths. Response: {response}")
            return {}

    except Exception as e:
        print(f"Error during LLM call for file selection: {e}")
        return {}

    relevant_content: Dict[str, str] = {}
    if selected_file_paths_str:
        for line in selected_file_paths_str.splitlines():
            file_path_from_llm = line.strip().lstrip("- ").strip()
            # Validate if the file path from LLM is in our list and actually exists
            if file_path_from_llm in all_available_files:
                full_path = os.path.join(log_dir, file_path_from_llm)
                # file_path_from_llm is the relative path
                content = _read_and_truncate_file_content(file_path_from_llm, full_path)
                if not content.startswith("Error reading file"):
                        relevant_content[file_path_from_llm] = content
                # Error handling is done within _read_and_truncate_file_content
            else:
                print(f"Warning: LLM suggested a file not in the original list or malformed: '{file_path_from_llm}'")
    
    return relevant_content