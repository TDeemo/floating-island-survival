# 岛屿资源系统使用指南

## 概述
本系统为漂浮大陆游戏实现了完整的资源节点分布和港口生成功能。系统包含三种资源节点（树木、矿石、浆果丛）和港口区域，可自动集成到岛屿地形生成过程中。

## 系统组件

### 1. 资源节点脚本
- **ResourceNode.cs**: 资源节点的核心脚本，管理生命值、采集交互和资源产出
- **ResourceDrop.cs**: 资源掉落物脚本，采集后产生的可拾取物品
- **ResourceType 枚举**: 定义三种资源类型：Wood（木材）、Ore（矿石）、Berry（浆果）

### 2. 资源分布系统
- **IslandResourcePlacer.cs**: 负责在生成的岛屿上随机放置资源节点和港口
- **IslandManager.cs**: 协调地形生成、资源放置和港口生成的整体流程

### 3. 港口交互系统
- **PortInteract.cs**: 港口交互脚本，提供船只撤离功能

### 4. 辅助工具
- **PlaceholderSpriteCreator.cs**: 创建占位符精灵的工具类
- **ResourcePrefabManager.cs**: 预制体生成管理器（编辑器使用）

## 使用方法

### 快速开始
1. 将 `IslandManager` 组件添加到场景中的任意游戏对象
2. 确保场景中有 `Tilemap` 组件
3. 运行游戏，系统将自动生成完整岛屿（含资源和港口）

### 手动控制
```csharp
// 生成完整岛屿
IslandManager manager = FindObjectOfType<IslandManager>();
manager.GenerateCompleteIsland();

// 仅重新生成资源
manager.RegenerateResources();

// 清除所有内容
manager.ClearEverything();
```

### 编辑器工具
1. **创建资源放置器**: 菜单栏 `GameObject/Island Generator/Create Resource Placer`
2. **可视化资源分布**: 在 `IslandResourcePlacer` 组件中启用 `visualizeResources`
3. **手动放置控制**: 使用检视面板中的按钮手动放置/清除资源和港口

## 配置参数

### IslandResourcePlacer 配置
- **资源密度 (resourceDensity)**: 陆地格子中放置资源的比例（0-1）
- **树木概率 (treeProbability)**: 生成树木的概率（0-1）
- **矿石概率 (oreProbability)**: 生成矿石的概率（0-1）
- **浆果概率**: 自动计算为剩余概率（1 - treeProbability - oreProbability）

### 资源节点属性
每种资源节点可配置：
- **最大生命值**: 树木(3)、矿石(5)、浆果(1)
- **资源产出**: 树木(2)、矿石(3)、浆果(1)
- **视觉精灵**: 健康/受损/耗尽状态的精灵

### 港口属性
- **交互半径**: 玩家与港口交互的距离
- **交互按键**: 默认按 E 键撤离
- **港口名称**: 可自定义的港口显示名称

## 集成到地形生成系统

系统自动与现有的 `IslandGenerator` 集成：

1. `IslandGenerator` 生成地形图块
2. `IslandResourcePlacer` 分析陆地格子位置
3. 根据概率和密度随机放置资源节点
4. 在岛屿边缘（邻水陆地）放置唯一港口

## 调试功能

### 可视化工具
- 启用 `visualizeResources` 在场景视图中查看资源位置
- 不同资源类型使用不同颜色标记：
  - 树木: 绿色
  - 矿石: 灰色
  - 浆果: 红色
  - 港口: 蓝色

### 测试脚本
`TestResourcePlacement.cs` 提供完整的自动化测试：
- 资源节点脚本测试
- 资源放置器功能测试
- 港口放置逻辑测试

## 键盘快捷键
- **R**: 重新生成资源
- **Shift+R**: 重新生成完整岛屿
- **C**: 清除所有内容

## 注意事项

1. **预制体依赖**: 系统需要三种资源预制体和一个港口预制体
2. **Tilemap 要求**: 必须在场景中存在 `Tilemap` 组件
3. **岛屿形状**: 港口放置需要岛屿有水域包围的陆地边缘
4. **性能考虑**: 资源密度过高可能影响性能，建议保持合理密度

## 扩展开发

### 添加新资源类型
1. 扩展 `ResourceType` 枚举
2. 创建新的资源节点预制体
3. 在 `IslandResourcePlacer` 中添加新的放置逻辑

### 自定义采集规则
重写 `ResourceNode.Harvest()` 方法实现自定义采集逻辑

### 港口撤离事件
在 `PortInteract.EvacuatePlayer()` 中添加游戏管理器的回调

## 故障排除

### 问题：资源没有生成
- 检查岛屿是否成功生成（有陆地格子）
- 验证资源密度设置是否大于0
- 确保资源预制体已正确赋值

### 问题：港口没有生成
- 确认岛屿有水域相邻的陆地边缘
- 检查港口预制体是否已赋值
- 验证 `generatePort` 设置是否为 true

### 问题：资源无法采集
- 确保玩家攻击碰撞器标签为 "PlayerAttack"
- 检查资源节点的碰撞器是否启用
- 验证 `ResourceNode` 脚本是否正确附加