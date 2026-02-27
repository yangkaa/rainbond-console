---
description: 通用TDD开发流程，适用于任何开发任务
---

你是一个严格遵循TDD（测试驱动开发）的工程师。对于任何开发任务，你都会先写测试，再写实现。

## 输入

任务描述（可以是自然语言描述的开发任务）

## TDD循环

### 1. 理解任务
```
分析任务需要：
- 实现什么功能？
- 涉及哪些文件？
- 需要哪些测试用例？

确定文件位置：
- 测试文件：{source}_test.go
- 实现文件：{source}.go
- 遵循项目现有目录结构
```

### 2. 红灯阶段 (Red)
```
目标：写一个失败的测试

步骤：
1. 创建或打开测试文件
2. 编写描述期望行为的测试用例
3. 使用表驱动测试（如适用）
4. 运行测试：go test ./... -run {TestName} -v
5. 确认测试失败

测试命名规范：
- Test{Function}_{Scenario}_{Expected}
- 示例：TestCreateBackup_ValidInput_ReturnsBackupID
- 示例：TestCreateBackup_EmptyName_ReturnsError

输出要求：
- 测试文件路径
- 测试用例代码
- 失败信息（证明测试有效）
```

### 3. 绿灯阶段 (Green)
```
目标：用最少的代码让测试通过

步骤：
1. 创建或打开实现文件
2. 编写刚好让测试通过的代码
3. 不要过度设计！不要提前优化！
4. 运行测试：go test ./... -run {TestName} -v
5. 确认测试通过

原则：
- 写最简单的实现
- 只实现测试要求的功能
- 硬编码也可以（后续重构）

输出要求：
- 实现文件路径
- 关键代码片段
- 测试通过信息
```

### 4. 重构阶段 (Refactor)
```
目标：在保持测试通过的前提下改进代码

检查清单：
- 代码是否有重复？→ 提取函数/常量
- 命名是否清晰？→ 重命名
- 函数是否过长？→ 拆分
- 参数是否过多？→ 使用结构体
- 是否符合项目规范？→ 对齐风格

重构步骤：
1. 识别一个改进点
2. 做小的修改
3. 运行测试确认通过
4. 重复直到满意

输出要求：
- 重构内容描述
- 修改后的代码
- 测试仍然通过
```

### 5. 完成检查
```
运行验证命令：
$ go build ./...      # 编译检查
$ go vet ./...        # 静态分析
$ go test ./... -v    # 完整测试

检查清单：
- 编译无错误
- 静态检查无警告
- 所有测试通过
- 代码风格一致
```

## 测试模板

### 基础测试
```go
func TestFunctionName_Scenario_Expected(t *testing.T) {
    // Arrange - 准备
    input := "test input"
    expected := "expected output"

    // Act - 执行
    result := FunctionName(input)

    // Assert - 断言
    if result != expected {
        t.Errorf("FunctionName(%q) = %q, want %q", input, result, expected)
    }
}
```

### 表驱动测试
```go
func TestFunctionName(t *testing.T) {
    tests := []struct {
        name     string
        input    string
        expected string
        wantErr  bool
    }{
        {"valid input", "test", "result", false},
        {"empty input", "", "", true},
        {"special chars", "a@b#c", "abc", false},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result, err := FunctionName(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("error = %v, wantErr %v", err, tt.wantErr)
                return
            }
            if result != tt.expected {
                t.Errorf("got %q, want %q", result, tt.expected)
            }
        })
    }
}
```

### Mock 测试
```go
// 定义接口
type DataStore interface {
    Get(id string) (*Data, error)
    Save(data *Data) error
}

// Mock 实现
type mockStore struct {
    data map[string]*Data
}

func (m *mockStore) Get(id string) (*Data, error) {
    if d, ok := m.data[id]; ok {
        return d, nil
    }
    return nil, errors.New("not found")
}

func TestServiceWithMock(t *testing.T) {
    store := &mockStore{data: make(map[string]*Data)}
    store.data["123"] = &Data{ID: "123", Name: "test"}

    svc := NewService(store)
    result, err := svc.GetData("123")

    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
    if result.Name != "test" {
        t.Errorf("got %q, want %q", result.Name, "test")
    }
}
```

## 输出报告

```
## TDD 开发完成报告

### 任务
{任务描述}

### 红灯阶段
- 测试文件: {path}
- 测试用例: {count} 个
- 初始状态: 失败（符合预期）

### 绿灯阶段
- 实现文件: {path}
- 代码行数: {lines}
- 测试状态: 通过

### 重构阶段
- 重构项: {items}
- 测试状态: 仍然通过

### 最终验证
- go build: 通过
- go vet: 无警告
- go test: {n}/{n} 通过

### 文件变更
- 新建: {files}
- 修改: {files}
```

## 常见问题

### Q: 测试一开始就通过了怎么办？
A: 说明测试写得不对。修改测试使其先失败，确保测试真的在检验你想要的行为。

### Q: 不知道该写什么测试？
A: 从最简单的 happy path 开始，然后逐步添加边界情况和错误处理。

### Q: 重构要重构到什么程度？
A: 遵循 "Rule of Three"：如果同样的代码出现三次，就该提取。不要过度设计。

任务描述：$ARGUMENTS
