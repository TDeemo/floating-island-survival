# Godot 光照系统设计文档

## 1. 系统概述

光照系统是漂浮大陆游戏的核心视觉与玩法组件，负责管理动态光源效果、夜间视野限制和怪物吸引机制。系统与昼夜循环、怪物AI、玩家角色和建造系统紧密集成，为游戏提供沉浸式的黑暗环境体验和生存压力。

### 1.1 核心功能
- **动态光源管理**：支持手持火把、篝火等光源的创建、更新和销毁
- **夜间视野限制**：根据光源和环境黑暗程度计算玩家可视范围
- **怪物吸引机制**：光源吸引附近怪物，增加夜间探索风险
- **多系统集成**：与昼夜循环、怪物AI、玩家控制无缝协作

### 1.2 设计原则
- **模块化设计**：每个光源类型独立可扩展
- **性能优化**：支持大量光源的高效处理
- **易集成**：提供清晰的API和信号接口
- **像素风适配**：光照效果适配游戏像素美术风格

## 2. 系统架构

### 2.1 组件关系图
```
┌─────────────────────────────────────────────────────────────┐
│                   游戏主场景 (MainScene)                    │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ LightManager│  │ TimeManager  │  │ PlayerController │   │
│  └──────┬──────┘  └──────┬───────┘  └──────────┬───────┘   │
│         │                 │                     │          │
│   注册/注销        时间阶段信号          装备/卸下火把      │
│         │                 │                     │          │
│  ┌──────▼─────────────────▼─────────────────────▼──────┐   │
│  │             光源组件 (LightSource)                  │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  ┌──────────────┐        ┌──────────────────────┐  │   │
│  │  │   TorchLight │        │    CampfireLight     │  │   │
│  │  └──────────────┘        └──────────────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │           NightVisionSystem (独立组件)               │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 数据流向
1. **光源创建** → LightManager注册 → 怪物吸引检测
2. **时间变化** → NightVisionSystem更新 → 视野范围计算
3. **玩家移动** → 光源跟随 → 怪物吸引范围更新
4. **燃料消耗** → 光照强度变化 → 视野范围调整

## 3. 核心类设计

### 3.1 LightSource (光源基类)
**文件路径**: `scripts/lighting_system/LightSource.gd`

#### 类定义
```gdscript
class_name LightSource
extends Node2D
```

#### 核心属性
| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `radius` | `float` | 200.0 | 光源半径（像素） |
| `intensity` | `float` | 1.0 | 光源强度（0.0-2.0） |
| `color` | `Color` | Color(1.0,0.9,0.7,1.0) | 光源颜色 |
| `enabled` | `bool` | true | 是否启用光源 |
| `attract_monsters` | `bool` | true | 是否吸引怪物 |

#### 关键方法
- `set_radius(new_radius: float)`: 设置光源半径
- `set_intensity(new_intensity: float)`: 设置光源强度
- `turn_on()/turn_off()/toggle()`: 光源开关控制
- `is_attracting_monsters() -> bool`: 检查是否正在吸引怪物

#### 信号
- `light_toggled(is_enabled: bool)`: 光源开关状态变化
- `monster_attraction_changed(is_attracting: bool)`: 怪物吸引状态变化

### 3.2 TorchLight (手持火把)
**文件路径**: `scripts/lighting_system/TorchLight.gd`

#### 类定义
```gdscript
class_name TorchLight
extends LightSource
```

#### 特有属性
| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `max_fuel_time` | `float` | 600.0 | 最大燃料时间（游戏内秒） |
| `current_fuel_time` | `float` | 600.0 | 当前剩余燃料时间 |
| `fuel_consumption_rate` | `float` | 1.0 | 燃料消耗速率 |
| `follow_player` | `bool` | true | 是否自动跟随玩家 |

#### 关键方法
- `equip_to_player(player: Node2D)`: 装备火把到玩家角色
- `unequip()`: 卸下火把
- `relight(fuel_amount: float)`: 重新点燃火把
- `add_fuel(fuel_amount: float)`: 添加燃料
- `get_fuel_ratio() -> float`: 获取燃料比例

### 3.3 CampfireLight (篝火)
**文件路径**: `scripts/lighting_system/CampfireLight.gd`

#### 类定义
```gdscript
class_name CampfireLight
extends LightSource
```

#### 特有属性
| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `max_fuel_time` | `float` | 3600.0 | 最大燃料时间（1小时） |
| `provide_warmth` | `bool` | true | 是否提供取暖效果 |
| `warmth_range` | `float` | 150.0 | 取暖范围（像素） |
| `build_cost_resources` | `Dictionary` | {"wood":10,"stone":5} | 建造消耗资源 |

#### 关键方法
- `start_build()`: 开始建造流程
- `add_build_resource(resource_type: String, amount: int) -> bool`: 添加建造资源
- `add_fuel(fuel_amount: float)`: 添加燃料
- `get_build_status() -> Dictionary`: 获取建造状态
- `get_warmth_info() -> Dictionary`: 获取取暖信息

### 3.4 LightManager (全局光照管理器)
**文件路径**: `scripts/lighting_system/LightManager.gd`

#### 类定义
```gdscript
class_name LightManager
extends Node
```

#### 核心职责
1. **光源注册管理**: 跟踪所有活动光源
2. **怪物吸引计算**: 定期检测光源对怪物的吸引
3. **全局状态协调**: 集成昼夜循环与视野系统

#### 关键方法
- `register_light(light: LightSource) -> int`: 注册光源并返回ID
- `unregister_light(light: LightSource)`: 注销光源
- `get_lights_near_player(position: Vector2, max_distance: float)`: 查找玩家附近光源
- `player_has_light(position: Vector2) -> bool`: 检查玩家是否有有效光源

### 3.5 NightVisionSystem (夜间视野系统)
**文件路径**: `scripts/lighting_system/NightVisionSystem.gd`

#### 类定义
```gdscript
class_name NightVisionSystem
extends Node
```

#### 核心功能
1. **视野范围计算**: 基于黑暗程度和光源影响
2. **黑暗迷雾效果**: 屏幕边缘变暗效果
3. **状态过渡管理**: 平滑的视野变化动画

#### 关键属性
| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `base_vision_range` | `float` | 100.0 | 基础夜间视野范围 |
| `max_vision_range` | `float` | 800.0 | 最大视野范围 |
| `enable_dark_fog` | `bool` | true | 是否启用黑暗迷雾 |

## 4. 预制体资源

### 4.1 火把预制体
**文件路径**: `scenes/lights/torch.tscn`

#### 节点结构
```
Torch (Node2D, 脚本: TorchLight.gd)
├── Sprite2D (纹理: Square.png, 缩放: 0.5)
├── Light2D (颜色: 暖黄, 能量: 0.9)
└── CollisionShape2D (形状: RectangleShape2D)
```

#### 参数配置
- **半径**: 250像素
- **颜色**: Color(1.0, 0.8, 0.5, 1.0)
- **燃料时间**: 600游戏秒（10分钟）

### 4.2 篝火预制体
**文件路径**: `scenes/lights/campfire.tscn`

#### 节点结构
```
Campfire (Node2D, 脚本: CampfireLight.gd)
├── Sprite2D (纹理: Square.png, 缩放: 1.0)
├── Light2D (颜色: 橙色, 能量: 1.2)
└── CollisionShape2D (形状: CircleShape2D)
```

#### 参数配置
- **半径**: 400像素
- **颜色**: Color(1.0, 0.7, 0.4, 1.0)
- **燃料时间**: 3600游戏秒（1小时）

## 5. 集成接口

### 5.1 与昼夜循环系统集成
```gdscript
# LightManager中获取时间阶段
var current_phase = _time_manager.current_phase
var is_night = current_phase == TimeManager.DayPhase.NIGHT

# NightVisionSystem响应时间变化
_time_manager.day_phase_changed.connect(_on_day_phase_changed)
```

### 5.2 与怪物AI系统集成
```gdscript
# MonsterAI响应光源吸引
if monster.has_method("set_attracted_to_light"):
    monster.set_attracted_to_light.call(light_position, attraction_strength)
```

### 5.3 与玩家角色集成
```gdscript
# PlayerController装备火把
var torch = preload("res://scenes/lights/torch.tscn").instantiate()
torch.equip_to_player(self)
```

### 5.4 与建造系统集成
```gdscript
# 建造管理器创建篝火
var campfire = preload("res://scenes/lights/campfire.tscn").instantiate()
campfire.start_build()
```

## 6. 测试指南

### 6.1 测试脚本
**文件路径**: `scripts/test/test_lighting.gd`

#### 测试用例
1. **CREATE_LIGHT_SOURCE**: 验证光源基类创建和参数设置
2. **TORCH_FUNCTIONALITY**: 测试火把燃料系统和开关功能
3. **CAMPFIRE_FUNCTIONALITY**: 验证篝火建造系统
4. **LIGHT_MANAGER_REGISTRATION**: 测试光源注册/注销流程
5. **NIGHT_VISION_SYSTEM**: 验证夜间视野计算
6. **INTEGRATION_WITH_TIME_MANAGER**: 测试与时间系统集成
7. **INTEGRATION_WITH_MONSTER_AI**: 验证怪物吸引机制

#### 运行测试
```gdscript
# 创建测试场景，添加test_lighting.gd节点
# 设置test_to_run选择测试用例
# 启动游戏查看控制台输出
```

### 6.2 手动测试流程
1. **基础功能验证**
   - 实例化火把预制体，检查光照效果
   - 装备火把到玩家，验证跟随效果
   - 创建篝火，验证建造流程

2. **集成测试**
   - 在夜间场景测试视野限制
   - 验证怪物被光源吸引的行为
   - 测试多光源叠加效果

3. **性能测试**
   - 创建大量光源，检查帧率影响
   - 长时间运行测试燃料消耗

## 7. 性能优化建议

### 7.1 光源数量控制
- **动态禁用**: 远离玩家的光源自动禁用
- **层级管理**: 按重要性分级处理
- **池化技术**: 重用光源实例减少创建开销

### 7.2 计算优化
- **空间分区**: 使用四叉树加速范围查询
- **延迟更新**: 非关键光源降低更新频率
- **近似计算**: 怪物吸引使用简化距离计算

### 7.3 内存管理
- **资源复用**: 共享纹理和材质
- **及时释放**: 销毁不再需要的光源
- **异步加载**: 大型资源异步加载

## 8. 扩展性设计

### 8.1 新光源类型
```gdscript
# 创建自定义光源示例
class_name MagicOrbLight extends LightSource
func _setup_magic_properties():
    radius = 500.0
    color = Color(0.5, 0.8, 1.0, 1.0)  # 蓝色魔法光
```

### 8.2 光照效果扩展
- **动态阴影**: 基于光源位置生成实时阴影
- **光晕效果**: 光源周围的光晕和辉光
- **颜色混合**: 多光源颜色叠加和混合

### 8.3 平台适配
- **移动端优化**: 简化效果保持性能
- **PC增强**: 支持更复杂的光照计算
- **跨平台一致性**: 确保各平台视觉效果一致

## 9. 故障排除

### 9.1 常见问题
| 问题现象 | 可能原因 | 解决方案 |
|----------|----------|----------|
| 光源不显示 | Light2D节点禁用 | 检查enabled属性 |
| 怪物不被吸引 | attract_monsters为false | 确保光源启用吸引 |
| 视野范围异常 | TimeManager未找到 | 验证场景依赖关系 |
| 性能下降 | 光源数量过多 | 实施数量控制和优化 |

### 9.2 调试工具
```gdscript
# LightManager调试信息
var light_info = _light_manager.get_light_info()
print("活动光源: %d, 总光源: %d" % [light_info.active_lights, light_info.total_lights])

# NightVisionSystem调试信息
var darkness = _night_vision.get_darkness_level()
print("黑暗程度: %.2f, 视野范围: %.0f" % [darkness, _night_vision.get_vision_range()])
```

## 10. 版本历史

### v1.0 (2026-03-10)
- 初始版本发布
- 实现5个核心GDScript组件
- 创建火把和篝火预制体
- 集成测试脚本完成
- 设计文档编写完成

---

**文档维护**: 光照系统开发团队  
**最后更新**: 2026-03-10  
**相关文档**: 
- `docs/game_design_document.md` - 游戏设计文档
- `docs/godot_day_night_system.md` - 昼夜循环系统文档
- `docs/godot_monster_system.md` - 怪物AI系统文档