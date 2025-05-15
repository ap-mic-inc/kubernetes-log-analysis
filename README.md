# Kubernetes Log Analysis Tool: Your K8s Log Analysis Assistant

[中文版說明文件](https://github.com/ap-mic-inc/kubernetes-log-analysis/blob/main/README_zh_tw.md)

## I. Project Overview

Still manually sifting through massive logs when encountering Kubernetes cluster issues? This project, "Kubernetes Log Analysis Tool," is here to help! We leverage powerful Large Language Model (LLM) APIs, allowing you to easily collect and analyze Kubernetes logs within your own environment. With simple commands and natural language, you can quickly obtain analysis results, significantly improving troubleshooting and system monitoring efficiency.

## II. Key Feature Highlights

-   **One-Click Log Collection**: Easily gather various logs from your Kubernetes cluster using the `k8s-debug.sh` script.
-   **AI-Powered Smart Analysis**: Integrates with the Gemini API, enabling you to ask questions in natural language and analyze log content from multiple perspectives.
-   **Secure Local Analysis**: All analysis is performed locally on your machine, ensuring sensitive logs are not exposed and protecting your data privacy.

## III. Prerequisites

Before you begin, please ensure you have the following:

-   **Kubernetes Access**: Ensure your `kubectl` can successfully access the target cluster.
-   **Python Environment**: Python 3.8 or higher is required.

## IV. Quick Installation Guide

Ready to go? Follow these steps to get started quickly:
1.  **Install Necessary Python Packages**
    ```bash
    pip install kubernetes-log-analysis==0.1.0
    ```

2.  **Set Your Gemini API Key**
    To ensure the AI analysis feature works correctly, please set your Gemini API key. Using an environment variable is recommended:
    ```bash
    export GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
    ```
    Remember to replace `"YOUR_GEMINI_API_KEY"` with your own key.

## V. How to Use

Once the setup is complete, you can start analyzing your Kubernetes logs!

1.  **Collect Logs**
    Obtain and execute the `k8s-debug.sh` script to collect logs. You can adjust the parameters within the script according to your needs.
    ```bash
    wget https://raw.githubusercontent.com/ap-mic-inc/kubernetes-log-analysis/refs/heads/main/k8s-debug.sh
    chmod +x k8s-debug.sh
    ./k8s-debug.sh
    ```
    This script will store the collected logs in a specific folder (usually in the script's execution directory, for example, a folder named `k8s-debug-logs-<timestamp>`).

2.  **Navigate to the Log Directory**
    Change to the directory created by the log collection script. For example, if logs were collected in `k8s-debug-logs-20231026103045`:
    ```bash
    cd k8s-debug-logs-20231026103045 # Please replace with your actual log directory path
    ```

3.  **Start AI Analysis**
    Use the `k-logs` command with your natural language query to analyze the logs:
    ```bash
    k-logs "Find all ERR level error messages from the past hour"
    ```

    **More Query Examples to Spark Your Imagination:**
    *   Want to know which Pods are most active (have the most logs)? Try: `k-logs "Count the log volume for each Pod and list the top five"`
    *   Want to understand popular keywords from the last half hour? Try: `k-logs "Analyze high-frequency keywords appearing in the last 30 minutes"`
    *   Is a specific Pod (e.g., `my-pod-xyz`) experiencing issues? Try: `k-logs "Check if my-pod-xyz has any errors or warnings"`

    Unleash your imagination and explore your logs using natural language!

## VI. Expected Output Example

Here is an example of the analysis results you might see:

```text
[INFO] 2025-05-09T08:00:00Z pod/frontend-abc123 restart count: 3
[ERROR] 2025-05-09T08:05:10Z pod/backend-def456 OOMKilled probability: 0.2%
Analysis complete, 12 ERR messages filtered.
```
(Please note: The actual output will vary based on your log content and query command)

## VII. Advanced Configuration and Customization
You can further customize this tool:

Environment Variable Settings:

- GEMINI_API_KEY: Your Gemini Large Language Model API key. This is crucial for the AI analysis feature; please ensure it is set correctly.
Custom Log Collection Script:

- k8s-debug.sh: You can modify this script, for example, by adding more log sources or adjusting filtering conditions to better suit your specific monitoring needs.

## VIII. About the Author
### Simon Liu

APMIC MLOps Engineer x Google Developer Expert (GDE) in AI

A technology enthusiast in the field of artificial intelligence solutions, focusing on assisting enterprises in implementing generative AI, MLOps, and Large Language Model (LLM) technologies to drive digital transformation and practical technological implementation.

Currently also a Google Developer Expert (GDE) in the GenAI field, actively participating in technology communities, promoting the application and development of AI technology through technical articles, speeches, and practical experience sharing. To date, he has published over a hundred technical articles on platforms like Medium, covering topics such as generative AI, RAG, and AI Agents, and has served as a speaker at numerous technical seminars, sharing practical applications of AI and generative AI.

### Related Links:
- APMIC Official Website: https://www.apmic.ai/
- Personal Social Media Links: https://simonliuyuwei.my.canva.site/link-in-bio