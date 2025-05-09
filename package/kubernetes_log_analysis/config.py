import os
from dotenv import load_dotenv

# Load environment variables from .env file in the current working directory
# or the directory of this script if .env is placed alongside the package.
# For k-log, it's better to load .env from where k-log is run.
# dotenv_path = os.path.join(os.getcwd(), '.env')
# load_dotenv(dotenv_path=dotenv_path)
load_dotenv() # Loads .env from CWD or parent directories.

# LiteLLM uses GOOGLE_API_KEY for Gemini models
GEMINI_API_KEY = os.getenv("GOOGLE_API_KEY")

# Default model, can be overridden by environment variable
LLM_MODEL = os.getenv("LLM_MODEL", "gemini/gemini-2.5-flash-preview-04-17")

# Pattern to identify the log directory, used for a warning if the dir name doesn't match
DEFAULT_LOG_DIR_NAME_PATTERN = "k8s-debug-"
