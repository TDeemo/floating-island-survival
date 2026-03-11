# 岛屿地形生成系统使用指南

## 概述
本系统基于Perlin噪声算法生成64×64网格的岛屿地形，包含草地、森林、山脉、水域四种基础图块。系统提供完整的编辑器工具，支持一键生成测试岛屿。

## 文件清单
- `漂浮大陆/Assets/Scripts/IslandGenerator.cs` - 主生成脚本
- `漂浮大陆/Assets/Scripts/CustomTile.cs` - 自定义Tile基类
- `漂浮大陆/Assets/Scripts/TileFactory.cs` - 运行时Tile创建工具
- `漂浮大陆/Assets/Scripts/IslandGeneratorSetup.cs` - 场景自动设置脚本
- `漂浮大陆/Assets/Editor/IslandGeneratorEditor.cs` - 编辑器Inspector工具

## 快速开始

### 方法一：通过菜单创建（推荐）
1. 在Unity编辑器中，选择菜单 `GameObject → Island Generator → Create Island Generator`
2. 系统会自动创建包含Tilemap和IslandGenerator组件的游戏对象
3. 在Inspector中点击"Generate Island"按钮生成地形

### 方法二：手动设置
1. 创建空GameObject，命名为"Island Generator"
2. 添加Tilemap组件和TilemapRenderer组件
3. 添加IslandGenerator脚本组件
4. 将Tilemap组件拖拽到IslandGenerator的tilemap字段
5. 点击"Generate Island"按钮

### 方法三：运行时生成
1. 将IslandGeneratorSetup脚本添加到场景中的任意GameObject
2. 勾选`setupOnAwake`和`generateOnStart`选项
3. 运行游戏，系统会自动创建并生成岛屿

## 组件说明

### IslandGenerator
核心生成脚本，主要参数：

| 参数 | 说明 | 默认值 |
|------|------|--------|
| tilemap | 目标Tilemap组件 | 必需 |
| grassTile | 草地Tile | 自动创建 |
| forestTile | 森林Tile | 自动创建 |
| mountainTile | 山脉Tile | 自动创建 |
| waterTile | 水域Tile | 自动创建 |
| width | 地形宽度 | 64 |
| height | 地形高度 | 64 |
| scale | 噪声缩放系数 | 10.0 |
| waterLevel | 水域阈值 | 0.3 |
| grassLevel | 草地阈值 | 0.5 |
| forestLevel | 森林阈值 | 0.7 |
| mountainLevel | 山脉阈值 | 0.85 |
| seed | 随机种子 | 0 |
| randomSeed | 使用随机种子 | true |
| createIslandShape | 创建岛屿形状 | true |
| islandRadius | 岛屿半径（相对于地图） | 0.4 |
| autoGenerate | 编辑器自动生成 | false |

### 编辑器功能
在IslandGenerator组件的Inspector中提供以下功能：

1. **Generate Island** - 生成新岛屿
2. **Clear Island** - 清除所有图块
3. **快速Tile查找按钮** - 在项目中查找指定名称的Tile
4. **Auto-Find All Tiles** - 自动查找所有四种Tile

## 算法说明

### Perlin噪声生成
系统使用Unity内置的`Mathf.PerlinNoise`函数生成基础噪声，并叠加高频细节噪声，创建更自然的地形变化。

### 岛屿形状处理
通过距离衰减函数，确保生成的地形中央为陆地，周边为水域，形成岛屿形状。

### 图块分配规则
根据噪声值分配Tile类型：
- 噪声值 < 0.3 → 水域
- 0.3 ≤ 噪声值 < 0.5 → 草地
- 0.5 ≤ 噪声值 < 0.7 → 森林
- 0.7 ≤ 噪声值 < 0.85 → 山脉
- 噪声值 ≥ 0.85 → 山脉

## 自定义与扩展

### 使用自定义Tile
1. 创建继承自TileBase的自定义Tile（如CustomTile）
2. 在项目中创建Tile资产
3. 将Tile资产拖拽到IslandGenerator的对应字段

### 调整地形参数
通过调整以下参数控制地形特征：
- `scale`：值越小，地形变化越平缓；值越大，地形越破碎
- `waterLevel`~`mountainLevel`：调整各类地形的分布比例
- `islandRadius`：控制岛屿大小（0-1，1为填满整个地图）

### 扩展图块类型
1. 在`GetTileForNoiseValue`方法中添加新的判断条件
2. 在Inspector中添加对应的Tile字段
3. 在编辑器脚本中更新查找逻辑

## 性能考虑
- 64×64网格包含4096个Tile，生成即时
- 使用对象池管理Tile实例（通过TileFactory缓存）
- 支持分块加载（可扩展）

## 已知限制
1. 动态创建的Tile在编辑器模式下不会保存为资产
2. 如需持久化Tile资产，需手动创建并分配
3. 当前版本仅支持64×64固定大小，可通过修改width/height参数调整

## 故障排除

### 问题：点击Generate Island无反应
- 检查tilemap字段是否已分配
- 检查Console是否有错误信息
- 确保游戏对象处于激活状态

### 问题：地形全为水域或全为陆地
- 调整waterLevel参数
- 检查createIslandShape是否启用
- 检查islandRadius值是否过小/过大

### 问题：Tile显示为紫色（丢失）
- 检查Tile资产是否已正确分配
- 确保CustomTile脚本编译无错误
- 尝试使用"Auto-Find All Tiles"按钮

## 后续开发计划
1. 支持多生态岛屿类型（森林、矿山、沼泽等）
2. 添加资源节点（树木、矿石）随机分布
3. 集成港口生成与撤离机制
4. 优化分块加载与内存管理

---

**文档版本**：1.0  
**最后更新**：2026-03-05  
**关联文档**：
- [游戏设计文档](../game_design_document.md)
- [技术架构方案](../technical_architecture.md)
- [原型规划](../prototype_plan.md)