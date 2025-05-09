from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="kubernetes-log-analysis",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "litellm>=1.34.0",
        "click>=8.0",
        "python-dotenv>=1.0.0",
        "google-generativeai" # For Gemini, used by LiteLLM
    ],
    entry_points={
        "console_scripts": [
            "k-log=kubernetes_log_analysis.cli:main_cli",
        ],
    },
    author="Your Name / APMIC", # Feel free to change
    author_email="your.email@example.com", # Feel free to change
    description="A tool to analyze Kubernetes log bundles using LLMs via LiteLLM.",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/yourusername/kubernetes-log-analysis", # Optional: Replace with your repo URL
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License", # Or your preferred license
        "Operating System :: OS Independent",
        "Topic :: System :: Logging",
        "Topic :: Software Development :: Libraries :: Python Modules",
    ],
    python_requires='>=3.8',
)
