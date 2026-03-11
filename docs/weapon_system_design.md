# 漂浮大陆武器系统设计文档

## 概述
本武器系统为漂浮大陆游戏的核心战斗模块，支持武器制作、怪物掉落、宝箱掉落等多种获取方式，不同武器具备独特的攻击效果。

## 依赖系统
- 资源采集系统 (PlayerResourceCollector.cs)
- 游戏管理器 (GameManager.cs)
- 预制体系系统 (Prefabs目录)
- 现有精灵资源 (temp/Assets/Assets/┼╔╧╡/)

## 数据结构

### 枚举定义
```csharp
public enum WeaponType
{
    Melee,      // 近战武器
    Ranged      // 远程武器
}

public enum WeaponEffect
{
    None,               // 无特效
    Knockback,          // 击退
    Bleeding,           // 流血（持续伤害）
    Slow,               // 减速
    AreaDamage,         // 范围伤害
    Pierce              // 穿透
}
```

### 武器数据类
```csharp
[System.Serializable]
public class WeaponData
{
    public string weaponId;                 // 武器唯一标识
    public string displayName;              // 显示名称
    public WeaponType weaponType;           // 武器类型
    public int damage;                      // 基础伤害
    public float attackSpeed;               // 攻击速度（每秒攻击次数）
    public float range;                     // 攻击范围（近战为半径，远程为射程）
    public WeaponEffect[] effects;          // 特殊效果数组
    public Sprite weaponSprite;             // 武器精灵
    public GameObject projectilePrefab;     // 远程武器投射物预制体（仅远程）
    public AudioClip attackSound;           // 攻击音效
}
```

### 武器配方类
```csharp
[System.Serializable]
public class WeaponRecipe
{
    public string weaponId;                 // 目标武器ID
    public ResourceRequirement[] requirements; // 所需资源
    
    [System.Serializable]
    public class ResourceRequirement
    {
        public ResourceType resourceType;   // 资源类型（Wood, Ore, Berry）
        public int amount;                  // 所需数量
    }
}
```

### 武器实例类（挂载在预制体上）
```csharp
public class Weapon : MonoBehaviour
{
    public WeaponData data;                 // 武器数据
    private bool isEquipped = false;
    
    public void Equip(Transform holder) { /* 装备逻辑 */ }
    public void Attack(Vector2 direction) { /* 攻击逻辑 */ }
    public void Unequip() { /* 卸载逻辑 */ }
}
```

## 武器配方表
| 武器ID | 名称 | 类型 | 伤害 | 攻速 | 范围 | 特效 | 配方 |
|--------|------|------|------|------|------|------|------|
| sword_wood | 木剑 | 近战 | 5 | 1.2 | 1.0 | 无 | 木材×3 |
| sword_iron | 铁剑 | 近战 | 10 | 1.0 | 1.2 | 流血 | 木材×2 + 矿石×5 |
| bow_wood | 木弓 | 远程 | 8 | 0.8 | 8.0 | 穿透 | 木材×5 |
| bow_iron | 铁弓 | 远程 | 12 | 0.6 | 10.0 | 击退 | 木材×3 + 矿石×8 |

## 掉落系统

### 怪物掉落配置
- 普通怪物：10%概率掉落木剑或木弓（权重1:1）
- 精英怪物：25%概率掉落铁剑或铁弓（权重1:1）
- BOSS：100%概率掉落随机武器（高级武器权重更高）

### 宝箱掉落配置
- 普通宝箱：30%概率包含武器（木剑60%，木弓40%）
- 稀有宝箱：70%概率包含武器（铁剑50%，铁弓50%）

### 实现方式
1. 扩展EnemyHealth.cs：死亡时调用掉落逻辑
2. 扩展Chest交互脚本：开箱时调用掉落逻辑
3. 掉落管理器：统一管理掉落表和概率计算

## 制作系统

### 制作台预制体
- 位置：主岛固定位置
- 交互：玩家靠近按E键打开制作界面
- 功能：显示可制作武器列表、所需资源、制作按钮

### 制作流程
1. 玩家靠近制作台，触发交互提示
2. 按E键打开制作UI
3. 选择武器，显示所需资源（高亮满足条件的配方）
4. 点击制作按钮，扣除资源，生成武器并添加到玩家背包

### 实现类
- CraftingStation.cs：制作台交互脚本
- CraftingUI.cs：制作界面UI控制
- CraftingManager.cs：制作逻辑管理器

## 攻击系统

### 近战武器攻击
- 触发攻击动画
- 在武器前方生成攻击碰撞区域
- 对碰撞到的敌人造成伤害并触发特效
- 支持连击机制

### 远程武器攻击
- 触发拉弓/射击动画
- 生成投射物（箭矢）并赋予初速度
- 投射物飞行过程中检测碰撞
- 命中敌人时造成伤害并触发特效

### 玩家武器控制器
扩展现有CharacterMovement或PlayerAttack脚本，添加：
- 武器切换功能（数字键1-4或滚轮）
- 攻击输入处理
- 武器数据绑定
- 攻击冷却计时

## 预制体清单

### 武器预制体（创建在 `漂浮大陆/Assets/Prefabs/Weapons/`）
1. **Sword_Wood.prefab**
   - SpriteRenderer（使用Warrior_Blue.png中的剑部分或单独精灵）
   - BoxCollider2D（触发器，用于拾取）
   - Weapon脚本组件
   - 武器数据配置

2. **Bow_Wood.prefab**
   - SpriteRenderer（使用Archer_Bow_Blue.png）
   - BoxCollider2D（触发器，用于拾取）
   - Weapon脚本组件
   - 武器数据配置

### 投射物预制体（复用现有Arrow.prefab）
- 位置：`temp/Assets/Assets/┼╔╧╡/Arrow.prefab`
- 脚本：ArrowProjectile.cs（已存在）

### 制作台预制体
- 位置：`漂浮大陆/Assets/Prefabs/Crafting/CraftingStation.prefab`
- 组件：SpriteRenderer、BoxCollider2D、CraftingStation脚本

## 脚本文件结构

所有武器系统脚本保存在 `漂浮大陆/Assets/Scripts/WeaponSystem/` 目录：

- `WeaponData.cs` - 武器数据结构定义
- `WeaponRecipe.cs` - 配方数据结构定义
- `Weapon.cs` - 武器组件脚本
- `WeaponDropSystem.cs` - 武器掉落管理器
- `CraftingStation.cs` - 制作台交互脚本
- `CraftingUI.cs` - 制作界面UI
- `CraftingManager.cs` - 制作逻辑管理器
- `PlayerWeaponController.cs` - 玩家武器控制器（扩展现有攻击系统）

## 测试场景

创建测试场景 `WeaponTest.unity` 验证以下流程：

1. **武器制作测试**
   - 玩家靠近制作台，UI正常显示
   - 资源充足时制作按钮可点击
   - 制作后资源正确扣除，武器生成

2. **武器掉落测试**
   - 击杀怪物有概率掉落武器
   - 宝箱开启有概率包含武器
   - 掉落武器可被玩家拾取

3. **武器攻击测试**
   - 近战武器攻击造成伤害并播放动画
   - 远程武器发射投射物并命中目标
   - 武器特效正确触发（击退、流血等）

## 集成要点

1. **资源系统对接**：制作时调用GameManager扣除资源
2. **背包系统预留**：武器获取后添加到玩家背包（未来扩展）
3. **UI系统集成**：制作UI与现有ResourceUI风格一致
4. **数据持久化**：玩家拥有的武器数据需要保存到GameManager

## 验收标准对照

| 验收标准 | 实现方案 |
|----------|----------|
| 武器数据结构文档完整 | 本文档 + 代码定义 |
| 至少两种武器预制体 | Sword_Wood.prefab, Bow_Wood.prefab |
| 制作台交互正常 | CraftingStation.cs + CraftingUI.cs |
| 怪物死亡掉落武器 | 扩展EnemyHealth.cs + WeaponDropSystem.cs |
| 宝箱包含武器 | 扩展Chest脚本 + 掉落系统 |
| 玩家可切换武器攻击 | PlayerWeaponController.cs扩展 |
| 不同武器不同效果 | WeaponData.effects + 攻击逻辑实现 |
| 无编译错误 | 脚本结构清晰，引用正确 |
| 测试场景验证全流程 | WeaponTest.unity场景 |

## 后续扩展方向

1. **武器强化系统**：使用额外资源升级武器属性
2. **附魔系统**：为武器添加额外魔法效果
3. **武器耐久度**：使用一定次数后需要修复
4. **武器套装效果**：同时装备特定武器组合获得加成