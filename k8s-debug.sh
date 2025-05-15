#!/usr/bin/env bash
# Kubernetes Debug Information Collector
# This script collects a wide range of information from a Kubernetes cluster
# and the local OS environment where the script is run.
# It's designed to help diagnose issues and understand the current state.
# Output is saved into a timestamped directory and then compressed into a .tar.gz file.

set -euo pipefail # Exit on error (-e), undefined variable (-u), or pipe failure (-o pipefail)

# ------------------------------------------------------------
# 預設參數 (Default Parameters)
# ------------------------------------------------------------
DEFAULT_NAMESPACE="default"
DEFAULT_OUTDIR_BASE="k8s-debug"

# ------------------------------------------------------------
# 參數解析 (Parameter Parsing)
# ------------------------------------------------------------
NAMESPACE="${DEFAULT_NAMESPACE}"
OUTDIR_BASE="${DEFAULT_OUTDIR_BASE}"

while getopts ":n:o:" opt; do
  case ${opt} in
    n ) NAMESPACE=$OPTARG ;;
    o ) OUTDIR_BASE=$OPTARG ;;
    \? ) echo "用法: $0 [-n namespace] [-o output_directory_base_name]" >&2; exit 1 ;;
  esac
done
shift $((OPTIND -1))

# ------------------------------------------------------------
# 參數設定 (Parameter Settings)
# ------------------------------------------------------------
TIMESTAMP=$(date +%Y%m%d%H%M%S)
OUTDIR="./result/${OUTDIR_BASE}-${NAMESPACE}-${TIMESTAMP}"
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
# ------------------------------------------------------------
# 函式：詳細描述資源 (Function: Detailed Describe Resource)
# $1: resource_type - The type of resource (e.g., "pod", "deployment")
# $2: namespace     - The namespace
# ------------------------------------------------------------
function describe_resource() {
  local resource_type="$1"
  local namespace="$2"
  local output_dir="${OUTDIR}/describe-${resource_type}s"
  mkdir -p "${output_dir}"
  echo ">> 開始對 ${namespace} namespace 中每個 ${resource_type} 分別執行 describe ..."
  # Use --ignore-not-found to prevent script from failing if resource type doesn't exist in namespace
  for name in $(kubectl get "${resource_type}" -n "${namespace}" -o jsonpath='{.items[*].metadata.name}' --ignore-not-found); do
    echo "   - 描述 ${resource_type}: ${name}"
    kubectl describe "${resource_type}" "${name}" -n "${namespace}" \
      > "${output_dir}/${resource_type}-${name}.txt" 2>&1 \
      || echo "!! describe 失敗: ${resource_type} ${name} in ${namespace}" >> "${OUTDIR}/errors.log"
  done
}
# ------------------------------------------------------------
# 函式：收集 Pod 日誌 (Function: Collect Pod Logs)
# $1: namespace - The namespace
# ------------------------------------------------------------
function collect_pod_logs() {
  local namespace="$1"
  local output_dir="${OUTDIR}/logs/${namespace}"
  mkdir -p "${output_dir}"
  echo ">> 開始收集 Pod 日誌 (namespace=${namespace}) ..."
  # Use --ignore-not-found to prevent script from failing if no pods are found
  for pod in $(kubectl get pods -n "${namespace}" -o jsonpath='{.items[*].metadata.name}' --ignore-not-found); do
    echo "   - 收集中 Pod: ${pod} 的日誌..."
    # Collect logs from all containers in the pod (--all-containers), with timestamps (--timestamps)
    kubectl logs -n "${namespace}" "${pod}" --all-containers --timestamps \
      > "${output_dir}/${pod}.log" 2>&1 \
      || echo "!! 日誌收集失敗: ${namespace}/${pod}" >> "${OUTDIR}/errors.log"
  done
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
# Note: describe nodes is cluster-scoped, not namespace-specific

# ------------------------------------------------------------
# 詳細 Describe：Namespace ${NAMESPACE} 中的資源 (各自成檔)
# (Detailed Describe: Resources in Namespace ${NAMESPACE} - each in a separate file)
# ------------------------------------------------------------
describe_resource "pod" "${NAMESPACE}"
describe_resource "deployment" "${NAMESPACE}"
describe_resource "statefulset" "${NAMESPACE}"
describe_resource "daemonset" "${NAMESPACE}"
describe_resource "service" "${NAMESPACE}"

dump "ingresses-list" "kubectl get ingress -n ${NAMESPACE} -o wide" # 新增 Ingress 列表
describe_resource "ingress" "${NAMESPACE}"

dump "networkpolicies-list" "kubectl get networkpolicy -n ${NAMESPACE} -o wide" # 新增 NetworkPolicy 列表
describe_resource "networkpolicy" "${NAMESPACE}"

dump "hpa-list" "kubectl get hpa -n ${NAMESPACE} -o wide" # 新增 HPA 列表
describe_resource "hpa" "${NAMESPACE}"
describe_resource "configmap" "${NAMESPACE}"
describe_resource "secret" "${NAMESPACE}"
describe_resource "pvc" "${NAMESPACE}"

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
collect_pod_logs "${NAMESPACE}"

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
