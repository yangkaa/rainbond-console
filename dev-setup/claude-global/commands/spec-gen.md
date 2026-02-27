---
description: 将设计文档转化为标准化的任务规范文档，支持 YAML 和 Markdown 格式
---

你是一个技术规范编写专家。将设计文档转化为可被 /spec-driven 解析执行的标准规范。

## 输入

设计文档路径（可选，默认读取最近的 plan 文件）

## 输出

标准化规范文档，保存到 `.claude/specs/{project-name}.yaml` 和 `.claude/specs/{project-name}.md`

## 核心概念：Commit 分组

**重要**: 任务必须按 commit 分组，每个 commit 代表一个逻辑完整的变更单元。

### 分组原则
1. **功能完整性** - 一个 commit 应该是可独立工作的功能单元
2. **文件相关性** - 修改相关文件的 task 放在一起（如 model + handler + 测试）
3. **垂直切片** - 一个完整的 API 实现（类型定义 + 业务逻辑 + 路由注册）
4. **验证任务合并** - 纯验证/测试的 task 合并到前一个 commit

### 分组示例
```
错误：每个 task 单独提交
task-1.1 → commit "添加类型定义"
task-1.2 → commit "实现接口"
task-1.3 → commit "添加测试"

正确：按功能完整性分组
commit-1 (task-1.1 + task-1.2 + task-1.3) → "feat: 实现套餐详情接口"
```

## 工作流程

### 1. 读取设计文档
- 读取指定路径或最近的 plan 文件
- 如果没有指定路径，查找 `.claude/plans/` 目录下最近修改的文件
- 解析文档结构

### 2. 提取关键信息
- 项目元信息（名称、仓库、分支）
- Sprint划分
- 每个Task的详细定义：
  - 文件变更列表（create/modify）
  - 实现要点（implementation）
  - TDD要求（测试文件、测试用例）
  - 验收标准（可执行命令）
  - 参考文件（references）

### 3. 生成规范文档

同时生成两种格式：

#### YAML 格式 (.claude/specs/{project}.yaml)
```yaml
meta:
  name: "{项目名称}"
  version: "1.0"
  repo: "{仓库路径}"
  branch: "{分支名}"
  design_doc: "{设计文档路径}"
  created_at: "{创建时间}"

sprints:
  - id: sprint-1
    name: "{Sprint名称}"

    # 按 commit 分组的任务
    commits:
      - id: commit-1
        message: "feat: {功能描述}"  # Git commit 消息
        tasks: [task-1.1, task-1.2]   # 包含的任务ID列表
      - id: commit-2
        message: "feat: {另一个功能}"
        tasks: [task-1.3, task-1.4]

    # 任务详情定义
    tasks:
      - id: task-1.1
        name: "{任务名称}"
        status: pending
        files:
          create:
            - "{新建文件路径}"
          modify:
            - "{修改文件路径}"
        implementation:
          - "{实现要点1}"
          - "{实现要点2}"
        tdd:
          test_file: "{测试文件路径}"
          test_cases:
            - name: "{测试函数名}"
              description: "{测试描述}"
        acceptance:
          - cmd: "{验收命令}"
            expect: "{预期结果}"
        references:
          - path: "{参考文件路径}"
            note: "{参考说明}"
```

#### Markdown 格式 (.claude/specs/{project}.md)
```markdown
# {项目名称} - 任务规范

## Meta
- **项目名称**: {名称}
- **版本**: 1.0
- **仓库**: {路径}
- **分支**: {分支}
- **设计文档**: {路径}

---

## Sprint 1: {名称}

### Commit 分组

| Commit ID | 消息 | 包含任务 | 状态 |
|-----------|------|---------|------|
| commit-1 | feat: {功能描述} | task-1.1, task-1.2 | pending |
| commit-2 | feat: {另一个功能} | task-1.3 | pending |

---

### Task 1.1: {任务名称}
**状态**: pending
**所属 Commit**: commit-1

**创建文件**:
- `{文件路径}`

**修改文件**:
- `{文件路径}`

**实现内容**:
1. {要点1}
2. {要点2}

**TDD要求**:
- 测试文件: `{测试文件路径}`
- 测试用例:
  - `{测试函数名}` - {描述}

**验收标准**:
\`\`\`bash
{命令}  # {预期}
\`\`\`

**参考文件**:
- `{路径}` - {说明}
```

### 4. 验证规范完整性
- 每个Task必须有唯一ID（格式：task-{sprint}.{seq}）
- 每个Task必须有至少一个验收标准
- 文件路径必须是相对于仓库根目录的路径
- 测试用例名称必须符合 Go 测试命名规范

### 5. 输出结果
- 打印生成的文件路径
- 显示规范摘要（Sprint数、Commit数、Task数）
- 显示 Commit 分组概览表
- 提示用户可以使用 `/spec-driven {spec} commit-X` 按 commit 执行任务

设计文档路径：$ARGUMENTS
