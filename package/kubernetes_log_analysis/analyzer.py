import os
from litellm import completion
from typing import Dict, Optional
from . import config # For API key and model configuration

def analyze_logs_with_llm(query: str, log_data: Dict[str, str], user_namespace: Optional[str]) -> str:
    """
    Sends the query and log data to an LLM via LiteLLM for analysis.
    """
    if not config.GEMINI_API_KEY:
        return "Error: GOOGLE_API_KEY not configured. Please set it as an environment variable (e.g., in a .env file)."

    if not log_data:
        return "No relevant log data found to answer the query based on the interpreted query type. Please try a different query or check the log directory."

    # Construct the prompt for the LLM
    # Prompt engineering is key here!
    system_message = (
        "You are an expert Kubernetes administrator and troubleshooter. "
        "Analyze the following Kubernetes diagnostic information to answer the user's question. "
        "The logs were collected from a Kubernetes cluster, likely focusing on a specific namespace. "
        f"The user's query might imply a namespace; if so, it's '{user_namespace if user_namespace else 'default'}'. "
        "Provide a concise and helpful summary based *only* on the information provided in the logs. "
        "If the information is insufficient to answer the question, clearly state that. "
        "If you see error messages from the log collection process itself (e.g., 'kubectl command failed'), "
        "mention that these indicate issues with data gathering for certain aspects. "
        "The user's query is in Chinese(zh-TW), please respond in Chinese(zh-TW)."
    )

    context_data_str = "\n\n--- Collected Diagnostic Information ---\n"
    # Aggregate log data, mindful of total length for the prompt
    # Gemini 1.5 Flash has 1M tokens context, but let's be somewhat conservative with char count.
    # ~3-4 chars per token on average. 1M tokens ~ 3-4M chars.
    # We'll cap total context string length.
    MAX_CONTEXT_CHARS = 2000000 # Approx 2 million characters

    for filename, file_content in log_data.items():
        header = f"\n--- Content from file: {filename} ---\n"
        if len(context_data_str) + len(header) + len(file_content) > MAX_CONTEXT_CHARS:
            remaining_chars = MAX_CONTEXT_CHARS - len(context_data_str) - len(header) - 200 # for truncation message
            if remaining_chars > 0:
                context_data_str += header + file_content[:remaining_chars] + "\n... [FURTHER CONTENT TRUNCATED DUE TO OVERALL PROMPT LENGTH] ..."
            print(f"Warning: Total log data provided to LLM was truncated. Stopped at file {filename}.")
            break 
        context_data_str += header + file_content

    user_prompt_content = f"User Question: {query}\n{context_data_str}"

    messages_for_litellm = [
        {"role": "system", "content": system_message},
        {"role": "user", "content": user_prompt_content}
    ]
    
    # Explicitly set the API key in the environment for LiteLLM to pick up.
    # For Gemini, LiteLLM expects GOOGLE_API_KEY. Our config.GEMINI_API_KEY reads this.
    if config.GEMINI_API_KEY:
        os.environ["GOOGLE_API_KEY"] = config.GEMINI_API_KEY
        print(f"DEBUG: Explicitly set os.environ['GOOGLE_API_KEY'] to: {os.environ.get('GOOGLE_API_KEY')[:5]}... (masked)") # 印出部分金鑰以確認

    try:
        print(f"Sending request to LLM model: {config.LLM_MODEL}. This may take a moment...")
        response = completion(
            model=config.LLM_MODEL,
            messages=messages_for_litellm,
            api_key=config.GEMINI_API_KEY # 也可以在這裡直接傳遞
            # max_tokens=1500, # Optional: Control response length
            # temperature=0.3, # Optional: For more factual responses
        )
        
        # Standard LiteLLM response structure
        if response.choices and response.choices[0].message and response.choices[0].message.content:
            return response.choices[0].message.content.strip()
        else:
            # Log the full response for debugging if it's not as expected
            print(f"DEBUG: LLM response object: {response}")
            return "Error: LLM response was empty or malformed. Check debug output."

    except Exception as e:
        # Catch LiteLLM specific exceptions if known, or general Exception
        print(f"DEBUG: Exception during LLM API call: {e}") # Print full error for debugging
        return f"Error during LLM API call: {str(e)}"
