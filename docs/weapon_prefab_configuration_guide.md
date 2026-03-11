# 武器预制体配置指南

本文档说明如何正确配置漂浮大陆游戏中的武器预制体。

## 现有预制体

### Sword_Wood.prefab (木剑)
**位置**: `漂浮大陆/Assets/Prefabs/Weapons/Sword_Wood.prefab`

**必需组件**:
1. **SpriteRenderer** - 显示武器精灵
2. **BoxCollider2D** - 触发器，用于拾取检测
   - 设置 `Is Trigger` = true
3. **Weapon (WeaponSystem.Weapon)** - 武器逻辑组件

**Weapon组件配置**:
- `data` (WeaponData): 需要创建ScriptableObject或通过代码配置
- `spriteRenderer`: 拖拽SpriteRenderer组件引用
- `pickupCollider`: 拖拽BoxCollider2D组件引用

### Bow_Wood.prefab (木弓)
**位置**: `漂浮大陆/Assets/Prefabs/Weapons/Bow_Wood.prefab`

**必需组件**:
1. **SpriteRenderer** - 显示武器精灵
2. **BoxCollider2D** - 触发器，用于拾取检测
   - 设置 `Is Trigger` = true
3. **Weapon (WeaponSystem.Weapon)** - 武器逻辑组件

**Weapon组件配置**:
- `data` (WeaponData): 需要创建ScriptableObject或通过代码配置
- `spriteRenderer`: 拖拽SpriteRenderer组件引用
- `pickupCollider`: 拖拽BoxCollider2D组件引用

## 武器数据配置

### 方法一：通过ScriptableObject配置（推荐）
1. 创建ScriptableObject资产：
   ```
   Assets/Resources/WeaponData/wood_sword_data.asset
   Assets/Resources/WeaponData/wood_bow_data.asset
   ```

2. 配置WeaponData字段：
   - `weaponId`: "sword_wood" / "bow_wood"
   - `displayName`: "木剑" / "木弓"
   - `weaponType`: Melee / Ranged
   - `damage`: 5 / 8
   - `attackSpeed`: 1.2 / 0.8
   - `range`: 1.0 / 8.0
   - `effects`: 空数组
   - `weaponSprite`: 分配相应精灵
   - `projectilePrefab`: 仅远程武器需要（Arrow.prefab）
   - `attackSound`: 可选

### 方法二：通过代码动态配置
可以在运行时通过代码创建WeaponData实例：

```csharp
// 示例：创建木剑数据
WeaponData woodSwordData = new WeaponData
{
    weaponId = "sword_wood",
    displayName = "木剑",
    weaponType = WeaponType.Melee,
    damage = 5,
    attackSpeed = 1.2f,
    range = 1.0f,
    effects = new WeaponEffect[0]
};
```

## 预制体创建流程

### 步骤1：创建基础GameObject
1. 在Unity编辑器中创建空GameObject
2. 重命名为 "Sword_Wood" 或 "Bow_Wood"

### 步骤2：添加必需组件
1. **SpriteRenderer**
   - 分配对应的武器精灵
2. **BoxCollider2D**
   - 设置 `Is Trigger` = true
   - 调整大小匹配武器精灵
3. **Weapon (WeaponSystem.Weapon)**
   - 拖拽SpriteRenderer和BoxCollider2D引用到相应字段

### 步骤3：配置WeaponData
1. 创建WeaponData ScriptableObject
2. 分配数据到Weapon组件的`data`字段

### 步骤4：保存为预制体
1. 拖拽GameObject到 `Assets/Prefabs/Weapons/` 文件夹
2. 删除场景中的实例

## 测试验证

验证预制体配置是否正确：

1. **组件检查**:
   - 确保所有必需组件存在
   - 检查引用不为空

2. **数据验证**:
   - WeaponData的weaponId正确
   - 武器类型匹配（近战/远程）
   - 数值在合理范围内

3. **功能测试**:
   - 实例化预制体到场景
   - 玩家可以拾取武器
   - 武器可以装备和攻击

## 故障排除

### 问题1：Weapon组件显示为"Missing"
**原因**: WeaponSystem命名空间未正确编译
**解决**:
1. 确保所有WeaponSystem脚本在同一命名空间
2. 检查编译错误
3. 重新导入脚本

### 问题2：预制体无法被实例化
**原因**: 可能缺少依赖资源
**解决**:
1. 检查精灵资源是否存在
2. 验证预制体引用
3. 检查资源路径

### 问题3：武器无法攻击
**原因**: WeaponData配置错误或攻击逻辑问题
**解决**:
1. 检查WeaponData的damage和attackSpeed
2. 验证攻击动画和碰撞检测
3. 调试攻击逻辑

## 自动配置脚本

提供编辑器脚本 `WeaponPrefabConfigurator.cs` 可自动配置预制体：

```csharp
using UnityEditor;
using UnityEngine;

public class WeaponPrefabConfigurator : EditorWindow
{
    // 编辑器窗口代码
}
```

此脚本可：
1. 自动添加必需组件
2. 配置默认数值
3. 验证预制体完整性

## 联系支持

如遇配置问题，请联系：
- 项目技术负责人
- Unity开发团队
- 查看项目文档和日志