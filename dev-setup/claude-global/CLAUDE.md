# 全局开发规范

## 代码提交规范

### 提交前验证
- 代码修改完成后，必须运行相关测试和构建验证
- Go 项目：运行 `go build ./...` 确保编译通过
- Go 项目：运行 `go vet ./...` 检查代码问题
- 有测试的项目：运行相关测试确保通过
- 所有验证通过后才能提交

### Git Commit 格式
- 提交信息只包含变更描述，保持简洁
- 禁止添加 "Generated with Claude Code" 等 AI 生成标识
- 禁止添加 "Co-Authored-By: Claude" 等 AI 作者信息
- 禁止添加任何 emoji 前缀
- 使用 Conventional Commits 格式：`type: description`
- 常用 type：feat, fix, refactor, docs, test, chore

### Commit 消息语言
- 默认使用英文
- 具体语言由项目级 CLAUDE.md 配置决定

## Rainbond Platform Architecture

### Repository Map

| Repository | Language | Path | Description |
|-----------|----------|------|-------------|
| rainbond | Go 1.23 | `__CODE_DIR__/rainbond` | Core services (API, builder, worker) — interfaces with Kubernetes |
| rainbond-console | Python 3.6 / Django 2.2 | `__CODE_DIR__/rainbond-console` | Web backend — serves UI, orchestrates Go API calls |
| rainbond-ui | React 16.8 / UMI 3.5 | `__CODE_DIR__/rainbond-ui` | Web frontend — user-facing dashboard |

### Data Flow

```
rainbond-ui (React)
    ↓ HTTP: /console/*, /openapi/v1/*
rainbond-console (Django, port 7070)
    ↓ HTTP: /v2/tenants/{tenant_name}/...
rainbond (Go, port 8443)
    ↓ Kubernetes API
Kubernetes Cluster
```

### Shared Database

Both `rainbond-console` and `rainbond` read/write the same MySQL database. Model definitions exist in both repos — keep them in sync when modifying schema.

### Cross-Repository Feature Implementation Order

When implementing a feature that spans multiple repos, work in this order:
1. `rainbond` (Go) — Add API endpoint, database model, business logic
2. `rainbond-console` (Python) — Add region API client call, service, view
3. `rainbond-ui` (React) — Add service function, DVA model, page/component
