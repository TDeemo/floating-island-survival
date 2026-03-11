# 集成测试场景文档

## 概述
集成测试场景 `integration_test.tscn` 包含了漂浮大陆生存肉鸽游戏所有8个核心系统的代表节点，用于验证组件引用关系和接口契约。

## 包含的系统节点

### 1. 岛屿生成系统
- **节点**: `IslandGenerator`
- **脚本**: `res://scripts/island_generation/IslandGenerator.gd`
- **功能**: 负责程序化生成漂流岛屿，支持多种生态环境变体（森林、矿山、沼泽等）。

### 2. 角色与移动系统
- **节点**: `PlayerInstance` (实例化 `player.tscn`)
- **预制体**: `res://scenes/player/player.tscn`
- **包含组件**: PlayerController、CameraFollow、AnimationManager
- **功能**: 玩家角色控制、相机跟随、动画状态机。

### 3. 资源分布系统
- **节点**: `WoodResource` (实例化 `WoodResource_new.tscn`)
- **预制体**: `res://scenes/resources/WoodResource_new.tscn`
- **脚本引用**: ResourceNode.gd (resource_type = Wood)
- **功能**: 资源节点基础，支持木材、矿石、药草三种资源类型采集。

### 4. 武器与战斗系统
- **节点**: `WeaponInstance` (实例化 `wood_sword.tscn`)
- **预制体**: `res://scenes/weapons/wood_sword.tscn`
- **脚本引用**: WeaponBase.gd
- **功能**: 基础武器实现，支持攻击伤害计算、掉落系统集成。

### 5. 怪物AI系统
- **节点**: `MonsterInstance` (实例化 `skeleton_melee.tscn`)
- **预制体**: `res://scenes/monsters/skeleton_melee.tscn`
- **脚本引用**: MonsterBase.gd、MonsterAI.gd
- **功能**: 怪物行为树、巡逻、追击、攻击逻辑。

### 6. 动态昼夜循环系统
- **节点**: `TimeManager`
- **脚本**: `res://scripts/day_night_system/TimeManager.gd`
- **功能**: 全局时间管理，支持可配置时间流逝、四个昼夜阶段切换。

### 7. 光照系统
- **节点**: `LightSource` (实例化 `torch.tscn`)
- **预制体**: `res://scenes/lights/torch.tscn`
- **脚本引用**: LightSource.gd、TorchLight.gd
- **功能**: 动态光源效果，支持手持火把、夜间视野限制、怪物吸引机制。

### 8. 建造种植系统
- **建筑节点**: `BuildingInstance` (实例化 `workbench.tscn`)
  - **预制体**: `res://scenes/buildings/workbench.tscn`
  - **脚本引用**: BuildingManager.gd、Workbench.gd
  - **功能**: 工作台建筑，支持物品制作交互。
- **作物节点**: `CropPlaceholder` (ColorRect占位符)
  - **类型**: ColorRect节点
  - **参数**: 尺寸32x32，绿色填充
  - **功能**: 作物系统占位符，待环境具备图形界面条件时替换为完整预制体。

## 节点位置布局
为避免重叠，各节点位置如下：
- `PlayerInstance`: Vector2(100, 100)
- `WoodResource`: Vector2(200, 150)
- `MonsterInstance`: Vector2(300, 100)
- `LightSource`: Vector2(150, 200)
- `BuildingInstance`: Vector2(250, 200)
- `CropPlaceholder`: Vector2(350, 200)

## 接口依赖关系
1. **资源采集** → **背包管理**: ResourceCollector.gd 调用 InventoryManager.gd
2. **怪物战斗** → **武器系统**: MonsterBase.gd 接收 WeaponBase.gd 伤害计算
3. **昼夜循环** → **怪物AI**: TimeManager.gd 触发 MonsterNightBoostSystem.gd
4. **建造系统** → **资源消耗**: BuildingManager.gd 检查 InventoryManager.gd
5. **光照系统** → **夜间视野**: LightManager.gd 与 NightVisionSystem.gd 交互

## 待实现项
1. **作物预制体完整创建**: 当前使用ColorRect占位符，待Godot编辑器可用时创建 `wheat.tscn` 和 `carrot.tscn`。
2. **运行时功能验证**: 当前仅验证引用完整性，后续需在具备图形界面环境中测试完整游戏循环。
3. **UI系统集成**: 主菜单、HUD、建造界面等UI组件尚未集成。
4. **多平台适配**: 移动端触控操作、UI响应式布局待实现。
5. **联机服务**: 账号同步、云存档等后端服务待开发。

## 验证方法
1. **文件完整性**: 检查 `integration_test.tscn` 文件存在且无语法错误。
2. **引用正确性**: 所有ext_resource路径指向实际存在的资源文件。
3. **UID匹配**: 无 `uid://placeholder` 残留（当前使用占位符UID `uid://integration_test`，待实际环境生成真实UID）。
4. **节点层次**: 节点父子关系正确，无循环依赖。

## 后续步骤
1. 在具备图形界面的环境中打开Godot编辑器，加载此场景验证组件功能。
2. 依次测试各系统交互：采集资源→制作武器→攻击怪物→建造建筑→种植作物。
3. 根据测试结果修复BUG，优化性能。
4. 逐步集成剩余系统，向可玩原型迈进。