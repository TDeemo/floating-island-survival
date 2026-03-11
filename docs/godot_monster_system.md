# Godot怪物AI系统设计文档

## 1. 系统概述

怪物AI系统是《漂浮大陆》游戏的核心战斗模块，负责管理所有怪物的行为、属性和战斗逻辑。系统与岛屿生成系统、武器系统、昼夜循环系统深度集成，支持不同生态环境的怪物种类和动态难度调整。

### 1.1 核心功能
- **怪物属性管理**：生命值、攻击力、移动速度等基础属性
- **AI行为控制**：巡逻、追击、攻击、返回等状态机
- **生态环境匹配**：不同生态环境（森林、矿山、沼泽等）生成对应怪物
- **动态难度**：夜晚怪物增强、难度星级影响怪物强度
- **掉落系统**：怪物死亡掉落资源和武器
- **生命周期管理**：生成、重生、清理全流程管理

### 1.2 技术特性
- 基于Godot 4.5.1 GDScript实现
- 模块化设计，支持扩展新怪物类型和AI行为
- 与现有武器系统、岛屿生成系统兼容
- 支持headless模式测试（组件层验证）

## 2. 系统架构

### 2.1 组件关系图
```
┌─────────────────────────────────────────┐
│           MonsterManager                │
│  ┌──────────────────────────────────┐  │
│  │ 管理所有怪物生命周期            │  │
│  │ 控制生成/重生/清理              │  │
│  └──────────────────────────────────┘  │
└─────────────┬──────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│           MonsterSpawner                │
│  ┌──────────────────────────────────┐  │
│  │ 根据生态环境分布生成点          │  │
│  │ 管理生成点状态和重生计时        │  │
│  └──────────────────────────────────┘  │
└─────────────┬──────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│           MonsterBase                   │
│  ┌──────────────────────────────────┐  │
│  │ 怪物基类，定义属性和状态机      │  │
│  │ 处理移动、伤害、死亡逻辑        │  │
│  └──────────────────────────────────┘  │
│                 │                       │
│                 ▼                       │
│  ┌──────────────────────────────────┐  │
│  │      MonsterAI                   │  │
│  │  AI决策组件，实现行为树          │  │
│  │ 目标检测和状态决策              │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### 2.2 与外部系统集成
```
岛屿生成系统 → 提供生态环境类型、岛屿大小、港口位置
    ↓
MonsterSpawner → 根据生态环境设置生成点
    ↓
MonsterManager → 管理怪物生成和生命周期
    ↓
武器系统 ← 怪物掉落武器、玩家攻击怪物
    ↓
昼夜循环系统 ← 夜晚怪物增强、行为变化
```

## 3. 类设计

### 3.1 MonsterBase（怪物基类）

#### 核心属性
```gdscript
class_name MonsterBase
extends CharacterBody2D

enum MonsterType { MELEE, RANGED, MAGIC, FLYING, BOSS }
enum MonsterState { IDLE, PATROL, CHASE, ATTACK, DEAD, RETURNING }

@export var monster_type: MonsterType = MonsterType.MELEE
@export var base_health: float = 50.0
@export var current_health: float = 50.0
@export var base_attack: float = 10.0
@export var move_speed: float = 100.0
@export var attack_range: float = 50.0
@export var chase_range: float = 300.0
@export var sight_range: float = 200.0
@export var monster_name: String = "未命名怪物"
@export var enhanced_at_night: bool = true
@export var night_enhancement_multiplier: float = 1.5
@export var drop_resource_type: String = ""
@export var drop_amount_min: int = 1
@export var drop_amount_max: int = 3
@export var drop_weapon_chance: float = 0.1
@export var drop_weapon_type: int = 0
```

#### 核心方法
- `take_damage(damage: float, source: Node)`：处理受到伤害
- `_die()`：死亡处理逻辑
- `_drop_items()`：触发掉落
- `set_target(new_target: Node2D)`：设置攻击目标
- `set_patrol_points(points: Array[Vector2])`：设置巡逻路径
- `apply_night_enhancement()` / `remove_night_enhancement()`：夜晚增强控制

#### 信号
- `monster_attacked(monster: MonsterBase)`
- `monster_died(monster: MonsterBase)`
- `resource_dropped(resource_type: String, amount: int, position: Vector2)`
- `weapon_dropped(weapon_type: int, position: Vector2)`

### 3.2 MonsterAI（AI组件）

#### 行为类型
```gdscript
enum AIBehavior {
    SIMPLE_PATROL,     # 简单巡逻
    AGGRESSIVE_CHASE,  # 主动追击
    DEFENSIVE_GUARD,   # 防御性守卫
    AMBUSH,            # 伏击
    BOSS               # BOSS特殊行为
}
```

#### 核心功能
- 目标检测与选择
- AI行为决策（根据行为类型）
- 视线检测与距离计算
- BOSS多阶段行为控制

### 3.3 MonsterManager（怪物管理器）

#### 主要职责
1. **生成配置管理**：加载和配置各生态环境的怪物生成参数
2. **生命周期控制**：控制怪物的生成、重生和清理
3. **数量控制**：限制同时存在的怪物数量
4. **难度适配**：根据游戏难度调整怪物数量和强度

#### 配置类
```gdscript
class MonsterSpawnConfig:
    var monster_scene: PackedScene
    var biome_type: int  # BiomeManager.BiomeType
    var spawn_weight: float = 1.0
    var min_difficulty: int = 1
    var max_difficulty: int = 5
    var max_count_per_island: int = 5
    var spawn_radius: float = 100.0
```

### 3.4 MonsterSpawner（怪物生成器）

#### 核心算法
1. **生成点分布**：根据岛屿大小和生态环境类型计算生成点位置
2. **距离验证**：确保生成点离港口和玩家有足够距离
3. **地形适配**：检查生成点位置是否适合怪物活动
4. **动态生成**：根据玩家位置动态激活/生成怪物

## 4. 生态环境匹配

### 4.1 生态环境与怪物类型对应表
| 生态环境 | 近战怪物 | 远程怪物 | 魔法怪物 | 飞行怪物 | BOSS |
|---------|---------|---------|---------|---------|------|
| 森林 | 骷髅战士 | 森林弓箭手 | 树精法师 | 巨鹰 | 远古树人 |
| 矿山 | 岩石傀儡 | 洞穴射手 | 熔岩法师 | 洞穴蝙蝠 | 岩石巨人 |
| 沼泽 | 沼泽僵尸 | 毒箭蛙 | 沼泽巫婆 | 沼泽飞虫 | 巨型鳄鱼 |
| 雪原 | 雪人 | 冰霜射手 | 冰元素 | 雪鹰 | 雪怪王 |
| 火山 | 熔岩魔 | 火山射手 | 火焰幽灵 | 火山蝙蝠 | 火山巨龙 |
| 丛林 | 丛林野人 | 吹箭手 | 丛林萨满 | 巨嘴鸟 | 丛林巨蟒 |

### 4.2 属性调整规则
- **难度星级**：每星级增加怪物生命值20%、攻击力15%
- **夜晚增强**：攻击力×1.5、移动速度×1.3、追逐范围×2.0
- **生态环境加成**：
  - 森林：移动速度+10%
  - 矿山：防御力+20%
  - 沼泽：中毒伤害+30%
  - 雪原：冰冻效果时间+50%
  - 火山：燃烧伤害+40%
  - 丛林：攻击速度+15%

## 5. 集成指南

### 5.1 初始化步骤
1. **场景设置**：在主场景中添加MonsterManager和MonsterSpawner节点
2. **配置加载**：调用`MonsterManager.setup_spawn_configs()`加载生成配置
3. **岛屿参数设置**：在岛屿生成后调用`MonsterSpawner.setup_island()`
4. **怪物生成**：调用`MonsterSpawner.spawn_all_initial_monsters()`

### 5.2 代码示例
```gdscript
# 在主游戏脚本中
func setup_monster_system():
    # 获取管理器
    var monster_manager = $MonsterManager
    var monster_spawner = $MonsterSpawner
    
    # 设置生成配置
    monster_manager.setup_spawn_configs()
    
    # 设置岛屿参数（从岛屿生成系统获取）
    var biome_type = BiomeManager.BiomeType.FOREST
    var difficulty = 3
    var island_size = Vector2(512, 512)
    var harbor_position = Vector2(256, 50)
    
    monster_spawner.setup_island(biome_type, difficulty, island_size, harbor_position)
    
    # 生成初始怪物
    monster_spawner.spawn_all_initial_monsters()
```

### 5.3 与武器系统集成
```gdscript
# 在攻击系统中处理怪物伤害
func _on_attack_hit_monster(monster: MonsterBase, weapon: WeaponBase):
    var damage = weapon.base_damage
    monster.take_damage(damage, player)
    
    # 触发怪物反击（如果怪物存活）
    if monster.current_state != MonsterBase.MonsterState.DEAD:
        monster.set_target(player)
```

### 5.4 与昼夜循环系统集成
```gdscript
# 在时间管理器中
func _on_night_start():
    for monster in monster_manager.active_monsters:
        if monster.enhanced_at_night:
            monster.apply_night_enhancement()

func _on_day_start():
    for monster in monster_manager.active_monsters:
        if monster.enhanced_at_night:
            monster.remove_night_enhancement()
```

## 6. 测试方法

### 6.1 单元测试（组件层）
- **MonsterBase测试**：验证属性设置、伤害计算、状态切换
- **MonsterAI测试**：验证目标检测、行为决策、视线计算
- **MonsterManager测试**：验证生成配置、生命周期管理
- **MonsterSpawner测试**：验证生成点分布、动态生成

### 6.2 集成测试
1. **与岛屿生成系统集成**：验证不同生态环境的怪物生成
2. **与武器系统集成**：验证战斗交互和伤害计算
3. **与昼夜循环系统集成**：验证夜晚怪物增强效果
4. **与资源收集系统集成**：验证怪物掉落收集

### 6.3 性能测试
- **压力测试**：同时存在大量怪物时的性能表现
- **内存测试**：怪物生成和清理的内存管理
- **网络同步测试**：多人游戏时的怪物状态同步

### 6.4 测试脚本
提供了`test_monster_ai.gd`脚本，支持以下测试功能：
- 怪物生成和基本属性验证
- AI行为观察（巡逻、追击、攻击）
- 伤害计算和死亡处理测试
- 掉落系统验证

#### 使用方法
1. 将测试脚本附加到测试场景节点
2. 配置测试怪物场景数组
3. 设置玩家节点引用
4. 运行游戏，使用功能键控制测试：
   - **F1**：开始测试
   - **F2**：对第一个怪物造成伤害
   - **F3**：切换怪物目标
   - **F4**：清理所有测试怪物

## 7. 预制体模板

### 7.1 近战怪物模板（skeleton_melee.tscn）
- **基础属性**：生命60、攻击15、速度80、攻击范围40
- **AI行为**：简单巡逻
- **掉落配置**：骨资源（2-4个）、15%概率掉落近战武器
- **夜晚增强**：1.6倍增强

### 7.2 远程怪物模板（archer_ranged.tscn）
- **基础属性**：生命40、攻击12、速度100、攻击范围120
- **AI行为**：主动追击
- **掉落配置**：箭资源（3-6个）、20%概率掉落远程武器
- **夜晚增强**：1.4倍增强

### 7.3 创建新怪物预制体步骤
1. 复制现有模板场景文件
2. 修改导出属性（生命值、攻击力等）
3. 调整AI行为配置
4. 设置掉落类型和概率
5. 关联自定义精灵和动画

## 8. 已知问题与限制

### 8.1 技术限制
- **headless模式验证**：Godot headless模式在容器环境中可能存在运行时问题
- **性能考虑**：大量怪物同时进行复杂AI计算可能影响性能
- **内存管理**：怪物频繁生成和清理需要注意内存泄漏

### 8.2 设计限制
- **行为树复杂度**：当前实现为简化状态机，复杂行为需要扩展
- **生态环境匹配**：需要手动配置每种生态环境的怪物类型
- **难度平衡**：数值平衡需要实际游戏测试调整

### 8.3 解决方案
- **渐进式验证**：采用"产出优先、验证延后"策略
- **性能优化**：实现怪物LOD系统，远距离怪物使用简化AI
- **配置数据驱动**：将生态环境匹配配置外部化，支持热更新

## 9. 扩展计划

### 9.1 短期扩展（原型阶段）
1. **更多怪物类型**：添加魔法、飞行、BOSS类型怪物
2. **行为树系统**：实现更复杂的AI决策树
3. **技能系统**：怪物特殊技能和攻击模式

### 9.2 中期扩展（Alpha阶段）
1. **群体AI**：怪物群体行为和协作攻击
2. **自适应难度**：根据玩家表现动态调整怪物强度
3. **生态环境互动**：怪物与环境的交互行为

### 9.3 长期扩展（Beta阶段）
1. **高级AI**：机器学习驱动的智能行为
2. **动态生态链**：怪物之间的捕食和竞争关系
3. **叙事AI**：与游戏剧情联动的怪物行为

## 10. 附录

### 10.1 文件结构
```
godot_project/
├── scripts/monster_system/
│   ├── MonsterBase.gd      # 怪物基类
│   ├── MonsterAI.gd        # AI组件
│   ├── MonsterManager.gd   # 怪物管理器
│   └── MonsterSpawner.gd   # 怪物生成器
├── scenes/monsters/
│   ├── skeleton_melee.tscn    # 近战骷髅
│   ├── archer_ranged.tscn     # 远程弓箭手
│   └── [更多怪物预制体...]
└── scripts/test/
    └── test_monster_ai.gd     # 测试脚本
```

### 10.2 依赖关系
- **Godot 4.5.1**：引擎基础
- **BiomeManager**：生态环境类型定义
- **WeaponSystem**：伤害计算和武器掉落
- **TimeManager**：昼夜循环状态

### 10.3 版本历史
| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0 | 2026-03-10 | 初始版本，包含基本怪物AI系统 |

---

**文档维护**：游戏开发团队  
**最后更新**：2026-03-10  
**相关文档**：  
- [游戏设计文档](game_design_document.md)  
- [Godot迁移路线图](godot_migration_roadmap.md)  
- [武器系统设计](未创建)  
- [岛屿生成系统设计](godot_island_generator.md)