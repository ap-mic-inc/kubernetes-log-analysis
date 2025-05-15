import click
import os
from .analyzer import analyze_logs_with_llm
from .file_finder import determine_query_type_and_resource, find_relevant_files_with_llm, QUERY_TO_FILE_MAP
from . import config # To check API key presence and get default dir pattern

@click.command()
@click.option(
    '--log-dir', 
    default='.', 
    help='Path to the Kubernetes log directory (e.g., k8s-debug-default-TIMESTAMP). Defaults to current directory.',
    type=click.Path(exists=True, file_okay=False, dir_okay=True, readable=True)
)
@click.argument('query_parts', nargs=-1, required=True) # 'query_parts' because click will pass it as a tuple
def main_cli(log_dir: str, query_parts: tuple):
    """
    Kubernetes Log Analysis Tool (k-log)

    Analyzes collected Kubernetes logs using an LLM to answer your questions.
    The KUBERNETES_LOG_ANALYSIS_PROJECT_PATH environment variable should be set to the root of the project.
    Your query should be enclosed in quotes if it contains spaces.

    Example: k-log "請問目前 nodes 狀態"
    Example: k-log --log-dir /path/to/k8s-debug-dir "logs for pod my-pod-123 in namespace my-ns"
    """
    user_query = " ".join(query_parts)

    if not config.GEMINI_API_KEY:
        click.echo(click.style("Error: GOOGLE_API_KEY not configured.", fg="red"))
        click.echo("Please set it as an environment variable (e.g., in a .env file in the current directory or project root).")
        return

    abs_log_dir = os.path.abspath(log_dir)
    dir_name = os.path.basename(abs_log_dir)
    if not dir_name.startswith(config.DEFAULT_LOG_DIR_NAME_PATTERN) and dir_name != ".": # dir_name can be "." if log_dir is "."
         # Check if current path is a k8s-debug dir if dir_name is "."
        if dir_name == "." and not os.path.basename(os.getcwd()).startswith(config.DEFAULT_LOG_DIR_NAME_PATTERN):
            click.echo(click.style(f"Warning: Log directory '{abs_log_dir}' doesn't look like a standard '{config.DEFAULT_LOG_DIR_NAME_PATTERN}*' output. Proceeding anyway.", fg="yellow"))
        elif dir_name != ".": # Only show warning if it's not "." and doesn't match
            click.echo(click.style(f"Warning: Log directory '{dir_name}' doesn't look like a standard '{config.DEFAULT_LOG_DIR_NAME_PATTERN}*' output. Proceeding anyway.", fg="yellow"))


    click.echo(f"Analyzing logs in: {abs_log_dir}")
    click.echo(click.style("\n🔍 Your query:", bold=True, fg="green"))
    click.echo("--------------------------------------------------")
    click.echo(f"{user_query}")
    click.echo("--------------------------------------------------")
    
    # We'll still run this to get a potential namespace or for fallback error messages,
    # but we won't exit early if query_type is None.
    query_type, resource_name, namespace = determine_query_type_and_resource(user_query)

    if not query_type:
        click.echo(click.style(f"Warning: Could not determine a specific type for your query: '{user_query}'.", fg="yellow"))
    click.echo("Attempting to find relevant files using LLM...")
    relevant_data = find_relevant_files_with_llm(abs_log_dir, user_query)

    if not relevant_data:
        click.echo(click.style(f"No relevant log files found for the interpreted query in '{abs_log_dir}'.", fg="red"))
        click.echo("Please check the log directory structure or try a different query.")
        if query_type and query_type in QUERY_TO_FILE_MAP: # Use QUERY_TO_FILE_MAP directly
            # This part is now a fallback if LLM fails and the old method had a guess
            click.echo(click.style("The old rule-based method might have looked for:", fg="yellow"))
            click.echo("Expected file patterns for this query type:")
            for pattern in QUERY_TO_FILE_MAP[query_type]: # Use QUERY_TO_FILE_MAP directly
                click.echo(f"  - {pattern.replace('{namespace}', namespace if namespace else 'default').replace('{resource_name}', resource_name if resource_name else '<specific_resource>')}")
        return

    click.echo(f"Found {len(relevant_data)} relevant file(s)/content snippet(s) for analysis:")
    for f_name in relevant_data.keys():
        click.echo(f"  - {f_name}")
    
    response = analyze_logs_with_llm(user_query, relevant_data, namespace)

    click.echo(click.style("\n🔍 LLM Analysis:", bold=True, fg="green"))
    click.echo("--------------------------------------------------")
    click.echo(response)
    click.echo("--------------------------------------------------")

if __name__ == '__main__':
    main_cli()
