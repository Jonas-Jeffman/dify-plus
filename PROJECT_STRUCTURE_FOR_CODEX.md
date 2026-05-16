# PROJECT_STRUCTURE_FOR_CODEX

## 1. 项目整体定位

本项目是 Dify-Plus：在 Dify 基础上进行企业场景二次开发，并新增独立管理中心。README 中明确描述为“管理中心 + Dify 二开”。

项目是多模块项目，不是单一应用。当前仓库同时包含：

- Dify 后端 API：`api/`，Python + Flask + Celery。
- Dify 主前端：`web/`，Next.js + React + TypeScript。
- 管理中心：`admin/`，基于 gin-vue-admin，包含 Go + Gin 后端和 Vue3 + Vite 前端。
- Docker Compose 部署配置：`docker/`。
- SDK、文档、运维脚本和压测脚本：`sdks/`、`docs/`、`scripts/`。

核心目标：提供 Dify 自托管能力，并在其上增加用户额度、API 密钥额度、应用中心、钉钉登录、管理后台、费用报表等二开能力。未发现单独的 CLI 主入口；如需确认 CLI 能力，应继续查看 `api/commands.py`、`dev/` 和相关脚本。

## 2. 项目根目录概览

- `admin/`：Dify-Plus 管理中心。包含 `admin/server/` Go 后端、`admin/web/` Vue 管理端、`admin/deploy/` 部署配置。二次开发管理后台功能优先从这里开始。
- `api/`：Dify 后端 API、业务服务、模型、迁移、Celery 任务、RAG/Workflow/LLM 运行时等。入口包括 `api/app.py`、`api/app_factory.py`。
- `web/`：Dify 主前端。Next.js App Router 结构，页面在 `web/app/`，组件在 `web/app/components/`，请求层在 `web/service/` 和 `web/contract/`。
- `docker/`：Docker Compose、Nginx、sandbox、数据库/缓存/向量库等部署配置。Dify-Plus 全量 compose 是 `docker/docker-compose.dify-plus.yaml`。
- `dev/`：开发辅助脚本，如 `start-api`、`start-web`、`start-worker`、`start-docker-compose`、格式化和类型检查脚本。
- `docs/`：多语言文档。实际内容需要按具体问题继续确认。
- `images/`：README 和项目说明使用的图片资源。
- `scripts/`：运维脚本和压测脚本。根目录脚本偏向文档索引任务处理，`scripts/stress-test/` 是 Locust 压测套件。
- `sdks/`：SDK 目录，发现 `nodejs-client`、`php-client`。
- `.github/`：GitHub 相关配置，具体 CI/CD 内容需要进一步确认。
- `.gitlab-ci.yml`：GitLab CI 配置文件，说明存在 GitLab CI 迹象。
- `.devcontainer/`：开发容器配置，具体内容需要进一步确认。
- `.vscode/`：VS Code 项目配置。
- `.agents/`、`.codex/`、`.claude/`：AI 辅助开发相关本地配置或说明。
- `README.md`：Dify-Plus 项目介绍、二开功能、启动文档链接。
- `README_DIFY.md`：Dify 原项目 README，具体内容需要按需阅读。
- `Makefile`：根目录开发准备、后端检查、测试、Docker 镜像构建和推送命令。
- `CONTRIBUTING.md`、`LICENSE`、`AUTHORS`：贡献、许可和作者信息。
- `.editorconfig`、`.gitignore`、`.gitattributes`、`.coveragerc`：通用工程配置。

## 3. 核心模块说明

### Dify 后端 API：`api/`

- 入口：`api/app.py` 根据命令创建 Flask app 或迁移 app；`api/app_factory.py` 初始化配置、数据库、Redis、Celery、蓝图、存储、OpenTelemetry 等扩展。
- 接口层：`api/controllers/`，按 `console`、`service_api`、`web`、`files`、`mcp`、`trigger` 等拆分。
- 业务层：`api/services/`，包含账户、应用、数据集、模型、计费、工作流、RAG pipeline 等服务。
- 数据模型：`api/models/`。
- Workflow/Agent/RAG/LLM：`api/core/workflow/`、`api/core/model_runtime/`、`api/core/rag/`、`api/services/rag_pipeline/`。
- 异步任务：`api/tasks/`、`api/schedule/`，Celery 入口通过 `app.celery`。
- 二开代码：README 说明二开部分会用 `extend` 标记；实际发现大量 `*_extend.py`、`migrations_extend/`、`configs/extend/`。

### Dify 主前端：`web/`

- 框架：Next.js + React + TypeScript。
- 页面入口：`web/app/`。
- 组件：`web/app/components/`。
- API 请求：`web/service/`。
- typed contract：`web/contract/`，存在 oRPC 相关依赖。
- 国际化：`web/i18n/`、`web/i18n-config/`。
- 测试：Vitest + React Testing Library，测试文件分布在组件旁和 `web/__tests__/`。
- 二开前端：发现 `extend` 命名文件和目录，如 `apps-center-extend`、`account-money-extend`、`secret-key-quota-set-modal-extend.tsx`。

### 管理中心：`admin/`

- 管理中心后端：`admin/server/`，Go + Gin + GORM + Viper + Zap。入口为 `admin/server/main.go`。
- 管理中心后端分层：`api/v1/`、`router/`、`service/`、`model/`、`middleware/`、`initialize/`、`config/`。
- Dify-Plus 管理业务集中在：`admin/server/api/v1/gaia/`、`admin/server/service/gaia/`、`admin/server/model/gaia/`、`admin/server/router/gaia/`。
- 管理中心前端：`admin/web/`，Vue3 + Vite + Element Plus。页面在 `admin/web/src/view/`，请求在 `admin/web/src/api/`。
- 管理中心二开页面集中在：`admin/web/src/view/gaia/`、`quota/`、`systemIntegrated/` 等。

### Worker 和任务队列

- Dify 后端使用 Celery，队列包括 dataset、workflow、mail、plugin、conversation、schedule 等。
- 开发脚本：`dev/start-worker`。
- compose 中 Dify-Plus 还发现 `worker-gaia`、`worker-dataset`、`worker_beat` 等服务。

### 部署和反向代理

- `docker/docker-compose.yaml`：Dify 标准 Docker Compose。
- `docker/docker-compose.dify-plus.yaml`：Dify-Plus 全量 Docker Compose，发现 `api`、`worker`、`web`、`nginx`、`admin-web`、`admin-server`、`sandbox-full` 等服务。
- `docker/docker-compose.middleware.yaml`：本地开发中间件，发现 PostgreSQL/MySQL、Redis、sandbox、plugin daemon、SSRF proxy、Weaviate。
- `docker/nginx/conf.d/default.conf.template`：将 `/admin/` 代理到 `admin-web`，`/admin/api/` 代理到 `admin-server`，`/console/api`、`/api`、`/v1` 等代理到 `api`，`/` 代理到 `web`。

### SDK 和脚本

- `sdks/nodejs-client/`：Node.js SDK，含 `package.json`、`pnpm-workspace.yaml`。
- `sdks/php-client/`：PHP SDK，具体结构需要进一步确认。
- `scripts/stress-test/`：Locust SSE 压测套件，主要压测 `/v1/workflows/run`。

## 4. 技术栈和依赖

- 后端 API：Python 3.11 到 3.12、Flask、Flask-SQLAlchemy、Flask-Migrate、Celery、Redis、Gunicorn、gevent、Pydantic、SQLAlchemy、OpenTelemetry、Sentry、LiteLLM、Weaviate client 等。
- 后端 API 包管理：`uv`，配置在 `api/pyproject.toml` 和 `api/uv.lock`。
- 主前端：Node.js、pnpm、Next.js 16、React 19、TypeScript、Tailwind CSS、TanStack Query、oRPC、Vitest、Storybook、ESLint。
- 管理中心后端：Go，Gin、GORM、Viper、Zap、Casbin、Redis client、MySQL/PostgreSQL/SQL Server/SQLite drivers 等。
- 管理中心前端：Vue3、Vite、Element Plus、Pinia、Vue Router、Axios、ECharts、Tailwind CSS。
- 数据库：Dify 默认 PostgreSQL，compose 也支持 MySQL；管理中心开发 compose 使用 MySQL；Go 后端依赖包含多种 GORM driver。
- 缓存和队列：Redis；Celery broker/backend 使用 Redis。
- 向量数据库：compose 和依赖中发现 Weaviate、Qdrant、Milvus、PGVector、Chroma、OpenSearch、ElasticSearch、ClickHouse/ClickZetta 等迹象；实际启用由环境变量和 compose profile 决定。
- 部署工具：Docker、Docker Compose、Nginx、Certbot；管理中心还发现 Kubernetes YAML。
- CI/CD：发现 `.gitlab-ci.yml` 和 `.github/`，具体流程需要进一步确认。
- 数据库 seed/init：发现管理中心 `admin/server/source/`、`initialize/`，Dify API 有迁移和 initdb 相关服务；具体初始化流程需要按环境确认。

未发现：统一 monorepo package manager 配置；根目录没有 `package.json`。未发现 Terraform。未发现明确的 Helm chart。

## 5. 启动方式

### 本地开发：Dify API + Web

README 和脚本推荐先启动中间件，再源码启动 API 和 Web。

```bash
cd docker
cp middleware.env.example middleware.env
docker compose -f docker-compose.middleware.yaml --profile postgresql --profile weaviate -p dify up -d
```

```bash
cd api
cp .env.example .env
uv sync --dev
uv run flask db upgrade
uv run flask extend_db upgrade
uv run flask run --host 0.0.0.0 --port=5001 --debug
```

```bash
cd web
cp .env.example .env.local
pnpm install
pnpm run dev
```

可选脚本：

- `dev/start-docker-compose`：启动中间件。
- `dev/start-api`：执行 `flask db upgrade` 并启动 Flask debug server。注意该脚本未显式执行 `extend_db upgrade`，二开表迁移需自行确认。
- `dev/start-web`：安装依赖并启动 `pnpm dev:inspect`。
- `dev/start-worker`：启动 Celery worker。

根目录 `Makefile` 提供：

- `make dev-setup`：准备 Docker 中间件、Web 依赖、API 依赖和 API 普通迁移。
- `make test`、`make lint`、`make type-check`：后端测试和检查。

### 本地开发：管理中心

源码方式：

```bash
cd admin/server
go run main.go
```

```bash
cd admin/web
yarn install
yarn serve
```

管理中心开发 compose：

```bash
cd admin/deploy/docker-compose
docker compose -f docker-compose-dev.yaml up -d
```

该 compose 会启动 `web`、`server`、`mysql`、`redis`。其中示例文件包含默认数据库密码，不要直接用于生产。

### 服务器部署

Dify 标准部署：

```bash
cd docker
cp .env.example .env
docker compose up -d
```

Dify-Plus 全量部署：

```bash
cd docker
cp .env.example .env
docker compose -f docker-compose.dify-plus.yaml up -d
```

部署前必须根据环境配置 `.env`，不要提交真实密钥。Nginx 反代路径见 `docker/nginx/conf.d/default.conf.template`。

## 6. 配置文件和环境变量

实际发现的关键配置：

- `docker/.env.example`：Docker Compose 主环境变量示例，覆盖 API、Web、数据库、Redis、Celery、存储、向量库、Nginx、插件、OpenTelemetry 等。
- `api/.env.example`：Dify API 环境变量示例。
- `web/.env.example`：Dify 主前端环境变量示例，包含 API prefix、公开 API prefix、部署环境等。
- `admin/web/.env.development`、`admin/web/.env.production`：管理中心前端 Vite 环境配置。
- `admin/server/config.yaml`、`admin/server/config.docker.yaml`：管理中心后端配置，包含数据库、Redis、JWT、Dify API 地址、存储等配置结构。
- `docker/admin-server/config.docker.yaml`：Docker 场景下管理中心后端配置。
- `docker/docker-compose*.yaml`：服务、网络、卷、环境变量和镜像配置。
- `docker/nginx/conf.d/default.conf.template`：Nginx 路由和反向代理模板。
- `api/pyproject.toml`：Python 依赖、开发依赖、测试配置。
- `web/package.json`、`web/next.config.ts`、`web/vitest.config.ts`、`web/eslint.config.mjs`、`web/tailwind.config.js`：主前端依赖和构建/测试配置。
- `admin/web/package.json`、`admin/web/vite.config.js`：管理中心前端配置。
- `admin/server/go.mod`：管理中心 Go 依赖。
- `.gitlab-ci.yml`：GitLab CI 配置，具体流水线含义需要进一步确认。

安全规则：不要把 `.env`、真实 API Key、数据库密码、JWT signing key、云存储密钥提交到仓库。文档或代码评审中只引用变量名，不输出真实值。

## 7. 数据库和迁移

### Dify API 数据库

- ORM/模型：`api/models/`。
- 普通迁移：`api/migrations/`，使用 Flask-Migrate/Alembic。
- 二开迁移：`api/migrations_extend/`，README 说明使用 `flask extend_db ...`。
- 迁移命令：

```bash
cd api
uv run flask db upgrade
uv run flask extend_db upgrade
```

`api/docker/entrypoint.sh` 中也发现 `flask extend_db upgrade`。涉及二开表或字段时，应优先放在 `api/migrations_extend/`，但实际约定需要结合现有迁移继续确认。

### 管理中心数据库

- 模型：`admin/server/model/`，Dify-Plus 管理业务集中在 `admin/server/model/gaia/`。
- 初始化：`admin/server/initialize/`、`admin/server/source/`。
- ORM：GORM。
- 默认开发 compose 使用 MySQL；Go 依赖也包含 PostgreSQL、SQL Server、SQLite driver。实际生产数据库类型由配置决定。

### 中间件和向量库

- `docker/docker-compose.middleware.yaml` 提供 PostgreSQL/MySQL、Redis、Weaviate 等开发依赖。
- `docker/docker-compose.dify-plus.yaml` 中发现多种向量库和检索服务，实际启用取决于 `.env` 和 profile。

## 8. API 和业务逻辑定位方法

### 定位 Dify 主前端页面

1. 页面路由从 `web/app/` 开始找。
2. 公共组件看 `web/app/components/`。
3. 请求和 hook 看 `web/service/`。
4. typed contract 看 `web/contract/`。
5. 文案看 `web/i18n/`。
6. Dify-Plus 二开优先搜索 `extend`、`billing`、`quota`、`dingtalk`、`gaia`。

### 定位 Dify API

1. 根据 URL 路径在 `api/controllers/` 搜索。
2. 根据 controller import 追到 `api/services/`。
3. 根据实体名追到 `api/models/`。
4. 涉及异步任务继续查 `api/tasks/`、`api/schedule/`。
5. 涉及工作流、RAG、模型运行时继续查 `api/core/workflow/`、`api/core/rag/`、`api/core/model_runtime/`。
6. 涉及二开字段或表继续查 `api/migrations_extend/`。

### 定位管理中心功能

1. 前端页面：`admin/web/src/view/`。
2. 前端请求：`admin/web/src/api/`。
3. 路由和权限：`admin/web/src/router/`、`admin/web/src/permission.js`。
4. 后端路由：`admin/server/router/`。
5. 后端接口：`admin/server/api/v1/`。
6. 后端业务：`admin/server/service/`。
7. 后端模型：`admin/server/model/`。
8. Dify-Plus 管理业务重点看 `gaia` 子目录。

### 定位部署配置

- Dify 标准服务：`docker/docker-compose.yaml`。
- Dify-Plus 全量服务：`docker/docker-compose.dify-plus.yaml`。
- 本地中间件：`docker/docker-compose.middleware.yaml`。
- 管理中心独立部署：`admin/deploy/`。
- Nginx 路由：`docker/nginx/conf.d/default.conf.template`。
- 镜像构建：根 `Makefile`、各模块 `Dockerfile`。

## 9. 常用搜索命令

```bash
# 根目录扫描文件
rg --files

# 搜索二开代码
rg "extend|gaia|billing|quota|ding_talk|dingtalk"

# 搜索前端页面文案
rg "页面文案" web/app web/i18n admin/web/src/view

# 搜索主前端路由和页面
rg "page.tsx|layout.tsx" web/app
rg "apps-center|account-money|secret-key" web/app web/service web/contract

# 搜索主前端 API 调用
rg "fetch|request|client|NEXT_PUBLIC_API_PREFIX" web/service web/contract web/app

# 搜索 Dify API 路由或接口路径
rg "/console/api|/v1|/api|route|Resource|Blueprint" api/controllers api/extensions

# 搜索 Dify API 业务服务
rg "class .*Service|def .*" api/services

# 搜索数据库模型和字段
rg "class .*\\(|Column\\(|db\\.|mapped_column|account_money|api_token" api/models api/migrations api/migrations_extend

# 搜索 Celery 任务和定时任务
rg "celery|@shared_task|@app.task|schedule|worker-gaia|worker_beat" api/tasks api/schedule api docker

# 搜索 Workflow/RAG/LLM/provider
rg "workflow|rag|provider|model_runtime|prompt|embedding|vector" api/core api/services web/app

# 搜索管理中心前端页面和接口
rg "quota|dashboard|tenants|model|dingTalk" admin/web/src/view admin/web/src/api

# 搜索管理中心后端路由、接口、业务
rg "gaia|quota|dashboard|tenants|Router|Api" admin/server/router admin/server/api admin/server/service admin/server/model

# 搜索环境变量和部署配置
rg "DB_HOST|REDIS|VECTOR_STORE|ADMIN_GROUP_ID|EMAIL_DOMAIN|SECRET_KEY|NGINX|admin-server|admin-web" docker api web admin

# 搜索迁移命令和迁移文件
rg "flask db|extend_db|Alembic|migrations_extend|RegisterTables|AutoMigrate" api admin
```

## 10. 推荐二次开发流程

1. 新建分支，先确认当前工作区是否有他人改动：`git status`。
2. 阅读本文件，然后必须继续阅读相关源码、README 和配置，不能只依赖本文件。
3. 用 `rg` 从页面文案、接口路径、函数名、表字段或配置项定位代码。
4. 小范围修改，优先遵循当前模块的分层和命名习惯；不要顺手重构无关代码。
5. 涉及 Dify-Plus 二开时，优先检查是否已有 `extend` 文件或 `gaia` 模块。
6. 涉及数据库时，明确是否需要新增普通迁移或 `migrations_extend` 迁移；不要只改模型。
7. 涉及异步逻辑时，确认 Celery 队列、worker 是否需要启动或新增配置。
8. 涉及前后端联动时，同时确认接口路径、请求参数、响应类型、i18n 文案和错误处理。
9. 运行最小必要验证：
   - API：`uv run pytest <target>`、`uv run ruff check <target>`。
   - Web：`pnpm test <target>`、`pnpm type-check` 或相关组件测试。
   - 管理中心后端：`go test ./...`，具体范围按修改点收窄。
   - 管理中心前端：`yarn build` 或相关页面手动验证，具体测试能力需要进一步确认。
10. 查看差异：`git diff --stat` 和 `git diff`，确认没有改到无关文件或密钥。
11. 提交前说明是否需要数据库迁移、环境变量、重建镜像、重启 worker 或执行初始化脚本。
12. 部署验证优先在测试环境执行，确认 Nginx 路由、API、worker、管理中心和数据库迁移状态。

## 11. Codex 使用规则

后续 Codex 修改代码前应先读取本文件，但不能完全依赖本文件；必须继续读取与任务直接相关的源码、配置、测试和启动脚本来确认。

Codex 处理本仓库时应遵守：

- 小范围修改，只改完成任务必需的文件。
- 不要重构无关代码。
- 不要格式化整个项目。
- 不要提交或输出真实密钥、token、数据库密码、JWT key、云服务凭证。
- 涉及数据库必须说明是否需要 migration，并指出迁移目录。
- 涉及部署必须说明是否需要重建镜像、重启服务、执行迁移或修改环境变量。
- 涉及前端页面必须检查对应 API、i18n、类型和响应结构。
- 涉及 worker/异步任务必须确认队列名称和启动方式。
- 发现无法判断的模块作用时，标注“需要进一步确认”，不要猜测。
- 如果工作区已有非本次修改的改动，不要回滚；需要先读懂并避开或兼容。

## 12. 后续开发提示词模板

### 定位功能代码

请先阅读 `PROJECT_STRUCTURE_FOR_CODEX.md`，然后根据“<页面文案/接口路径/功能名>”定位相关代码。只读代码，不修改。请列出前端页面、请求层、后端接口、业务服务、模型/迁移、配置文件的位置，并说明你判断的调用链。

### 小范围修改代码

请先阅读 `PROJECT_STRUCTURE_FOR_CODEX.md` 和相关源码。我要修改“<具体行为>”。只做最小范围改动，不重构无关代码，不格式化整个项目。改完后运行与改动相关的最小测试/检查，并说明是否涉及数据库迁移、环境变量、worker 或镜像重建。

### 排查报错

请先阅读 `PROJECT_STRUCTURE_FOR_CODEX.md`。下面是报错和复现步骤：“<报错/日志/步骤>”。请定位可能原因，优先检查配置、启动方式、接口路径、数据库迁移、队列和依赖版本。先给出结论和证据；需要改代码时再做最小修复。

### 新增功能

请先阅读 `PROJECT_STRUCTURE_FOR_CODEX.md`。我要新增“<功能描述>”。请先定位应该放在哪些模块，给出涉及的前端页面、API、service、model/migration、配置和测试范围。确认后按现有项目风格小范围实现，并说明部署影响。

### 部署检查

请先阅读 `PROJECT_STRUCTURE_FOR_CODEX.md` 和部署配置。我要部署到“<环境>”。请检查 Docker Compose、Nginx 路由、环境变量、数据库迁移、Redis/Celery、向量库、admin-web/admin-server、镜像版本是否一致。不要输出真实密钥，只列出需要配置的变量名和检查命令。

## 13. 风险点和注意事项

- 多服务依赖复杂：API、Web、worker、Redis、数据库、向量库、plugin daemon、sandbox、admin-web、admin-server、Nginx 需要协同。
- 环境变量很多：`docker/.env.example` 覆盖范围广，生产部署必须逐项确认，不能沿用示例密钥。
- 数据库迁移分两套：Dify 普通迁移在 `api/migrations/`，二开迁移在 `api/migrations_extend/`，遗漏 `extend_db upgrade` 会导致二开功能异常。
- Docker 镜像和源码可能不同步：compose 中使用的镜像版本可能不是当前源码构建结果，二开部署前要确认镜像 tag。
- 管理中心和 Dify API 共享认证/业务数据：JWT、Dify API 地址、管理员组、用户同步等配置错误会影响登录和管理功能。
- 前后端类型可能不一致：主前端存在 `contract/` 和 service 层，后端响应改动需要同步类型、调用方和测试。
- Worker 队列影响功能完整性：数据集索引、workflow、计费/额度统计、插件任务等可能依赖 Celery worker 和特定队列。
- 向量库选择影响 RAG：`VECTOR_STORE` 和相关 endpoint 配置必须与实际 compose profile/服务一致。
- 外部 API Key 风险：模型供应商、云存储、邮件、钉钉、OAuth、Sentry/OpenTelemetry 等均可能需要密钥，禁止提交真实值。
- 依赖版本冲突风险：`api/pyproject.toml`、`web/package.json`、`admin/server/go.mod` 均有大量依赖，升级需小心验证。
- 管理中心开发 compose 示例包含默认数据库口令，只适合本地示例，生产必须替换。
- README 中部分详细部署步骤指向 GitHub Wiki，离线环境下可能无法访问；需要进一步确认时应查看本地 compose、Dockerfile 和脚本。
- `.github/` 和 `.gitlab-ci.yml` 同时存在，实际 CI/CD 使用哪一套需要进一步确认。
