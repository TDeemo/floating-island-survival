# 怪物系统设计文档

## 1. 概述
怪物系统是漂浮大陆游戏的核心战斗系统之一，负责管理不同生态环境下的怪物行为、AI、战斗交互和掉落系统。本系统支持多种怪物类型，包括近战、远程、精英和Boss怪物，每种怪物具有独特的属性和行为模式。

## 2. 怪物数据结构

### 2.1 怪物类型枚举
```csharp
public enum MonsterType
{
    Normal,     // 普通怪物
    Elite,      // 精英怪物
    Boss        // Boss怪物
}
```

### 2.2 怪物种类（基于生态环境）
| 生态环境 | 怪物种类 | 类型 | 描述 |
|---------|---------|------|------|
| 森林 | 地精(Goblin) | 近战 | 使用木棒攻击，移动速度中等 |
| 森林 | 飞蛾(Moth) | 远程 | 发射毒刺，飞行单位 |
| 矿山 | 石像鬼(Gargoyle) | 近战 | 高防御，低移动速度 |
| 矿山 | 蝙蝠(Bat) | 远程 | 快速移动，低生命值 |
| 沼泽 | 史莱姆(Slime) | 近战 | 分裂特性，死亡后分裂为小史莱姆 |
| 沼泽 | 毒蘑菇(Toxic Mushroom) | 远程 | 释放毒雾范围攻击 |
| 雪原 | 雪怪(Yeti) | 近战 | 高生命值，攻击带冰冻效果 |
| 雪原 | 冰晶精灵(Ice Sprite) | 远程 | 发射冰锥，减速效果 |
| 火山 | 熔岩怪(Lava Golem) | 近战 | 火焰伤害，对火系攻击免疫 |
| 火山 | 火蝙蝠(Fire Bat) | 远程 | 飞行单位，留下火焰轨迹 |
| 丛林 | 食人花(Man-eating Plant) | 近战 | 伪装成植物，突袭攻击 |
| 丛林 | 毒蛇(Venom Snake) | 远程 | 喷射毒液，中毒效果 |

### 2.3 怪物基础属性
```csharp
public class MonsterStats
{
    public int maxHealth;          // 最大生命值
    public int attackDamage;       // 攻击伤害
    public float moveSpeed;        // 移动速度
    public float attackRange;      // 攻击范围
    public float attackCooldown;   // 攻击冷却时间
    public float detectRange;      // 索敌范围
    public float patrolRange;      // 巡逻范围
    public MonsterType type;       // 怪物类型
}
```

### 2.4 掉落表结构
```csharp
public class DropTable
{
    public string tableId;                 // 掉落表ID
    public float dropChance;               // 掉落概率 (0-1)
    public DropItem[] items;               // 掉落物品列表
}

public class DropItem
{
    public string itemId;                  // 物品ID (武器ID或资源ID)
    public float weight = 1f;              // 权重
    public GameObject itemPrefab;          // 物品预制体
}
```

## 3. AI状态机设计

### 3.1 状态图
```
[空闲/巡逻] ←→ [追击] ←→ [攻击]
    ↓              ↓         ↓
[死亡] ←-------- [受伤]
```

### 3.2 状态说明
1. **巡逻状态(Patrol)**
   - 在指定范围内随机移动
   - 定时改变移动方向
   - 播放行走动画

2. **追击状态(Chase)**
   - 检测到玩家后进入此状态
   - 持续向玩家移动
   - 使用避障算法绕过障碍物

3. **攻击状态(Attack)**
   - 进入攻击范围后触发
   - 播放攻击动画
   - 动画事件触发伤害判定
   - 攻击后进入冷却

4. **受伤状态(Hurt)**
   - 受到攻击时触发
   - 短暂无敌时间
   - 播放受击动画和闪烁效果

5. **死亡状态(Death)**
   - 生命值归零时触发
   - 播放死亡动画
   - 触发掉落系统
   - 延迟销毁对象

## 4. 战斗交互系统

### 4.1 伤害流程
```
玩家攻击命中 → 怪物受击检测 → 计算伤害 → 生命值扣减 → 受伤反馈
怪物攻击命中 → 玩家受击检测 → 计算伤害 → 生命值扣减 → 受伤反馈
```

### 4.2 伤害计算
```csharp
// 基础伤害公式
实际伤害 = 攻击力 × (1 - 防御减免) × 元素抗性系数

// 暴击计算
if (Random.value < 暴击率)
    实际伤害 *= 暴击倍率
```

### 4.3 击退效果
- 受击时根据伤害来源方向施加击退力
- 击退距离 = 击退基础值 × 伤害系数
- 飞行单位受击退影响较小

## 5. 掉落系统

### 5.1 掉落概率配置
| 怪物类型 | 掉落概率 | 主要掉落物 | 稀有掉落物 |
|---------|---------|-----------|-----------|
| 普通怪物 | 10% | 木材、石材、初级武器 | 无 |
| 精英怪物 | 25% | 铁矿石、中级武器 | 特殊材料(10%) |
| Boss怪物 | 100% | 高级武器、稀有材料 | 传奇武器(5%) |

### 5.2 资源掉落表
```csharp
// 普通怪物掉落表
{
    tableId: "normal_monster",
    dropChance: 0.1,
    items: [
        { itemId: "wood", weight: 0.6, prefab: WoodPrefab },
        { itemId: "stone", weight: 0.3, prefab: StonePrefab },
        { itemId: "sword_wood", weight: 0.1, prefab: SwordWoodPrefab }
    ]
}
```

### 5.3 武器掉落集成
怪物死亡时调用 `WeaponDropSystem.Instance.DropFromNormalEnemy(position)`，与武器系统无缝集成。

## 6. 预制体结构

### 6.1 怪物预制体组件
```
MonsterPrefab (GameObject)
├── SpriteRenderer (精灵渲染器)
├── Rigidbody2D (刚体，动态类型)
├── CapsuleCollider2D (碰撞体，用于物理交互)
├── CircleCollider2D (触发器，用于索敌范围)
├── MonsterController (主控脚本)
├── MonsterHealth (生命值组件)
└── Animator (动画控制器)
```

### 6.2 预制体配置示例
```yaml
名称: Goblin_Melee
类型: 近战
精灵: Goblin_Sprite.png
属性:
  生命值: 100
  攻击力: 15
  速度: 2.5
  攻击范围: 1.2
掉落表: normal_monster
```

## 7. 测试场景要求

### 7.1 场景元素
- 玩家角色预制体
- 两种以上怪物预制体
- 障碍物和地形
- 生命值UI显示
- 调试信息面板

### 7.2 测试流程
1. 怪物生成和巡逻行为验证
2. 玩家进入索敌范围触发追击
3. 进入攻击范围触发攻击动画
4. 战斗交互伤害计算验证
5. 怪物死亡掉落物品验证
6. 多怪物同时行为测试

## 8. 扩展性设计

### 8.1 生态环境适配
- 每个生态环境有专属怪物池
- 怪物属性受环境影响（如雪原怪物有冰抗性）
- 特殊天气影响怪物行为（如雨天降低火系怪物能力）

### 8.2 难度梯度
- 随游戏进度解锁更强怪物
- 夜晚怪物能力提升（核心紧张感机制）
- 精英/Boss怪物有特殊技能

### 8.3 网络同步支持
- 怪物状态同步（位置、生命值、行为状态）
- 掉落物品网络同步
- 多人合作战斗平衡

## 9. 技术实现说明

### 9.1 现有脚本
- `Enemy.cs`: 核心AI逻辑，包含巡逻、追击、攻击状态
- `EnemyHealth.cs`: 生命值管理、伤害处理、死亡掉落
- `WeaponDropSystem.cs`: 武器掉落概率管理

### 9.2 目录结构
```
漂浮大陆/Assets/
├── Scripts/MonsterSystem/     # 所有怪物系统脚本
├── Prefabs/Monsters/          # 怪物预制体
├── Sprites/Monsters/          # 怪物精灵资源
└── Animations/Monsters/       # 怪物动画控制器
```

### 9.3 编译要求
- 所有脚本无编译错误
- 预制体引用完整
- 资源路径正确

## 10. 后续优化方向

1. **AI优化**: 实现行为树替代简单状态机
2. **性能优化**: 怪物池对象复用，LOD系统
3. **表现增强**: 更多动画效果、粒子特效、音效
4. **平衡调整**: 基于玩家反馈调整数值平衡
5. **内容扩展**: 添加更多怪物种类和特殊能力