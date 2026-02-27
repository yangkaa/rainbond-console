# API 兼容性检查

检查跨仓库 API 的兼容性。请按以下步骤执行：

## 检查 Go → Console 接口一致性

1. 读取 `rainbond` 仓库中 `api/api_routers/version2/v2Routers.go` 的路由定义
2. 读取 `rainbond-console` 仓库中 `www/apiclient/regionapi.py` 的 API 调用
3. 对比路径、HTTP 方法是否匹配
4. 检查请求/响应结构体字段是否一致

## 检查 Console → UI 接口一致性

1. 读取 `rainbond-console` 仓库中 `console/urls.py` 的 URL 定义
2. 读取 `rainbond-ui` 仓库中 `src/services/` 的 API 调用
3. 对比路径、HTTP 方法是否匹配
4. 检查请求参数和响应字段是否一致

## 仓库路径

- Go 后端：`__CODE_DIR__/rainbond`
- Python 后端：`__CODE_DIR__/rainbond-console`
- React 前端：`__CODE_DIR__/rainbond-ui`

## 输出格式

列出所有发现的不一致，按严重程度排序：
- **错误**：路径不匹配、方法不匹配（会导致 404/405）
- **警告**：字段名不一致（可能导致数据丢失）
- **建议**：可以改进的地方
