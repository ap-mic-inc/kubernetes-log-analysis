#!/usr/bin/env bash
# Kubernetes Debug Information Collector
# This script collects a wide range of information from a Kubernetes cluster
# and the local OS environment where the script is run.
# It's designed to help diagnose issues and understand the current state.
# Output is saved into a timestamped directory and then compressed into a .tar.gz file.

set -euo pipefail # Exit on error (-e), undefined variable (-u), or pipe failure (-o pipefail)

# ------------------------------------------------------------
# 參數設定 (Parameter Settings)
# ------------------------------------------------------------
NAMESPACE="default"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
OUTDIR="./result/k8s-debug-${NAMESPACE}-${TIMESTAMP}"
ARCHIVE="${OUTDIR}.tar.gz"

mkdir -p "${OUTDIR}"

# ------------------------------------------------------------
# 函式：收集並輸出 (Function: Collect and Output)
# $1: name - A descriptive name for the collected data (used for filename)
# $2: cmd  - The command to execute for data collection
# ------------------------------------------------------------
function dump() {
  local name="$1"
  local cmd="$2"
  echo ">> 收集 ${name} ..."
  # Execute the command, redirect stdout to a file, and stderr to stdout (to capture both)
  # If the command fails, append an error message to errors.log
  ${cmd} > "${OUTDIR}/${name}.txt" 2>&1 \
    || echo "!! ${name} 收集失敗 (Command: ${cmd})" >> "${OUTDIR}/errors.log"
}

echo "=== Kubernetes 除錯資訊匯出 (Namespace: ${NAMESPACE}；輸出目錄: ${OUTDIR}) ==="
# errors.log will be created if any command fails and will contain details of failed commands.

# ------------------------------------------------------------
# 本機 OS 狀態資訊 (執行此腳本的機器)
# (Local OS Status Information - from the machine running this script)
# ------------------------------------------------------------
echo ">> 收集本機 OS 狀態資訊 ..."
dump "host-uname"           "uname -a" # System kernel information
dump "host-uptime"          "uptime"   # System uptime and load
dump "host-free-memory"     "free -m" # 以 MB 為單位顯示記憶體
dump "host-disk-space"      "df -h"
dump "host-lscpu"           "lscpu" # CPU 架構資訊
dump "host-top-snapshot"    "top -bn1" # CPU 和行程快照
dump "host-dmesg-tail"      "dmesg | tail -n 100" # 最後 100 行核心訊息 (可能需要權限)
# 如果需要網路介面資訊，可以取消註解下一行
# dump "host-ip-addr"         "ip addr"
# ------------------------------------------------------------
# 全域 Cluster 資訊
# (Global Cluster Information)
# ------------------------------------------------------------
dump "cluster-info"       "kubectl cluster-info" # Basic cluster endpoint information
dump "version"            "kubectl version --short" # Client and server Kubernetes versions
dump "nodes-wide"         "kubectl get nodes -o wide" # 新增：節點列表概覽
dump "component-status"   "kubectl get componentstatuses --no-headers -o wide" # Status of control plane components (deprecated in newer K8s versions but still useful if present)
dump "top-nodes"          "kubectl top nodes --no-headers" # 新增：節點資源使用 - requires Metrics Server

# ------------------------------------------------------------
# API、CRD 與 Webhook 資訊
# (API, CRD & Webhook Information)
# ------------------------------------------------------------
dump "api-resources"      "kubectl api-resources" # 新增：API 資源列表 - List all available API resources in the cluster
dump "crds"               "kubectl get crds -o wide" # 新增：自訂資源定義
dump "mutating-webhooks"  "kubectl get mutatingwebhookconfigurations -o wide" # 新增
dump "validating-webhooks" "kubectl get validatingwebhookconfigurations -o wide" # 新增

# ------------------------------------------------------------
# ${NAMESPACE} Namespace 資源總覽 (Resource Overview for ${NAMESPACE} Namespace)
# ------------------------------------------------------------
dump "namespace-info"     "kubectl get namespace ${NAMESPACE} -o wide" # Details of the target namespace
dump "all-resources"      "kubectl get all -n ${NAMESPACE} -o wide"
dump "top-pods"           "kubectl top pods -n ${NAMESPACE} --no-headers" # 新增：Pod 資源使用 - requires Metrics Server
dump "configmaps"         "kubectl get configmap -n ${NAMESPACE} -o wide"
dump "secrets"            "kubectl get secret -n ${NAMESPACE} -o wide" # List Secrets in the namespace (metadata only, not content by default with 'get')
dump "pvc"                "kubectl get pvc -n ${NAMESPACE} -o wide"
dump "persistent-volumes" "kubectl get pv -o wide" # 新增：PV 列表 - List all PersistentVolumes in the cluster (not namespace-specific but related to PVCs)
dump "storageclasses"     "kubectl get storageclass -o wide" # List all StorageClasses in the cluster

# ------------------------------------------------------------
# 詳細 Describe：Nodes
# ------------------------------------------------------------
dump "describe-nodes"     "kubectl describe nodes"

# ------------------------------------------------------------
# 詳細 Describe：Namespace ${NAMESPACE} 中的資源 (各自成檔)
# (Detailed Describe: Resources in Namespace ${NAMESPACE} - each in a separate file)
# ------------------------------------------------------------
echo ">> 開始對 ${NAMESPACE} namespace 中每個 Pod 分別執行 describe ..."
mkdir -p "${OUTDIR}/describe-pods"
# Loop through each Pod name (extracted using jsonpath) in the target namespace
for pod in $(kubectl get pods -n "${NAMESPACE}" -o jsonpath='{.items[*].metadata.name}'); do
  echo "   - 描述 Pod: ${pod}"
  kubectl describe pod "${pod}" -n "${NAMESPACE}" \
    > "${OUTDIR}/describe-pods/pod-${pod}.txt" 2>&1 \
    || echo "!! describe 失敗: Pod ${pod} in ${NAMESPACE}" >> "${OUTDIR}/errors.log"
done

echo ">> 開始對 ${NAMESPACE} namespace 中每個 Deployment 分別執行 describe ..."
mkdir -p "${OUTDIR}/describe-deployments"
# Loop through each Deployment name in the target namespace
for deploy in $(kubectl get deployment -n "${NAMESPACE}" -o jsonpath='{.items[*].metadata.name}'); do
  echo "   - 描述 Deployment: ${deploy}"
  kubectl describe deployment "${deploy}" -n "${NAMESPACE}" \
    > "${OUTDIR}/describe-deployments/deployment-${deploy}.txt" 2>&1 \
    || echo "!! describe 失敗: Deployment ${deploy} in ${NAMESPACE}" >> "${OUTDIR}/errors.log"
done

echo ">> 開始對 ${NAMESPACE} namespace 中每個 StatefulSet 分別執行 describe ..."
mkdir -p "${OUTDIR}/describe-statefulsets"
# Loop through each StatefulSet name in the target namespace
for sts in $(kubectl get statefulset -n "${NAMESPACE}" -o jsonpath='{.items[*].metadata.name}'); do
  echo "   - 描述 StatefulSet: ${sts}"
  kubectl describe statefulset "${sts}" -n "${NAMESPACE}" \
    > "${OUTDIR}/describe-statefulsets/statefulset-${sts}.txt" 2>&1 \
    || echo "!! describe 失敗: StatefulSet ${sts} in ${NAMESPACE}" >> "${OUTDIR}/errors.log"
done

echo ">> 開始對 ${NAMESPACE} namespace 中每個 DaemonSet 分別執行 describe ..."
mkdir -p "${OUTDIR}/describe-daemonsets"
# Loop through each DaemonSet name in the target namespace
for ds in $(kubectl get daemonset -n "${NAMESPACE}" -o jsonpath='{.items[*].metadata.name}'); do
  echo "   - 描述 DaemonSet: ${ds}"
  kubectl describe daemonset "${ds}" -n "${NAMESPACE}" \
    > "${OUTDIR}/describe-daemonsets/daemonset-${ds}.txt" 2>&1 \
    || echo "!! describe 失敗: DaemonSet ${ds} in ${NAMESPACE}" >> "${OUTDIR}/errors.log"
done

echo ">> 開始對 ${NAMESPACE} namespace 中每個 Service 分別執行 describe ..."
mkdir -p "${OUTDIR}/describe-services"
# Loop through each Service name in the target namespace
for svc in $(kubectl get service -n "${NAMESPACE}" -o jsonpath='{.items[*].metadata.name}'); do
  echo "   - 描述 Service: ${svc}"
  kubectl describe service "${svc}" -n "${NAMESPACE}" \
    > "${OUTDIR}/describe-services/service-${svc}.txt" 2>&1 \
    || echo "!! describe 失敗: Service ${svc} in ${NAMESPACE}" >> "${OUTDIR}/errors.log"
done

dump "ingresses-list" "kubectl get ingress -n ${NAMESPACE} -o wide" # 新增 Ingress 列表
echo ">> 開始對 ${NAMESPACE} namespace 中每個 Ingress 分別執行 describe ..."
mkdir -p "${OUTDIR}/describe-ingresses"
# Loop through each Ingress name in the target namespace
for ing in $(kubectl get ingress -n "${NAMESPACE}" -o jsonpath='{.items[*].metadata.name}'); do
  echo "   - 描述 Ingress: ${ing}"
  kubectl describe ingress "${ing}" -n "${NAMESPACE}" \
    > "${OUTDIR}/describe-ingresses/ingress-${ing}.txt" 2>&1 \
    || echo "!! describe 失敗: Ingress ${ing} in ${NAMESPACE}" >> "${OUTDIR}/errors.log"
done

dump "networkpolicies-list" "kubectl get networkpolicy -n ${NAMESPACE} -o wide" # 新增 NetworkPolicy 列表
echo ">> 開始對 ${NAMESPACE} namespace 中每個 NetworkPolicy 分別執行 describe ..."
mkdir -p "${OUTDIR}/describe-networkpolicies"
# Loop through each NetworkPolicy name in the target namespace
for np in $(kubectl get networkpolicy -n "${NAMESPACE}" -o jsonpath='{.items[*].metadata.name}'); do
  echo "   - 描述 NetworkPolicy: ${np}"
  kubectl describe networkpolicy "${np}" -n "${NAMESPACE}" \
    > "${OUTDIR}/describe-networkpolicies/networkpolicy-${np}.txt" 2>&1 \
    || echo "!! describe 失敗: NetworkPolicy ${np} in ${NAMESPACE}" >> "${OUTDIR}/errors.log"
done

dump "hpa-list" "kubectl get hpa -n ${NAMESPACE} -o wide" # 新增 HPA 列表
echo ">> 開始對 ${NAMESPACE} namespace 中每個 HorizontalPodAutoscaler 分別執行 describe ..."
mkdir -p "${OUTDIR}/describe-hpas"
# Loop through each HPA name in the target namespace
for hpa in $(kubectl get hpa -n "${NAMESPACE}" -o jsonpath='{.items[*].metadata.name}'); do
  echo "   - 描述 HPA: ${hpa}"
  kubectl describe hpa "${hpa}" -n "${NAMESPACE}" \
    > "${OUTDIR}/describe-hpas/hpa-${hpa}.txt" 2>&1 \
    || echo "!! describe 失敗: HPA ${hpa} in ${NAMESPACE}" >> "${OUTDIR}/errors.log"
done

echo ">> 開始對 ${NAMESPACE} namespace 中每個 ConfigMap 分別執行 describe ..."
mkdir -p "${OUTDIR}/describe-configmaps"
# Loop through each ConfigMap name in the target namespace
for cm in $(kubectl get configmap -n "${NAMESPACE}" -o jsonpath='{.items[*].metadata.name}'); do
  echo "   - 描述 ConfigMap: ${cm}"
  kubectl describe configmap "${cm}" -n "${NAMESPACE}" \
    > "${OUTDIR}/describe-configmaps/configmap-${cm}.txt" 2>&1 \
    || echo "!! describe 失敗: ConfigMap ${cm} in ${NAMESPACE}" >> "${OUTDIR}/errors.log"
done

echo ">> 開始對 ${NAMESPACE} namespace 中每個 Secret 分別執行 describe ..."
mkdir -p "${OUTDIR}/describe-secrets"
# Loop through each Secret name in the target namespace
for secret in $(kubectl get secret -n "${NAMESPACE}" -o jsonpath='{.items[*].metadata.name}'); do
  echo "   - 描述 Secret: ${secret}"
  # 'describe secret' shows metadata, creation timestamp, type, and data keys (not values)
  kubectl describe secret "${secret}" -n "${NAMESPACE}" \
    > "${OUTDIR}/describe-secrets/secret-${secret}.txt" 2>&1 \
    || echo "!! describe 失敗: Secret ${secret} in ${NAMESPACE}" >> "${OUTDIR}/errors.log"
done

echo ">> 開始對 ${NAMESPACE} namespace 中每個 PersistentVolumeClaim 分別執行 describe ..."
mkdir -p "${OUTDIR}/describe-pvcs"
# Loop through each PVC name in the target namespace
for pvc_name in $(kubectl get pvc -n "${NAMESPACE}" -o jsonpath='{.items[*].metadata.name}'); do
  echo "   - 描述 PVC: ${pvc_name}"
  kubectl describe pvc "${pvc_name}" -n "${NAMESPACE}" \
    > "${OUTDIR}/describe-pvcs/pvc-${pvc_name}.txt" 2>&1 \
    || echo "!! describe 失敗: PVC ${pvc_name}" >> "${OUTDIR}/errors.log"
done

echo ">> 開始對每個 StorageClass 分別執行 describe ..."
mkdir -p "${OUTDIR}/describe-storageclasses"
# Loop through each StorageClass name (cluster-scoped)
for sc_name in $(kubectl get sc -o jsonpath='{.items[*].metadata.name}'); do
  echo "   - 描述 StorageClass: ${sc_name}"
  kubectl describe sc "${sc_name}" \
    > "${OUTDIR}/describe-storageclasses/sc-${sc_name}.txt" 2>&1 \
    || echo "!! describe 失敗: StorageClass ${sc_name}" >> "${OUTDIR}/errors.log"
done

# ------------------------------------------------------------
# 事件與日誌
# ------------------------------------------------------------
dump "events"             "kubectl get events -n ${NAMESPACE} --sort-by=.metadata.creationTimestamp" # Get all events in the namespace, sorted by creation time

echo ">> 開始收集 Pod 日誌 (namespace=${NAMESPACE}) ..."
mkdir -p "${OUTDIR}/logs/${NAMESPACE}"
# Loop through each Pod name in the target namespace to collect logs
for pod in $(kubectl get pods -n "${NAMESPACE}" -o jsonpath='{.items[*].metadata.name}'); do
  echo "   - 收集中 Pod: ${pod} 的日誌..."
  # Collect logs from all containers in the pod (--all-containers), with timestamps (--timestamps)
  kubectl logs -n "${NAMESPACE}" "${pod}" --all-containers --timestamps \
    > "${OUTDIR}/logs/${NAMESPACE}/${pod}.log" 2>&1 \
    || echo "!! 日誌收集失敗: ${NAMESPACE}/${pod}" >> "${OUTDIR}/errors.log"
done

# ------------------------------------------------------------
# Namespace RBAC 資訊
# (Namespace RBAC Information)
# ------------------------------------------------------------
dump "roles"              "kubectl get roles -n ${NAMESPACE} -o wide" # List Roles in the namespace
dump "rolebindings"       "kubectl get rolebindings -n ${NAMESPACE} -o wide" # List RoleBindings in the namespace

# ------------------------------------------------------------
# 🔧 壓縮步驟：將輸出目錄打包為 tar.gz
# (Compression Step: Package the output directory into a tar.gz file)
# ------------------------------------------------------------
echo ">> 開始壓縮輸出目錄為 ${ARCHIVE} ..."
tar czf "${ARCHIVE}" "${OUTDIR}" \
  && echo "✅ 壓縮完成：檔案位於 $(pwd)/${ARCHIVE}" \
  || echo "!! 壓縮失敗" >> "${OUTDIR}/errors.log"

# ------------------------------------------------------------
# 完成 (Completion)
# ------------------------------------------------------------
echo "=== 全部流程結束 ==="
echo "請檢視壓縮包：${ARCHIVE}，或展開後檢查資料夾 ${OUTDIR}。"
echo "若有錯誤，請檢查 ${OUTDIR}/errors.log 檔案。"
