# 跨仓库功能开发流程

你正在帮助开发者实现一个跨越 Rainbond 多个仓库的功能。请按以下流程引导：

## 第一步：需求分析

请开发者描述要实现的功能，然后分析：
1. 这个功能涉及哪些仓库？
2. 需要新增/修改哪些 API？
3. 数据库是否需要变更？

## 第二步：Go 后端（rainbond）

如果功能涉及 Go 后端，先在 `__CODE_DIR__/rainbond` 中：
1. 在 `db/model/` 定义数据模型（如需新表）
2. 在 `db/dao/` 添加 DAO 接口，`db/mysql/` 添加实现
3. 在 `api/model/` 定义请求/响应结构体
4. 在 `api/handler/` 实现业务逻辑
5. 在 `api/controller/` 添加 HTTP 处理函数
6. 在 `api/api_routers/version2/v2Routers.go` 注册路由
7. 运行 `go build ./...` 和 `go vet ./...` 验证

## 第三步：Python 后端（rainbond-console）

在 `__CODE_DIR__/rainbond-console` 中：
1. 在 `www/apiclient/regionapi.py` 的 `RegionInvokeApi` 类中添加调用 Go API 的方法
2. 在 `console/models/main.py` 添加模型（如需）
3. 在 `console/repositories/` 添加数据访问层（底部创建单例）
4. 在 `console/services/` 添加业务逻辑层（底部创建单例）
5. 在 `console/views/` 添加视图，继承合适的基类（通常是 `TenantHeaderView`）
6. 在 `console/urls.py` 注册 URL
7. 运行 `make format` 和 `make check` 验证

## 第四步：React 前端（rainbond-ui）

在 `__CODE_DIR__/rainbond-ui` 中：
1. 在 `src/services/api.js` 添加 API 调用函数
2. 在 `src/models/` 添加或更新 DVA model
3. 在 `src/pages/` 创建或修改页面组件
4. 在 `src/locales/` 添加中英文翻译
5. 在 `config/router.config.js` 添加路由（如需新页面）
6. 运行 `yarn build` 验证

## 第五步：联调检查

- 确认 Go API 路径与 Console 的 RegionInvokeApi 调用一致
- 确认 Console URL 与 UI 的 service 函数调用路径一致
- 确认请求/响应字段名在三个仓库中保持一致
