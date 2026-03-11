# 武器系统快速设置指南

## 1. 系统初始化

### 1.1 创建管理器对象
在Unity场景中创建以下空GameObject并添加对应组件：

1. **WeaponDropSystem**
   - 添加组件: `WeaponSystem.WeaponDropSystem`
   - 作用: 管理所有武器掉落逻辑

2. **CraftingManager** 
   - 添加组件: `WeaponSystem.CraftingManager`
   - 配置预制体引用:
     - `swordWoodPrefab`: 拖入 `Prefabs/Weapons/Sword_Wood.prefab`
     - `bowWoodPrefab`: 拖入 `Prefabs/Weapons/Bow_Wood.prefab`
     - 铁质武器预制体（可留空，后续添加）

### 1.2 配置玩家角色
为玩家角色添加以下组件：

1. **PlayerWeaponController**
   - 添加组件: `WeaponSystem.PlayerWeaponController`
   - 设置 `weaponHolder`: 创建空子物体命名为"WeaponHolder"

## 2. 制作台设置

### 2.1 创建制作台预制体
1. 创建空GameObject命名为 "CraftingStation"
2. 添加组件:
   - `SpriteRenderer` - 分配制作台精灵
   - `BoxCollider2D` - 设置 Is Trigger = true
   - `WeaponSystem.CraftingStation`

### 2.2 创建制作UI
1. 创建Canvas命名为 "CraftingUI"
2. 添加子元素:
   - 背景Panel
   - 武器列表ScrollView
   - 资源信息Text
   - 关闭按钮
3. 添加组件: `WeaponSystem.CraftingUI`
4. 保存为预制体: `Prefabs/UI/CraftingUI.prefab`

### 2.3 连接制作台与UI
将CraftingUI预制体拖拽到CraftingStation组件的`craftingUIPrefab`字段

## 3. 宝箱设置

### 3.1 创建宝箱预制体
1. 创建空GameObject命名为 "Chest"
2. 添加组件:
   - `SpriteRenderer` - 分配宝箱精灵（开/关状态）
   - `BoxCollider2D` - 设置 Is Trigger = true
   - `WeaponSystem.ChestInteract`

### 3.2 配置宝箱类型
在ChestInteract组件中设置:
- `chestType`: Common（普通）或 Rare（稀有）
- `closedSprite`: 关闭状态的精灵
- `openSprite`: 打开状态的精灵

## 4. 怪物配置

### 4.1 现有怪物设置
确保怪物GameObject包含`EnemyHealth`组件，并配置:
- `enemyType`: Normal（普通）, Elite（精英）, 或 Boss（首领）

### 4.2 掉落逻辑验证
EnemyHealth.cs已集成`TryDropWeapon()`方法，死亡时会自动调用对应掉落表

## 5. 测试验证

### 5.1 快速测试脚本
使用`WeaponSystemTester`组件进行自动化测试:

1. 创建空GameObject命名为 "SystemTester"
2. 添加组件: `WeaponSystem.WeaponSystemTester`
3. 配置引用:
   - `craftingManager`: 拖入CraftingManager对象
   - `weaponDropSystem`: 拖入WeaponDropSystem对象
   - `playerWeaponController`: 拖入玩家对象
4. 勾选 `runAutomatedTests` 自动运行测试

### 5.2 手动测试步骤
1. **收集资源**: 使用PlayerResourceCollector采集木材
2. **制作武器**: 靠近制作台按E，制作木剑
3. **拾取武器**: 自动装备木剑
4. **攻击测试**: 左键攻击，验证伤害逻辑
5. **掉落测试**: 击杀怪物，验证武器掉落
6. **宝箱测试**: 开启宝箱，验证武器掉落

## 6. 故障排除

### 6.1 常见问题
**问题**: 制作UI不显示
**解决**: 检查CraftingStation的`craftingUIPrefab`引用是否正确

**问题**: 武器无法攻击
**解决**: 检查PlayerWeaponController的`weaponHolder`设置

**问题**: 无掉落
**解决**: 验证WeaponDropSystem实例存在且已初始化

### 6.2 日志检查
关键日志消息:
- "Player near crafting station. Press E to open crafting menu."
- "Crafting UI opened"
- "Crafted weapon: sword_wood"
- "Player attacked with [武器名]"
- "掉落武器: [武器ID]"

## 7. 扩展配置

### 7.1 武器数据配置
创建ScriptableObject配置武器属性:
1. Assets → Create → C# Script → 继承WeaponData
2. 配置各项属性
3. 拖拽到武器预制体的Weapon组件

### 7.2 掉落概率调整
在WeaponDropSystem组件中直接修改:
- `normalEnemyTable.dropChance`: 普通怪物掉落概率
- `commonChestTable.dropChance`: 普通宝箱掉落概率

## 8. 性能建议

1. **对象池**: 频繁掉落的武器建议使用对象池
2. **延迟加载**: 高级武器资源可延迟加载
3. **缓存引用**: 常用组件引用缓存到变量中

## 9. 技术支持

如遇配置问题，请检查:
- Unity控制台错误信息
- 脚本引用完整性
- 预制体依赖关系
- 场景对象层级