# Verilog 电梯控制器项目

## 项目概述

这是一个用 Verilog HDL 实现的多层电梯控制系统。该电梯控制器支持内部请求（电梯内部按键）和外部请求（各楼层上下按钮），采用状态机设计实现电梯的智能调度和门控逻辑。

### 主要特性

- 支持多层电梯（默认 4 层，可通过参数配置）
- 内部请求：电梯内部楼层选择按钮
- 外部请求：各楼层上/下呼叫按钮
- 智能调度算法：基于方向优先的请求处理
- 自动门控：开门、保持、关门状态管理
- 电机控制：上行/下行驱动输出
- 实时状态监控：当前楼层、运动方向、门状态等
- 兼容标准 Verilog：使用辅助函数替代 SystemVerilog 特性

### 技术栈

- **语言**: Verilog HDL（标准 Verilog-2005 兼容）
- **仿真工具**: Icarus Verilog（已测试）、ModelSim、Vivado
- **设计模式**: 有限状态机 (FSM)
- **辅助函数**: 用于兼容标准 Verilog 的动态位选择操作

## 项目结构

```
.
├── elevator_controller.v    # 电梯控制器主模块
├── elevator_tb.v            # 测试台模块
├── elevator_sim             # 编译后的仿真可执行文件（运行后生成）
└── IFLOW.md                 # 项目说明文档
```

## 文件说明

### elevator_controller.v

电梯控制器的核心实现，包含：

- **参数化设计**:
  - `NUM_FLOORS`: 楼层数量（默认 4）
  - `FLOOR_BITS`: 楼层编码位数（默认 2）

- **输入端口**:
  - `clk`: 时钟信号
  - `reset`: 复位信号
  - `internal_requests[NUM_FLOORS-1:0]`: 内部楼层请求
  - `external_up_requests[NUM_FLOORS-1:0]`: 外部上行请求
  - `external_down_requests[NUM_FLOORS-1:0]`: 外部下行请求
  - `floor_sensors[NUM_FLOORS-1:0]`: 楼层传感器输入

- **输出端口**:
  - `motor_up`: 电机上行控制
  - `motor_down`: 电机下行控制
  - `door_open`: 门打开控制
  - `door_close`: 门关闭控制
  - `current_floor[FLOOR_BITS-1:0]`: 当前楼层
  - `moving_up`: 上行状态指示
  - `moving_down`: 下行状态指示
  - `door_opening`: 门打开中状态
  - `door_closing`: 门关闭中状态

- **状态机**:
  - `IDLE`: 空闲状态
  - `MOVING_UP`: 上行状态
  - `MOVING_DOWN`: 下行状态
  - `OPENING_DOOR`: 开门状态
  - `DOOR_OPEN`: 门保持打开状态
  - `CLOSING_DOOR`: 关门状态

- **辅助函数**（用于兼容标准 Verilog）:
  - `get_requests_above`: 检查当前楼层上方的请求
  - `get_requests_below`: 检查当前楼层下方的请求

### elevator_tb.v

电梯控制器的测试台，包含以下测试场景：

1. **测试 1**: 内部请求前往 2 层
2. **测试 2**: 外部上行请求从 1 层
3. **测试 3**: 外部下行请求从 3 层
4. **测试 4**: 多个请求（1 层和 3 层）

## 构建和运行

### 编译仿真

使用 Icarus Verilog 进行仿真（推荐）：

```bash
# 编译设计文件和测试台
iverilog -o elevator_sim elevator_controller.v elevator_tb.v

# 运行仿真
vvp elevator_sim

# 查看波形（需要 GTKWave）
gtkwave elevator.vcd
```

使用 ModelSim：

```bash
# 编译
vlog elevator_controller.v elevator_tb.v

# 仿真
vsim elevator_tb

# 添加波形
add wave -r *

# 运行
run -all
```

使用 Vivado：

```bash
# 在 Vivado Tcl Console 中执行
read_verilog elevator_controller.v
read_verilog elevator_tb.v
launch_simulation
run all
```

### 修改参数

如需修改楼层数量，在实例化时修改参数：

```verilog
elevator_controller #(
    .NUM_FLOORS(8),    // 8 层电梯
    .FLOOR_BITS(3)     // 需要 3 位编码
) dut (/* 端口连接 */);
```

## 开发约定

### 代码风格

- 使用 `//` 进行单行注释
- 模块名使用小写加下划线（snake_case）
- 参数使用大写（UPPER_CASE）
- 信号使用小写加下划线（snake_case）
- 状态定义使用大写常量
- 缩进使用 4 个空格
- 函数名使用小写加下划线

### 设计原则

1. **参数化设计**: 使用参数提高代码可重用性
2. **状态机清晰**: 状态转换逻辑与输出逻辑分离
3. **时序控制**: 使用寄存器存储状态，组合逻辑处理下一状态
4. **请求锁存**: 外部请求信号需要锁存，直到电梯到达对应楼层
5. **方向优先**: 电梯优先处理当前运动方向的请求
6. **标准兼容性**: 使用辅助函数替代 SystemVerilog 特性以确保兼容性

### 兼容性说明

本项目使用标准 Verilog-2005 语法，不依赖 SystemVerilog 特性：

- **辅助函数**: `get_requests_above` 和 `get_requests_below` 函数用于替代 SystemVerilog 的动态位选择操作
- **变量声明**: 整数变量（`integer`）声明在 always 块外部，避免 SystemVerilog 语法要求
- **位选择**: 使用循环和函数实现动态位选择，而非 SystemVerilog 的 `+:` 和 `-:` 操作符

### 测试规范

- 测试台应覆盖所有主要功能场景
- 使用 `$display` 输出关键状态信息
- 使用 `#(CLK_PERIOD * N)` 控制仿真时间
- 模拟楼层传感器变化来测试电梯运动
- 每个测试场景应有清晰的注释说明
- 验证状态转换、电机控制和门控逻辑的正确性

### 扩展建议

如果需要扩展功能，可以考虑：

- 添加紧急停止功能
- 实现更复杂的调度算法（如 SCAN、LOOK 算法）
- 添加超载检测
- 实现门防夹保护
- 添加楼层显示和语音播报接口
- 支持多电梯协同调度
- 添加故障诊断和报警功能
- 实现节能模式（空闲时自动关闭某些功能）