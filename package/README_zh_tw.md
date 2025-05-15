## Kubernetes 日誌分析工具 (k-log)

一個命令列工具，利用大型語言模型 (LLMs) 分析收集 Kubernetes log 內容。

## 先決條件

-   Python 3.8+
-   一個 Kubernetes log 內容目錄 (由 `k8s-debug.sh` 生成，詳情可見 https://github.com/ap-mic-inc/kubernetes-log-analysis)。
-   Google Gemini API 金鑰 (或 LiteLLM 支援的其他模型的 API 金鑰)。

## 安裝 Python 套件

3.  使用 pip 安裝套件及其依賴項：
    ```bash
    pip install kubernetes-log-analysis==0.1.0
    ```

## 配置

1.  **API 金鑰**：此工具需要 Gemini 的 `GOOGLE_API_KEY`。在您將執行 `k-log` 的目錄 (或開發期間的專案根目錄) 中建立一個名為 `.env` 的檔案，內容如下：
    ```env
    GOOGLE_API_KEY="YOUR_GEMINI_API_KEY_HERE"
    ```
    或者，確保此環境變數已全域設定。

2.  **LLM 模型 (可選)**：您可以透過在 `.env` 檔案或全域設定 `LLM_MODEL` 環境變數來指定不同的 LiteLLM 相容模型字串。預設為 `gemini/gemini-2.5-flash-preview-04-17`。
    ```env
    LLM_MODEL="gemini/gemini-2.5-flash-preview-04-17"
    ```

## 使用方法

1.  確保您的 `GOOGLE_API_KEY` 已設定 (例如透過 `.env` 檔案)。
2.  導航到您的 Kubernetes 日誌包目錄 (例如 `cd /path/to/k8s-debug-default-20250509034522`)。
3.  使用您的查詢執行 `k-log` 命令：

    ```bash
    k-log "請問目前 nodes 狀態"
    ```
    或者，明確指定日誌目錄：
    ```bash
    k-log --log-dir /path/to/your/k8s-debug-default-20250509034522 "logs for pod kuberay-operator-6ddb59999c-mggc9"
    ```

### 範例查詢：

-   `k-log "status of nodes"`
-   `k-log "logs for pod jupyterlab-54698b59b8-bmvgq in namespace default"`
-   `k-log "describe service kubernetes"`
-   `k-log "any critical events?"`

## 關於作者

### Simon Liu

APMIC MLOps 工程師 x Google Developer Expert (GDE) in AI

為人工智慧解決方案領域的技術愛好者，專注於協助企業如何導入生成式人工智慧、MLOps 與大型語言模型（LLM）技術，推動數位轉型與技術落地如何實踐。​

目前也是 Google GenAI 領域開發者專家（GDE），積極參與技術社群，透過技術文章、演講與實務經驗分享，推廣 AI 技術的應用與發展，目前，在 Medium 平台上發表超過百篇技術文章，涵蓋生成式 AI、RAG 和 AI Agent 等主題，並多次擔任技術研討會中的講者，分享 AI 與生成式 AI 的實務應用。​

### 相關連結：

- APMIC 官網: https://www.apmic.ai/
- 個人社群網站連結: https://simonliuyuwei.my.canva.site/link-in-bio