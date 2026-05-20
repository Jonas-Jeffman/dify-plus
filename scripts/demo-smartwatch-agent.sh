#!/usr/bin/env bash
# Smartwatch Product Advisor Agent — Qwen 演示启动脚本
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCKER_DIR="${ROOT}/docker"
JSON_FILE="${ROOT}/api/constants/recommended_apps.json"
DSL_FILE="${ROOT}/docs/demo/smartwatch-advisor-agent-qwen.yml"
APP_ID="4c94b94b-ec48-4fb4-a540-9ccf0ebad0da"

# ---------- 1. 检查 Qwen API Key（命令行 export）----------
if [[ -z "${DASHSCOPE_API_KEY:-}" ]]; then
  if [[ -f "${DOCKER_DIR}/qwen.env" ]]; then
    # shellcheck disable=SC1091
    set -a && source "${DOCKER_DIR}/qwen.env" && set +a
  fi
fi

if [[ -z "${DASHSCOPE_API_KEY:-}" ]]; then
  echo "错误: 未设置 DashScope API Key。"
  echo "请先执行:"
  echo "  export DASHSCOPE_API_KEY=sk-你的密钥"
  echo "或:"
  echo "  cp ${DOCKER_DIR}/qwen.env.example ${DOCKER_DIR}/qwen.env"
  echo "  # 编辑 qwen.env 填入密钥后"
  echo "  source ${DOCKER_DIR}/qwen.env"
  exit 1
fi

echo "已检测到 DASHSCOPE_API_KEY（长度 ${#DASHSCOPE_API_KEY}）"
echo "说明: Key 用于在 Dify 网页「设置 → 模型供应商 → 通义千问」中填写。"
echo "注意: Qwen/Tongyi 是模型供应商，不是插件，不需要在 Plugins 市场安装。"

# ---------- 2. 校验 Agent 模板 JSON ----------
python3 <<PY
import json
from pathlib import Path

json_file = Path("${JSON_FILE}")
app_id = "${APP_ID}"
data = json.loads(json_file.read_text(encoding="utf-8"))
details = data["app_details"][app_id]
export_data = details["export_data"]

if "name: Smartwatch Product Advisor Agent" not in export_data:
    raise SystemExit("错误: 模板名称异常，未找到 Smartwatch Product Advisor Agent")
if "\n    provider: tongyi\n" not in export_data or "\n    name: qwen-plus\n" not in export_data:
    raise SystemExit(
        "错误: 模板模型异常，当前模板未配置为 provider=tongyi 且 name=qwen-plus"
    )

print("OK: Smartwatch 模板已配置 tongyi + qwen-plus")
PY

# ---------- 3. 导出 DSL（供 Import DSL 使用）----------
mkdir -p "$(dirname "${DSL_FILE}")"
python3 <<PY
import json, pathlib
d = json.load(open("${JSON_FILE}"))
pathlib.Path("${DSL_FILE}").write_text(d["app_details"]["${APP_ID}"]["export_data"], encoding="utf-8")
print("OK: 已导出 ${DSL_FILE}")
PY

# ---------- 4. 确保 docker/.env 使用内置模板 ----------
ENV_FILE="${DOCKER_DIR}/.env"
if [[ ! -f "${ENV_FILE}" ]]; then
  cp "${DOCKER_DIR}/.env.example" "${ENV_FILE}"
  echo "OK: 已自动初始化 ${ENV_FILE}"
fi

if grep -q '^HOSTED_FETCH_APP_TEMPLATES_MODE=' "${ENV_FILE}"; then
  sed -i 's/^HOSTED_FETCH_APP_TEMPLATES_MODE=.*/HOSTED_FETCH_APP_TEMPLATES_MODE=builtin/' "${ENV_FILE}"
else
  echo 'HOSTED_FETCH_APP_TEMPLATES_MODE=builtin' >> "${ENV_FILE}"
fi

# ---------- 5. 启动 / 更新 Docker（无需先 docker compose down）----------
cd "${DOCKER_DIR}"
echo "正在启动 Dify-Plus 服务..."
docker compose -f docker-compose.dify-plus.yaml up -d
docker compose -f docker-compose.dify-plus.yaml restart api
docker compose -f docker-compose.dify-plus.yaml restart nginx

sleep 3
if docker exec docker-api-1 grep -q 'qwen-plus' /app/api/constants/recommended_apps.json 2>/dev/null; then
  echo "OK: API 容器已加载 Qwen 版 Smartwatch 模板"
else
  echo "警告: 容器内未检测到 qwen-plus，请检查 volume 挂载"
fi

echo "检查关键容器状态..."
docker compose -f docker-compose.dify-plus.yaml ps api web plugin_daemon nginx

echo "检查网页链路健康..."
if curl -fsS "http://127.0.0.1:80/console/api/health" >/dev/null; then
  echo "OK: /console/api/health 可访问，网页应可正常加载"
else
  echo "警告: /console/api/health 仍不可访问，请执行："
  echo "  docker compose -f docker-compose.dify-plus.yaml logs --tail=120 nginx"
  echo "  docker compose -f docker-compose.dify-plus.yaml logs --tail=120 api"
fi

echo ""
echo "========== 下一步（浏览器）=========="
echo "1) Windows SSH 转发: ssh -L 8080:127.0.0.1:80 ubuntu@<服务器IP>"
echo "2) 打开 http://127.0.0.1:8080"
echo "3) Settings → Model Provider → Tongyi（通义千问）→ API Key 填入:"
echo "   ${DASHSCOPE_API_KEY:0:8}...（与 export 的 DASHSCOPE_API_KEY 相同）"
echo "4) Studio → Create from Template → Agent → Smartwatch Product Advisor Agent"
echo "   若看不到模板，可 Import DSL: ${DSL_FILE}"
echo "5) Preview，示例问题: 「我想给孩子买一块手表，应该怎么选？」"
echo ""
echo "========== 常见问题定位 =========="
echo "A) 如果你之前在 Plugins 市场安装 qwen 失败：这是正常现象。"
echo "   原因是 qwen/tongyi 属于模型供应商配置，不是插件市场插件。"
echo "B) 如插件市场整体安装失败（与 qwen 无关），可检查 daemon 日志:"
echo "   docker compose -f docker-compose.dify-plus.yaml logs --tail=120 plugin_daemon"
echo "   docker compose -f docker-compose.dify-plus.yaml logs --tail=120 api"
echo ""
