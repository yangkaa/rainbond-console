---
description: 基于规范文档驱动的TDD开发，严格按照规范执行任务
---

你是一个严格遵循规范的开发者。按照规范文档中的任务定义，使用TDD方式完成开发。

## 输入格式

```
<规范文档路径> <commit-ID 或 task-ID>
```

示例:
- `.claude/specs/cluster-backup.yaml commit-1` - **按 commit 执行（推荐）**
- `.claude/specs/cluster-backup.yaml task-1.1` - 单个任务执行
- `.claude/specs/cluster-backup.md commit-2`

如果只提供规范文档路径，显示 commit 分组概览和可用任务。
如果不提供任何参数，查找 `.claude/specs/` 下最近的规范文档。

## 执行模式

### 模式 1: 按 Commit 执行（推荐）
```bash
/spec-driven spec.yaml commit-1
```
- 批量执行 commit 包含的所有 task
- 所有 task 完成后，自动创建 git commit
- commit 消息使用规范中定义的 `message`

### 模式 2: 按 Task 执行
```bash
/spec-driven spec.yaml task-1.1
```
- 只执行单个 task
- 不自动 commit（需手动或等整个 commit 的 task 都完成）

## 工作流程

### 1. 解析规范
- 读取规范文档（支持 YAML 和 Markdown 格式）
- 判断输入是 `commit-X` 还是 `task-X.X`
- 如果是 commit-X：
  - 定位 commit 定义
  - 获取 commit 包含的所有 task ID 列表
  - 获取 commit message
- 如果是 task-X.X：
  - 直接定位单个任务
- 提取任务的所有定义：
  - `name`: 任务名称
  - `files.create`: 需要创建的文件
  - `files.modify`: 需要修改的文件
  - `implementation`: 实现要点
  - `tdd.test_file`: 测试文件路径
  - `tdd.test_cases`: 测试用例列表
  - `acceptance`: 验收标准
  - `references`: 参考文件

### 2. 准备阶段
- 读取 `references` 中的所有参考文件
- 理解现有代码模式和约定
- 检查并切换到正确的分支（如果 meta.branch 指定）
- 使用 TodoWrite 创建任务跟踪

### 3. TDD执行 (红-绿-重构)

#### 红灯阶段 (Red)
```
目标：编写失败的测试

1. 根据 tdd.test_file 创建测试文件
2. 根据 tdd.test_cases 编写测试用例
3. 测试函数命名：Test{Function}_{Scenario}_{Expected}
4. 运行测试：go test {package} -run {TestName} -v
5. 确认测试失败（这是期望的！）

输出：
- 创建的测试文件
- 测试失败信息（证明测试有效）
```

#### 绿灯阶段 (Green)
```
目标：用最少的代码让测试通过

1. 根据 files.create 创建实现文件
2. 根据 implementation 要点编写代码
3. 参考 references 中的现有代码模式
4. 运行测试：go test {package} -run {TestName} -v
5. 确认测试通过

输出：
- 创建/修改的实现文件
- 测试通过信息
```

#### 重构阶段 (Refactor)
```
目标：在保持测试通过的前提下改进代码

检查点：
- 代码是否有重复？
- 命名是否清晰？
- 结构是否合理？
- 是否符合项目规范？

如需重构：
1. 小步修改
2. 每次修改后运行测试
3. 确保测试始终通过
```

### 4. 验收验证
- 按顺序执行 `acceptance` 中的每条命令
- 验证输出符合 `expect` 预期：
  - `exit_code: 0` - 命令返回码为0
  - `contains: XXX` - 输出包含指定文本
  - `not_contains: XXX` - 输出不包含指定文本
- 所有验收点必须通过

### 5. 更新任务状态
- 在规范文档中将任务 `status` 从 `pending` 更新为 `completed`
- 如果是 YAML 格式，直接更新
- 如果是 Markdown 格式，更新 `**状态**: pending` 为 `**状态**: completed`

### 5.1 Commit 模式：自动提交（仅 commit-X 模式）
当使用 `commit-X` 模式且所有 task 完成后：

1. **检查所有 task 状态**
   - 确认 commit 包含的所有 task 都已 completed

2. **执行 Git 提交**
   ```bash
   git add <所有变更的文件>
   git commit -m "<commit.message>"
   ```

3. **更新 Commit 状态**
   - 在规范文档中更新 commit 状态为 completed
   - Markdown: 更新 Commit 分组表格中的状态列

### 6. 完成报告

#### Commit 模式报告
```
## Commit 完成报告

### Commit 信息
- Commit ID: {commit_id}
- 消息: {commit_message}
- 状态: 已提交

### 包含任务
- task-1.1: {name}
- task-1.2: {name}
- task-1.3: {name}

### 文件变更
- 创建: {files}
- 修改: {files}

### Git 提交
- Commit Hash: {hash}
- 变更文件数: {count}

### 下一步
建议执行: /spec-driven {spec_path} commit-2
```

#### Task 模式报告
```
## 任务完成报告

### 任务信息
- 任务ID: {task_id}
- 任务名称: {name}
- 所属 Commit: {commit_id}
- 状态: 完成

### 文件变更
- 创建: {files}
- 修改: {files}

### 测试结果
- 测试文件: {test_file}
- 通过: {test_count} 个测试用例

### 验收标准
- {acceptance_1}
- {acceptance_2}

### Commit 进度
- {commit_id}: 2/3 tasks 完成
- 剩余: task-1.3

### 下一步
建议执行: /spec-driven {spec_path} {next_task_id}
或执行整个 commit: /spec-driven {spec_path} {commit_id}
```

## 错误处理

### Commit ID 不存在
```
Commit {commit_id} 不存在

可用 Commit 列表：
| Commit | 消息 | 任务 | 状态 |
|--------|------|------|------|
| commit-1 | feat: 实现套餐详情接口 | task-1.1, task-1.2 | pending |
| commit-2 | test: 添加测试 | task-1.3 | pending |
```

### 任务ID不存在
```
任务 {task_id} 不存在

可用任务列表：
- task-1.1: {name} [pending] (commit-1)
- task-1.2: {name} [completed] (commit-1)
- task-2.1: {name} [pending] (commit-2)
```

### 验收失败
```
验收标准未通过

失败项：
- 命令: {cmd}
- 预期: {expect}
- 实际: {actual}

正在尝试修复...
```

### 依赖未完成
```
任务 {task_id} 依赖以下未完成任务：
- task-1.1: {name}
- task-1.2: {name}

建议先完成依赖任务。
```

## TDD检查清单

### 每个 Task 完成前的检查：
```
- 测试文件已创建
- 所有测试用例已编写
- 测试先失败后通过
- 实现代码符合要点
- go build ./... 编译通过
- go vet ./... 无警告
- 所有验收标准通过
- 任务状态已更新
```

### Commit 模式额外检查（执行 commit-X 时）：
```
- 所有包含的 task 都已完成
- 所有变更文件已 git add
- commit 消息符合规范
- git commit 执行成功
- commit 状态已更新为 completed
```

参数：$ARGUMENTS
