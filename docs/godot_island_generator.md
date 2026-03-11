# Godot 岛屿生成系统设计文档

## 概述
在Godot 4.5.1中重新实现漂浮大陆游戏的岛屿生成系统，支持多种生态环境和随机地形生成。基于Unity版本的算法设计，使用GDScript实现，并充分利用Godot的TileMap和随机数系统。

## 系统架构

### 核心组件

1. **IslandGenerator** (`res://scripts/island_generation/IslandGenerator.gd`)
   - 主生成器类，负责协调地形、资源、港口生成
   - 提供公共API：`generate_island(biome_type, seed)`, `clear_island()`
   - 管理TileMap节点和TileSet资源

2. **BiomeManager** (`res://scripts/island_generation/BiomeManager.gd`)
   - 管理生态环境类型及其属性
   - 支持的生态环境：森林、矿山、沼泽、雪原、火山、丛林
   - 提供生态环境特定的参数：地形噪声阈值、资源分布概率、颜色调色板

3. **TerrainChunk** (`res://scripts/island_generation/TerrainChunk.gd`)
   - 地形分块管理，支持大岛屿的分块加载（未来扩展）
   - 存储局部地形数据和资源位置

4. **HarborPlacer** (`res://scripts/island_generation/HarborPlacer.gd`)
   - 港口生成逻辑，确保港口位于岛屿边缘且连通性良好
   - 提供港口位置和朝向计算

5. **ResourceDistributor** (`res://scripts/island_generation/ResourceDistributor.gd`)
   - 资源节点分布逻辑，根据生态环境分配木材、矿石、药草等资源
   - 控制资源密度和聚集度

### 数据流

1. **初始化阶段**
   - 加载TileSet资源（`res://assets/tilesets/island_tileset.tres`）
   - 创建或获取TileMap节点
   - 配置BiomeManager和随机种子

2. **生成阶段**
   - 使用Perlin噪声生成基础高度图
   - 应用岛屿形状掩码（圆形衰减）
   - 根据生态环境调整阈值，分配图块类型
   - 生成港口位置
   - 分布资源节点

3. **输出阶段**
   - 更新TileMap单元格
   - 在资源位置实例化ResourceNode场景
   - 在港口位置实例化Harbor场景
   - 返回生成数据（尺寸、资源数量、港口位置）

## 算法设计

### 噪声生成
使用Godot的`FastNoiseLite`节点生成Perlin噪声，支持多倍频叠加以增加细节。

```gdscript
var noise = FastNoiseLite.new()
noise.noise_type = FastNoiseLite.TYPE_PERLIN
noise.frequency = 0.05
noise.fractal_octaves = 3
```

### 岛屿形状
通过距离衰减函数创建圆形岛屿：

```gdscript
var distance = Vector2(x - center_x, y - center_y).length()
var radius_factor = distance / (island_radius * min(width, height) / 2)
var island_mask = 1.0 - clamp(radius_factor, 0.0, 1.0)
noise_value = (noise_value + island_mask) / 2.0
```

### 图块分配规则
根据噪声值和生态环境阈值分配图块：

| 图块类型 | 默认阈值 | 森林变体 | 矿山变体 | 沼泽变体 |
|----------|----------|----------|----------|----------|
| 水域     | < 0.3    | < 0.25   | < 0.35   | < 0.2    |
| 草地     | 0.3-0.5  | 0.25-0.6 | 0.35-0.6 | 0.2-0.4  |
| 森林     | 0.5-0.7  | 0.6-0.8  | 0.6-0.75 | 0.4-0.6  |
| 山脉     | ≥ 0.7    | ≥ 0.8    | ≥ 0.75   | ≥ 0.6    |

### 港口生成
1. 扫描岛屿边缘单元格，寻找陆地单元格
2. 选择连通性最好的位置（至少3个相邻陆地单元格）
3. 确保有足够的空地用于港口建筑
4. 计算朝向（面向水域方向）

### 资源分布
1. 根据生态环境确定资源类型偏好：
   - 森林：木材(70%)、药草(20%)、矿石(10%)
   - 矿山：矿石(70%)、木材(20%)、药草(10%)
   - 沼泽：药草(60%)、木材(30%)、矿石(10%)
2. 在合适的图块类型上生成资源节点：
   - 木材：森林图块
   - 矿石：山脉图块
   - 药草：草地图块
3. 使用泊松圆盘采样确保资源分布均匀

## TileSet设计

### 基础图块
使用现有像素风纹理创建TileSet：
- `assets/sprites/Terrain/Tilemap_Flat.png` (640×256) - 平地地形
- `assets/sprites/Terrain/Tilemap_Elevation.png` (640×256) - 高地地形

### 图块映射
| 图块ID | 类型 | 源纹理 | 源区域 |
|--------|------|--------|--------|
| 0      | 水域 | Water.png | 完整纹理 |
| 1      | 草地 | Tilemap_Flat | 第1行第1列 |
| 2      | 森林 | Tilemap_Flat | 第2行第1列 |
| 3      | 山脉 | Tilemap_Elevation | 第1行第1列 |

### 资源节点场景
独立场景，附加到TileMap上方：
- `ResourceNode.tscn`：基础资源节点，包含类型、数量、采集状态
- 变体：`WoodResource.tscn`, `OreResource.tscn`, `HerbResource.tscn`

## 使用示例

### 基础生成
```gdscript
# 创建生成器
var generator = IslandGenerator.new()
generator.setup(get_node("TileMap"))

# 生成森林岛屿
var island_data = generator.generate_island(BiomeManager.FOREST, 12345)

# 获取生成信息
print("岛屿尺寸: ", island_data.size)
print("资源数量: ", island_data.resource_count)
print("港口位置: ", island_data.harbor_position)
```

### 编辑器集成
创建自定义编辑器工具，在Inspector中提供生成按钮：

```gdscript
@tool
extends Node2D

@export var auto_generate: bool = false
@export var biome_type: BiomeManager.BiomeType = BiomeManager.FOREST
@export var random_seed: int = 0

func _ready():
    if not Engine.is_editor_hint() and auto_generate:
        generate_island()
```

## 测试场景

创建 `IslandTest.tscn` 场景包含：
1. TileMap节点（用于显示地形）
2. IslandGenerator节点（附加脚本）
3. 控制UI：
   - 生成按钮（选择生态环境）
   - 随机种子输入框
   - 清除按钮
   - 信息显示面板

## 性能优化

1. **批处理**：使用`TileMap.set_cells_terrain_connect`批量设置单元格
2. **延迟加载**：大岛屿分块生成，仅加载可视区域
3. **对象池**：资源节点实例复用
4. **缓存**：噪声数据预计算和缓存

## 与Unity版本对比

| 特性 | Unity版本 | Godot版本 |
|------|-----------|-----------|
| 引擎API | Unity C# Tilemap | Godot TileMap + GDScript |
| 噪声算法 | Mathf.PerlinNoise | FastNoiseLite |
| 编辑器集成 | 自定义Inspector工具 | @tool脚本 + 导出变量 |
| 资源系统 | Prefab实例化 | PackedScene实例化 |
| 性能策略 | 对象池(TileFactory) | 批处理 + 缓存 |

## 后续扩展计划

1. **动态生态环境**：岛屿内多个生态环境区域混合
2. **侵蚀模拟**：水流侵蚀算法创建更自然地形
3. **洞穴系统**：地下洞穴和隧道生成
4. **建筑放置**：自动在合适位置放置建筑
5. **多线程生成**：后台线程生成大型岛屿

## 文件清单

- `docs/godot_island_generator.md` - 本设计文档
- `scripts/island_generation/IslandGenerator.gd` - 主生成器
- `scripts/island_generation/BiomeManager.gd` - 生态环境管理
- `scripts/island_generation/TerrainChunk.gd` - 地形分块
- `scripts/island_generation/HarborPlacer.gd` - 港口生成
- `scripts/island_generation/ResourceDistributor.gd` - 资源分布
- `scenes/island_test.tscn` - 测试场景
- `assets/tilesets/island_tileset.tres` - TileSet资源
- `scenes/resources/ResourceNode.tscn` - 资源节点场景

---

**文档版本**: 1.0  
**最后更新**: 2026-03-09  
**关联文档**: 
- [Unity岛屿生成指南](../island_generation_guide.md)
- [游戏设计文档](../game_design_document.md)
- [Godot迁移路线图](../godot_migration_roadmap.md)