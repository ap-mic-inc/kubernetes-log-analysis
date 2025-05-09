# Kubernetes Log Analysis 工具

## 一、專案概述
本專案旨在協助企業在自有環境中，利用 LLM（Large Language Model）模型 API 進行 Kubernetes 叢集日誌(Log)收集與分析。使用者可透過簡易命令及自然語言指令，快速取得日誌分析結果，提升故障排除與監控效率。

## 二、主要功能

- **Log 收集**：透過 `k8s-debug.sh` 腳本，一鍵匯集 Kubernetes 叢集的各類日誌。
- **AI 驅動分析**：整合 Gemini API，使用自然語言指令對日誌進行多角度分析。
- **即時回饋**：在本地端執行分析命令，避免將敏感日誌上傳至外部平台。

## 三、先決條件

- **Kubernetes 權限**：kubectl 可存取目標叢集
- **Python**：版本 3.8 以上

## 四、安裝指引

1. **Clone 本專案**
   ```bash
   git clone https://github.com/YourOrg/kubernetes-log-analysis.git
   cd kubernetes-log-analysis
   ```

2. **安裝 Python 套件**
   套件檔案位於 `package/dist/`，請依照下列指令安裝：

   ```bash
   cd package
   make build_python_package
   ```

3. **設定 Gemini API 金鑰**
   建議以環境變數方式設定：

   ```bash
   export GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
   ```

## 五、使用說明

1. **收集 Log**

   ```bash
   # 執行 k8s-log 收集腳本，依實際腳本選項調整參數
   ./k8s-debug.sh
   ```

2. **進入 Log 資料夾**

   ```bash
   cd /path/to/collected_logs
   ```

3. **執行 AI 分析命令**

   ```bash
   k-logs "請找出過去一小時內所有 ERR 等級的錯誤訊息"
   ```

   * 支援多種查詢範例：

     * `請統計各 Pod 日誌量並列出前五名`
     * `分析最近 30 分鐘內出現的高頻關鍵字`

## 六、範例輸出

```text
[INFO] 2025-05-09T08:00:00Z pod/frontend-abc123 重啟次數: 3
[ERROR] 2025-05-09T08:05:10Z pod/backend-def456 OOMKilled 機率: 0.2%
分析完成，共篩選出 12 條 ERR 資訊。
```

## 七、參數設定與擴充

* **環境變數**：

  * `GEMINI_API_KEY`：LLM API 金鑰

* **自訂腳本**：

  * `k8s-debug.sh`：可修改 `k8s-debug.sh`，新增其他日誌來源或篩選條件。
