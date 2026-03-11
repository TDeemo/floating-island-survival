# Godot 玩家角色系统设计文档

## 概述
在Godot 4.5.1中实现漂浮大陆游戏的玩家角色控制器、相机跟随系统和基础动画状态机。系统支持WASD/方向键输入、加速度物理效果、平滑相机跟随以及空闲/行走/奔跑动画状态管理。

## 系统架构

### 核心组件

1. **PlayerController** (`res://scripts/player/PlayerController.gd`)
   - 主控制器类，继承自CharacterBody2D
   - 处理输入、移动物理、碰撞检测
   - 提供速度、加速度、减速度等可调参数

2. **CameraFollow** (`res://scripts/player/CameraFollow.gd`)
   - 相机跟随脚本，继承自Camera2D
   - 实现平滑跟随玩家，支持边界约束
   - 可配置跟随延迟、边缘缓冲和地图边界

3. **AnimationManager** (`res://scripts/player/AnimationManager.gd`)
   - 动画状态管理器，继承自Node
   - 管理空闲、行走、奔跑等基础动画状态
   - 支持八个方向的精灵方向切换

4. **Player预制场景** (`res://scenes/player/player.tscn`)
   - 完整玩家角色预制体
   - 包含CharacterBody2D、Sprite2D、CollisionShape2D、Camera2D和AnimationManager节点

### 数据流

1. **输入处理阶段**
   - Godot Input系统捕获WASD/方向键输入
   - PlayerController计算归一化输入向量
   - 应用加速度/减速度物理模型

2. **物理移动阶段**
   - 更新当前速度向量
   - 执行`move_and_slide()`处理碰撞
   - 限制最大速度防止无限加速

3. **相机跟随阶段**
   - CameraFollow计算目标位置
   - 应用边界约束（如果启用）
   - 使用平滑阻尼更新相机位置

4. **动画更新阶段**
   - AnimationManager根据速度和输入确定动画状态
   - 更新精灵方向和动画播放
   - 提供状态查询接口

## 组件详细设计

### PlayerController

#### 核心功能
- **输入映射**：使用Godot默认的`ui_left`、`ui_right`、`ui_up`、`ui_down`动作，同时支持方向键和WASD
- **物理模型**：
  - 加速：`current_velocity.move_toward(target_velocity, acceleration * delta)`
  - 减速：`current_velocity.move_toward(Vector2.ZERO, deceleration * delta)`
  - 限速：`current_velocity.length() > max_speed`
- **碰撞处理**：通过`move_and_slide()`自动处理TileMap和物理体碰撞

#### 导出参数
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `speed` | `float` | 300.0 | 基础移动速度（像素/秒） |
| `acceleration` | `float` | 1500.0 | 加速度（像素/秒²） |
| `deceleration` | `float` | 1800.0 | 减速度（像素/秒²） |
| `max_speed` | `float` | 500.0 | 最大速度限制（像素/秒） |

#### 公共接口
```gdscript
## 获取当前移动输入方向
func get_move_direction() -> Vector2

## 获取当前速度向量
func get_current_velocity() -> Vector2

## 获取是否正在移动
func is_player_moving() -> bool

## 设置动画管理器引用
func set_animation_manager(manager: AnimationManager)
```

### CameraFollow

#### 核心功能
- **平滑跟随**：使用`smooth_damp`算法实现平滑相机移动
- **边界约束**：
  - 计算基于视口大小和缩放的实际相机边界
  - 钳制相机位置确保不超出地图范围
- **边缘缓冲**：保持相机距离地图边界至少指定像素距离

#### 导出参数
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `target` | `Node2D` | `null` | 跟随的目标节点 |
| `follow_smoothness` | `float` | 0.2 | 跟随延迟（秒），值越大越平滑 |
| `enable_bounds` | `bool` | `true` | 是否启用边界约束 |
| `map_bound_min` | `Vector2` | `Vector2.ZERO` | 地图最小边界坐标 |
| `map_bound_max` | `Vector2` | `Vector2(1024, 1024)` | 地图最大边界坐标 |
| `edge_buffer` | `float` | 50.0 | 边缘缓冲距离（像素） |

#### 公共接口
```gdscript
## 设置地图边界
func set_map_bounds(min_pos: Vector2, max_pos: Vector2)

## 启用/禁用边界约束
func set_bounds_enabled(enabled: bool)

## 设置跟随目标
func set_target(new_target: Node2D)

## 立即跳转到目标位置（无平滑）
func snap_to_target()
```

### AnimationManager

#### 核心功能
- **状态管理**：
  - `IDLE`：速度 < `idle_threshold`
  - `WALK`：速度 < `walk_threshold`
  - `RUN`：速度 < `run_threshold`
- **方向检测**：将输入向量映射到八个方向（上、下、左、右、四个对角线）
- **动画播放**：生成状态+方向的组合动画名称（如`walk_up_left`）

#### 导出参数
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `sprite` | `Sprite2D` | `null` | 精灵节点引用 |
| `animation_player` | `AnimationPlayer` | `null` | 动画播放器引用 |
| `idle_threshold` | `float` | 10.0 | 空闲状态速度阈值 |
| `walk_threshold` | `float` | 150.0 | 行走状态速度阈值 |
| `run_threshold` | `float` | 350.0 | 奔跑状态速度阈值 |

#### 公共接口
```gdscript
## 更新动画状态
func update_animation(input_vector: Vector2, is_moving: bool, velocity: Vector2)

## 设置精灵水平翻转
func set_sprite_flip_h(flip: bool)

## 设置精灵垂直翻转
func set_sprite_flip_v(flip: bool)

## 获取当前动画状态
func get_current_state() -> AnimationManager.AnimationState

## 获取当前移动方向
func get_current_direction() -> AnimationManager.MoveDirection
```

## 使用示例

### 基础玩家创建
```gdscript
# 在场景中实例化玩家预制体
var player_scene = load("res://scenes/player/player.tscn")
var player_instance = player_scene.instantiate()
player_instance.position = Vector2(320, 240)
add_child(player_instance)
```

### 相机配置
```gdscript
# 获取玩家相机组件并配置
var camera_follow = player_instance.get_node("CameraFollow")
camera_follow.set_map_bounds(Vector2(0, 0), Vector2(2048, 2048))
camera_follow.set_bounds_enabled(true)
```

### 动画系统集成
```gdscript
# 手动连接动画管理器（如果未通过@export自动连接）
var animation_manager = player_instance.get_node("AnimationManager")
animation_manager.sprite = player_instance.get_node("Sprite2D")
animation_manager.animation_player = player_instance.get_node("AnimationPlayer")
```

## 测试场景

### 测试场景结构
`res://scenes/test_player/test_player.tscn` 包含：
1. **TileMap节点**：使用岛屿TileSet创建简单测试地形
2. **PlayerInstance节点**：玩家预制体实例
3. **UI控制**：显示操作提示标签
4. **测试脚本**：`TestPlayerScript`验证所有核心功能

### 测试功能验证
测试脚本自动验证以下功能：
1. **移动输入响应**：检查输入系统是否正常工作
2. **加速度/减速度物理**：验证物理参数配置
3. **碰撞检测**：检查碰撞形状是否正确配置
4. **相机跟随**：验证相机目标设置
5. **动画状态机**：确认动画管理器功能正常

### 运行测试
```gdscript
# 在编辑器中运行测试场景
# 控制台将输出详细测试结果和通过率
```

## 性能优化

### 移动物理优化
- **向量运算优化**：使用Godot内置的向量函数提高计算效率
- **条件分支简化**：减少每帧不必要的状态检查
- **输入采样优化**：合并输入采样减少系统调用

### 相机系统优化
- **边界计算缓存**：视口大小不变时复用边界计算结果
- **平滑算法优化**：使用帧率自适应的平滑参数

### 动画系统优化
- **状态变化检测**：仅在实际状态变化时更新动画
- **方向计算优化**：使用整数角度范围减少浮点运算

## 与Unity版本对比

| 特性 | Unity版本 | Godot版本 |
|------|-----------|-----------|
| **控制器类型** | CharacterController (3D) | CharacterBody2D (2D) |
| **输入系统** | Input.GetAxis + 自定义映射 | Godot Input映射 (ui_*动作) |
| **相机跟随** | Cinemachine 2D | 自定义CameraFollow脚本 |
| **动画系统** | Animator + 状态机 | AnimationPlayer + AnimationManager |
| **物理模型** | 刚体物理 + 力施加 | 运动学物理 + 加速度模型 |

## 后续扩展计划

### 短期扩展（原型阶段）
1. **攻击动画集成**：扩展AnimationManager支持攻击状态
2. **采集动画**：添加工具使用时的特殊动画
3. **受伤反馈**：受击闪烁和击退效果

### 中期扩展（Alpha阶段）
1. **装备系统集成**：根据装备武器动态切换动画
2. **角色切换支持**：多个可玩角色的动画系统适配
3. **移动平台适配**：虚拟摇杆输入与动画响应

### 长期扩展（Beta阶段）
1. **复杂状态机**：支持组合状态（行走+攻击等）
2. **表情系统**：角色表情和情绪动画
3. **物理动画**：基于物理的布料和头发模拟

## 文件清单

- `docs/godot_player_system.md` - 本设计文档
- `scripts/player/PlayerController.gd` - 主控制器脚本
- `scripts/player/CameraFollow.gd` - 相机跟随脚本
- `scripts/player/AnimationManager.gd` - 动画管理器脚本
- `scripts/player/test_player.gd` - 测试脚本
- `scenes/player/player.tscn` - 玩家预制场景
- `scenes/test_player/test_player.tscn` - 测试场景

---

**文档版本**: 1.0  
**最后更新**: 2026-03-09  
**关联文档**: 
- [游戏设计文档](game_design_document.md)
- [Godot迁移路线图](godot_migration_roadmap.md)
- [岛屿生成系统设计](godot_island_generator.md)