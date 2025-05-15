# Kubernetes Log Analysis 工具：您的 K8s 日誌分析好幫手

## 一、專案概述

遇到 Kubernetes 叢集問題，還在手動翻查大量日誌嗎？本專案「Kubernetes Log Analysis 工具」能助您一臂之力！我們利用強大的大型語言模型（LLM）API，讓您在自己的環境中，輕鬆收集並分析 Kubernetes 日誌。只需簡單的命令和自然語言，就能快速獲得分析結果，大幅提升故障排除和系統監控的效率。

## 二、主要功能亮點

-   **一鍵日誌收集**：透過 `k8s-debug.sh` 腳本，輕鬆匯集 Kubernetes 叢集的各種日誌。
-   **AI 智能分析**：整合 Gemini API，讓您能用自然語言提問，從多角度分析日誌內容。
-   **本地安全分析**：所有分析都在您的本地端執行，確保敏感日誌不外洩，保護您的資料隱私。

## 三、開始前的準備

在開始之前，請確認您已具備以下條件：

-   **Kubernetes 存取權限**：確保您的 `kubectl` 可以順利存取目標叢集。
-   **Python 環境**：需要 Python 3.8 或更高版本。

## 四、快速安裝指南

準備好了嗎？跟著以下步驟快速開始：
1.  **安裝必要的 Python 套件**
    ```bash
    pip install kubernetes-log-analysis==0.1.0
    ```

2.  **設定您的 Gemini API 金鑰**
    為了讓 AI 分析功能順利運作，請設定您的 Gemini API 金鑰。推薦使用環境變數：
    ```bash
    export GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
    ```
    請記得將 `"YOUR_GEMINI_API_KEY"` 替換成您自己的金鑰。

## 五、如何使用

設定完成後，就可以開始分析您的 Kubernetes 日誌了！

1.  **收集日誌**
    取得並且執行 `k8s-debug.sh` 腳本來收集日誌。您可以根據需求調整腳本內的參數。
    ```bash
    wget https://raw.githubusercontent.com/ap-mic-inc/kubernetes-log-analysis/refs/heads/main/k8s-debug.sh
    chmod +x k8s-debug.sh
    ./k8s-debug.sh
    ```
    此腳本會將收集到的日誌存放在特定資料夾（通常在腳本執行目錄下，例如名為 `k8s-debug-logs-<timestamp>` 的資料夾）。

2.  **進入日誌資料夾**
    切換到日誌收集腳本所產生的資料夾。例如，如果日誌被收集到 `k8s-debug-logs-20231026103045`：
    ```bash
    cd k8s-debug-logs-20231026103045 # 請替換成您實際的日誌資料夾路徑
    ```

3.  **開始 AI 分析**
    使用 `k-logs` 命令搭配您的自然語言提問來分析日誌：
    ```bash
    k-logs "請找出過去一小時內所有 ERR 等級的錯誤訊息"
    ```

    **更多查詢範例，激發您的靈感：**
    *   想知道哪些 Pod 最活躍（日誌最多）？試試：`k-logs "請統計各 Pod 日誌量並列出前五名"`
    *   想了解最近半小時內的熱門關鍵字？試試：`k-logs "分析最近 30 分鐘內出現的高頻關鍵字"`
    *   某個 Pod (例如 `my-pod-xyz`) 是否有異常？試試：`k-logs "檢查 my-pod-xyz 是否有任何錯誤或警告"`

    發揮您的想像力，用自然語言探索您的日誌吧！

## 六、預期輸出範例

以下是您可能會看到的分析結果範例：

```text
[INFO] 2025-05-09T08:00:00Z pod/frontend-abc123 重啟次數: 3
[ERROR] 2025-05-09T08:05:10Z pod/backend-def456 OOMKilled 機率: 0.2%
分析完成，共篩選出 12 條 ERR 資訊。
```

(請注意：實際輸出會根據您的日誌內容和查詢指令而有所不同)

## 七、進階設定與客製化

您可以進一步客製化此工具：

環境變數設定：

- GEMINI_API_KEY：您的 Gemini 大型語言模型 API 金鑰。這是 AI 分析功能的核心，請確保已正確設定。
自訂日誌收集腳本：

- k8s-debug.sh：您可以修改此腳本，例如加入更多日誌來源、調整篩選條件，使其更符合您的特定監控需求。

## 八、關於作者

### Simon Liu

APMIC MLOps 工程師 x Google Developer Expert (GDE) in AI

為人工智慧解決方案領域的技術愛好者，專注於協助企業如何導入生成式人工智慧、MLOps 與大型語言模型（LLM）技術，推動數位轉型與技術落地如何實踐。​

目前也是 Google GenAI 領域開發者專家（GDE），積極參與技術社群，透過技術文章、演講與實務經驗分享，推廣 AI 技術的應用與發展，目前，在 Medium 平台上發表超過百篇技術文章，涵蓋生成式 AI、RAG 和 AI Agent 等主題，並多次擔任技術研討會中的講者，分享 AI 與生成式 AI 的實務應用。​

### 相關連結：

- APMIC 官網: https://www.apmic.ai/
- 個人社群網站連結: https://simonliuyuwei.my.canva.site/link-in-bio