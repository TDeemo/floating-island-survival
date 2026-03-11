# Godot动态昼夜循环系统设计文档

## 1. 系统概述
动态昼夜循环系统是《漂浮大陆》游戏的核心紧张感机制之一。系统模拟游戏内时间的流逝，控制昼夜阶段切换（黎明、白天、黄昏、夜晚），并联动环境光变化、怪物能力强化和港口撤离倒计时，为玩家创造时间压迫感。

### 1.1 核心需求
- **时间流逝**：游戏时间按设定速度前进（默认：现实1秒 = 游戏1分钟）
- **昼夜阶段**：四个阶段（黎明04:00-06:00，白天06:00-18:00，黄昏18:00-20:00，夜晚20:00-04:00）
- **环境光渐变**：随阶段变化调整全局色调和亮度
- **怪物夜晚强化**：夜晚阶段怪物属性提升（攻击力+50%，追逐范围+100%等）
- **港口撤离计时**：黄昏开始显示撤离倒计时，夜晚必须抵达港口撤离

### 1.2 设计原则
- **模块化**：各功能独立，通过信号和接口通信
- **可配置**：关键参数通过导出变量在编辑器中调整
- **性能优化**：避免每帧遍历所有怪物，使用注册机制
- **兼容性**：与现有岛屿生成、角色控制、武器系统无缝集成

## 2. 系统架构

### 2.1 组件关系图
```
+-------------------+      +----------------------+      +---------------------------+
|   TimeManager     |◄----►|   DayNightCycle     |◄----►|   CanvasModulate         |
|  (全局时间管理)   |      |  (环境光控制器)     |      |  (全局色调调整)          |
+-------------------+      +----------------------+      +---------------------------+
          │                           │                           │
          ▼                           ▼                           ▼
+-------------------+      +----------------------+      +---------------------------+
|  MonsterNightBoost|      |  PortEvacuationTimer |      |  游戏场景中的所有怪物     |
|  System           |◄----►|  (撤离计时器UI)      |◄----►|  (通过组注册机制)         |
|  (怪物强化系统)   |      |                       |      |                           |
+-------------------+      +----------------------+      +---------------------------+
```

### 2.2 数据流向
1. **时间更新**：`TimeManager._process()` → 更新时间 → 发射`time_updated`信号
2. **阶段检测**：`TimeManager._update_phase()` → 检测阶段变化 → 发射`day_phase_changed`信号
3. **环境光响应**：`DayNightCycle._on_day_phase_changed()` → 更新目标颜色 → 平滑过渡到`CanvasModulate`
4. **怪物强化响应**：`MonsterNightBoostSystem._on_day_phase_changed()` → 更新强化状态 → 应用到注册的所有怪物
5. **撤离计时响应**：`PortEvacuationTimer._on_time_updated()` → 计算剩余时间 → 更新UI显示

## 3. 类设计说明

### 3.1 TimeManager (`TimeManager.gd`)
全局时间管理器，负责游戏时间的核心逻辑。

#### 主要功能
- 管理游戏时间流逝（现实时间到游戏时间的比例缩放）
- 判断当前昼夜阶段并发出阶段变化信号
- 提供时间设置和查询接口
- 支持时间暂停/恢复

#### 关键属性
- `time_scale`：时间流逝速度（现实1秒 = 游戏内多少秒）
- `time_enabled`：是否启用时间流逝
- `start_hour`/`start_minute`：游戏起始时间

#### 信号列表
- `time_updated(hour, minute, second)`：游戏时间更新
- `day_phase_changed(new_phase, previous_phase)`：昼夜阶段变化
- `dawn_started`/`day_started`/`dusk_started`/`night_started`：特定阶段开始
- `hour_changed(hour)`：整点事件

#### 使用方法
```gdscript
# 获取TimeManager实例（假设已注册为单例或通过组查找）
var time_manager = get_node("/root/TimeManager")

# 监听时间更新
time_manager.time_updated.connect(func(hour, minute, second):
    print("当前时间: %02d:%02d:%02d" % [hour, minute, second])
)

# 手动设置时间
time_manager.set_game_time(18, 30, 0)  # 18:30:00

# 获取当前阶段
var phase = time_manager.get_current_phase()
print("当前阶段: %s" % time_manager.get_phase_name(phase))
```

### 3.2 DayNightCycle (`DayNightCycle.gd`)
环境光控制器，管理昼夜视觉效果。

#### 主要功能
- 根据昼夜阶段调整`CanvasModulate`的颜色和亮度
- 支持平滑过渡和立即切换两种模式
- 可配置各阶段的颜色和亮度参数

#### 关键属性
- `canvas_modulate_path`：关联的`CanvasModulate`节点路径
- `dawn_color`/`day_color`/`dusk_color`/`night_color`：各阶段颜色
- `dawn_brightness`/`day_brightness`/`dusk_brightness`/`night_brightness`：各阶段亮度系数
- `smooth_transition`：是否启用平滑过渡
- `transition_duration`：渐变持续时间（秒）

#### 依赖关系
- 需要场景中存在`CanvasModulate`节点（可自动创建）
- 依赖`TimeManager`提供阶段变化信号

#### 使用方法
```gdscript
# 在场景中配置DayNightCycle节点
# 1. 创建DayNightCycle节点
# 2. 设置canvas_modulate_path指向CanvasModulate节点
# 3. 调整各阶段颜色和亮度参数

# 手动切换颜色（用于调试或特殊事件）
day_night_cycle.set_color(Color(0.5, 0.5, 1.0), 0.7, true)
```

### 3.3 MonsterNightBoostSystem (`MonsterNightBoostSystem.gd`)
怪物夜晚强化系统，动态调整怪物属性。

#### 主要功能
- 监听昼夜阶段变化，在夜晚激活怪物强化
- 支持渐进式强化（黄昏开始部分强化）
- 通过注册机制管理场景中的怪物，避免性能开销
- 缓存怪物原始属性，便于恢复

#### 关键属性
- `monster_group_name`：怪物组名（用于自动注册）
- `night_attack_multiplier`：夜晚攻击力倍率（默认1.5）
- `night_speed_multiplier`：夜晚移动速度倍率（默认1.2）
- `night_chase_range_multiplier`：夜晚追逐范围倍率（默认2.0）
- `night_sight_range_multiplier`：夜晚视野范围倍率（默认1.5）
- `progressive_enhancement`：是否启用渐进强化
- `dusk_enhancement_ratio`：黄昏阶段强化比例（默认0.5）

#### 怪物集成要求
怪物脚本（如`MonsterBase.gd`）需要在`_ready()`中调用注册方法：
```gdscript
func _ready() -> void:
    # ... 其他初始化 ...
    
    # 注册到夜晚强化系统
    var boost_system = get_node("/root/MonsterNightBoostSystem")
    if boost_system:
        boost_system.register_monster(
            self, 
            base_attack, 
            move_speed, 
            chase_range, 
            sight_range
        )
```

#### 使用方法
```gdscript
# 手动启用/禁用强化系统
monster_boost_system.set_enabled(false)

# 检查当前强化状态
if monster_boost_system.is_night_boost_active():
    print("怪物处于夜晚强化状态，倍率: %.2f" % monster_boost_system.get_current_boost_multiplier())
```

### 3.4 PortEvacuationTimer (`PortEvacuationTimer.gd`)
港口撤离计时器UI，提供时间紧迫感视觉反馈。

#### 主要功能
- 计算并显示距离夜晚开始的剩余时间
- 区分安全、警告、紧急三个阶段并对应不同颜色
- 提供港口区域检测和撤离触发接口
- 发射撤离成功/失败信号

#### 关键属性
- `warning_start_hour`：撤离警告开始时间（默认18:00）
- `evacuation_deadline_hour`：强制撤离截止时间（默认20:00）
- `warning_color`/`emergency_color`/`safe_color`：各阶段文本颜色
- `time_label_path`/`status_label_path`：UI标签节点路径

#### 港口区域设置
需要设置一个`Area2D`节点作为港口区域，用于检测玩家进入：
```gdscript
# 获取港口区域节点
var port_area = $PortArea  # Area2D节点
port_evacuation_timer.set_port_area(port_area)
```

#### 撤离触发
玩家在港口区域内时，可通过交互触发撤离：
```gdscript
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        port_evacuation_timer.trigger_evacuation()
```

#### 信号列表
- `evacuation_warning_started(seconds_until_night)`：撤离警告开始
- `emergency_evacuation_started`：紧急撤离阶段开始
- `evacuation_success`：撤离成功
- `evacuation_failed`：撤离失败
- `evacuation_countdown_updated(seconds_remaining)`：倒计时更新

## 4. 集成指南

### 4.1 场景设置步骤
1. **创建系统节点**：在根场景中添加四个系统节点（或通过自动加载）
2. **配置CanvasModulate**：确保场景中有`CanvasModulate`节点，或由`DayNightCycle`自动创建
3. **设置UI**：创建`PortEvacuationTimer`所需的UI标签节点
4. **配置港口区域**：在岛屿场景中添加`Area2D`作为港口区域，并连接到计时器
5. **怪物注册**：确保怪物脚本在`_ready()`中注册到强化系统

### 4.2 自动加载配置（推荐）
在`project.godot`中配置自动加载单例：
```ini
[autoload]

TimeManager="*res://scripts/day_night_system/TimeManager.gd"
DayNightCycle="*res://scripts/day_night_system/DayNightCycle.gd"
MonsterNightBoostSystem="*res://scripts/day_night_system/MonsterNightBoostSystem.gd"
PortEvacuationTimer="*res://scripts/day_night_system/PortEvacuationTimer.gd"
```

### 4.3 与现有系统兼容性
- **岛屿生成系统**：提供测试环境，不影响地形生成逻辑
- **角色控制系统**：玩家移动不受影响，但需响应港口区域交互
- **武器与战斗系统**：怪物属性变化自动反映在战斗计算中
- **资源收集系统**：时间限制增加采集策略维度

## 5. 测试验证方法

### 5.1 单元测试脚本
已创建测试脚本`test_day_night.gd`（位于`godot_project/scripts/test/`目录），验证以下功能：
- 时间流逝速度准确性
- 昼夜阶段切换正确性
- 环境光颜色渐变
- 怪物属性强化逻辑
- 撤离倒计时计算

### 5.2 测试场景
已创建测试场景`test_day_night.tscn`（位于`godot_project/scenes/test/`目录），包含：
- 完整的昼夜循环系统节点
- 测试用玩家和怪物
- 港口区域检测
- UI显示控件

### 5.3 验证步骤
1. **加载测试场景**：运行`test_day_night.tscn`
2. **观察时间流逝**：检查HUD时间显示是否按预期前进
3. **验证阶段切换**：加速时间流逝，观察黎明→白天→黄昏→夜晚的切换
4. **检查环境光**：确认`CanvasModulate`颜色随阶段平滑变化
5. **测试怪物强化**：切换到夜晚阶段，验证怪物属性提升
6. **测试撤离计时**：黄昏开始观察倒计时显示和颜色变化
7. **触发撤离**：移动玩家到港口区域，交互触发撤离事件

### 5.4 预期结果
- 游戏时间以60倍现实时间速度流逝（默认）
- 四个昼夜阶段在正确时间切换
- 环境光在阶段过渡时平滑渐变
- 夜晚阶段怪物攻击力提升50%，追逐范围提升100%
- 撤离计时器正确显示剩余时间，颜色随阶段变化
- 玩家在港口区域可成功触发撤离

## 6. 性能优化

### 6.1 时间更新优化
- 使用`_process()`而非`_physics_process()`，降低更新频率需求
- 仅在时间变化时发射信号，避免不必要的回调

### 6.2 怪物强化优化
- 采用注册机制，避免每帧遍历场景树
- 缓存原始属性，减少属性计算开销
- 仅在阶段变化时批量更新，非每帧更新

### 6.3 环境光优化
- 颜色插值计算使用Godot内置`lerp()`，性能高效
- 过渡期间每帧更新，非过渡期间跳过计算

## 7. 故障排除

### 7.1 常见问题
1. **`CanvasModulate`未生效**
   - 检查节点路径配置
   - 确认`CanvasModulate`在场景树中
   - 验证`DayNightCycle.enabled`为true

2. **怪物强化未触发**
   - 确认怪物已正确注册
   - 检查`MonsterNightBoostSystem.enabled`状态
   - 验证当前游戏阶段是否为夜晚或黄昏

3. **时间不流逝**
   - 检查`TimeManager.time_enabled`状态
   - 确认`time_scale`大于0
   - 验证`_process()`未被禁用

4. **撤离计时器显示异常**
   - 检查`warning_start_hour`和`evacuation_deadline_hour`配置
   - 确认`TimeManager`正确连接
   - 验证UI标签节点路径

### 7.2 调试工具
每个系统类都包含调试方法：
- `TimeManager.debug_print_time()`：打印当前游戏时间
- `DayNightCycle.debug_print_color()`：打印当前环境光颜色
- `MonsterNightBoostSystem.debug_print_monsters()`：打印已注册怪物
- `PortEvacuationTimer.debug_print_state()`：打印撤离状态

## 8. 扩展与定制

### 8.1 自定义阶段时间
修改`TimeManager`中的常量：
```gdscript
const PHASE_DAWN_START: int = 4
const PHASE_DAWN_END: int = 6
const PHASE_DAY_START: int = 6
const PHASE_DAY_END: int = 18
const PHASE_DUSK_START: int = 18
const PHASE_DUSK_END: int = 20
const PHASE_NIGHT_START: int = 20
const PHASE_NIGHT_END: int = 4
```

### 8.2 自定义强化参数
通过导出变量调整怪物强化倍率：
```gdscript
@export var night_attack_multiplier: float = 1.5
@export var night_speed_multiplier: float = 1.2
@export var night_chase_range_multiplier: float = 2.0
@export var night_sight_range_multiplier: float = 1.5
```

### 8.3 添加特殊事件
通过监听`TimeManager`信号实现自定义事件：
```gdscript
time_manager.time_updated.connect(func(hour, minute, second):
    if hour == 12 and minute == 0:
        trigger_midday_event()
)
```

## 9. 版本历史
- **v1.0.0** (2026-03-10)：初始版本
  - 实现基础时间管理系统
  - 完成昼夜环境光渐变
  - 集成怪物夜晚强化
  - 提供港口撤离计时UI

---
**文档维护**：开发团队  
**最后更新**：2026-03-10  
**关联文件**：
- `godot_project/scripts/day_night_system/TimeManager.gd`
- `godot_project/scripts/day_night_system/DayNightCycle.gd`
- `godot_project/scripts/day_night_system/MonsterNightBoostSystem.gd`
- `godot_project/scripts/day_night_system/PortEvacuationTimer.gd`
- `godot_project/scenes/test/test_day_night.tscn`
- `godot_project/scripts/test/test_day_night.gd`