# 基础建造系统设计文档

## 1. 系统概述
基础建造系统允许玩家在主岛上放置和管理建筑，支持资源收集、制作和生存功能。系统与现有的资源采集系统（PlayerResourceCollector.cs）、游戏管理器（GameManager.cs）和预制体系集成。

## 2. 建筑数据结构

### 2.1 建筑类型枚举
```csharp
public enum BuildingType
{
    Workbench,    // 工作台：用于制作武器和工具
    Farmland,     // 农田：用于种植作物
    Campfire      // 篝火：提供光照和安全感
}
```

### 2.2 建筑数据类
```csharp
[System.Serializable]
public class BuildingData
{
    public BuildingType type;
    public Vector2 position;          // 建筑位置
    public bool isPlaced;             // 是否已放置
    public float placementTime;       // 放置时间（用于生长计时等）
    public FarmlandState farmState;   // 农田状态（仅对农田有效）
}

[System.Serializable]
public class FarmlandState
{
    public bool hasSeed;              // 是否已种植种子
    public float plantTime;           // 种植时间
    public bool isReadyToHarvest;     // 是否可收获
    public string seedType;           // 种子类型（目前仅支持"herb_seed"）
}
```

### 2.3 建筑配方配置
| 建筑类型 | 所需资源 | 数量 | 功能描述 |
|---------|---------|------|---------|
| 工作台 | 木材 | 10 | 用于制作武器、工具和装备。提供制作界面，解锁更多制作配方。 |
| 农田 | 木材 | 5<br>石头 | 3 | 用于种植作物。玩家可将采集的种子放入农田，经过生长时间后收获作物（药草）。 |
| 篝火 | 木材 | 8<br>石头 | 2 | 提供动态光照范围和效果。夜间探索时提供视野和安全区，会吸引怪物但提供保护。 |

## 3. 系统组件设计

### 3.1 BuildingManager（建造管理器）
- **职责**：管理所有建筑实例，处理建造模式切换，验证放置位置，保存/加载建筑数据。
- **关键方法**：
  - `EnterBuildMode()`：进入建造模式，显示建筑选择UI
  - `ExitBuildMode()`：退出建造模式
  - `PlaceBuilding(BuildingType type, Vector2 position)`：放置建筑并扣除资源
  - `SaveBuildings()`：保存建筑数据到持久化存储
  - `LoadBuildings()`：从持久化存储加载建筑

### 3.2 Building 基类
- **组件**：所有建筑的基类，包含共同属性和方法
- **属性**：
  - `buildingType`：建筑类型
  - `requiredResources`：所需资源字典
  - `isPlaced`：是否已放置
- **方法**：
  - `CanAfford()`：检查玩家是否有足够资源
  - `ConsumeResources()`：扣除资源
  - `OnPlaced()`：放置后触发的事件

### 3.3 具体建筑类

#### 3.3.1 WorkbenchBuilding
- **功能**：提供制作界面
- **交互**：玩家靠近按交互键打开制作UI
- **集成**：与现有的CraftingManager.cs和CraftingUI.cs系统连接

#### 3.3.2 FarmlandBuilding
- **功能**：种植和收获作物
- **状态机**：
  1. 空闲状态：等待种植种子
  2. 种植状态：种子已种植，生长中
  3. 成熟状态：作物可收获
- **交互**：
  - 玩家手持种子时按交互键种植
  - 作物成熟后按交互键收获
- **生长时间**：120秒（可配置）

#### 3.3.3 CampfireBuilding
- **功能**：提供光照和安全感
- **视觉效果**：
  - 动态光源（Unity Light2D组件）
  - 粒子效果（火焰）
- **游戏机制**：
  - 提供半径为5单位的圆形光照区域
  - 夜间在光照区域内怪物攻击力降低20%
  - 会吸引10单位半径内的怪物

### 3.4 BuildingPreview（建造预览）
- **功能**：在建造模式下显示建筑预览
- **视觉效果**：
  - 绿色：可放置位置
  - 红色：不可放置位置（与其他建筑重叠、地形阻挡等）
- **控制**：使用鼠标选择位置，左键确认放置，右键取消

## 4. 持久化设计

### 4.1 数据存储
- **存储方式**：JSON序列化
- **文件路径**：`Application.persistentDataPath + "/building_data.json"`
- **存储内容**：
  ```json
  {
    "buildings": [
      {
        "type": "Workbench",
        "position": {"x": 10.5, "y": 2.3},
        "isPlaced": true,
        "placementTime": 1646641200,
        "farmState": null
      }
    ]
  }
  ```

### 4.2 保存时机
1. 玩家放置新建筑时
2. 游戏保存时（通过GameManager）
3. 场景切换时
4. 游戏退出时（需处理退出事件）

## 5. 与现有系统集成

### 5.1 资源系统集成
- 使用`GameManager.Instance.AddResource()`和资源检查
- 建筑消耗资源时调用`GameManager.Instance.AddResource(negativeAmount)`

### 5.2 时间系统集成
- 使用`GameManager.dayTime`和`isDay`判断昼夜
- 篝火在夜间自动激活光照效果
- 农田生长基于真实时间（Time.deltaTime）

### 5.3 怪物系统集成
- 篝火的光照区域影响怪物行为（通过MonsterNightBoostSystem）
- 怪物被吸引到篝火附近但攻击力降低

## 6. 测试场景设计

### 6.1 测试场景要素
1. **主岛区域**：平坦地形，用于放置建筑
2. **资源节点**：木材、石头资源，用于收集测试
3. **UI测试面板**：显示当前资源和建筑状态
4. **调试控制**：
   - 快捷键增加资源（F1：木材+10，F2：石头+10）
   - 快捷键切换建造模式（B键）
   - 显示建筑网格和可放置区域

### 6.2 测试流程
1. 收集足够资源（木材、石头）
2. 进入建造模式（B键）
3. 选择建筑类型（1：工作台，2：农田，3：篝火）
4. 移动鼠标预览放置位置
5. 左键确认放置，扣除资源
6. 测试农田种植交互：
   - 采集药草种子（从资源节点）
   - 靠近农田按E键种植
   - 等待生长时间（可加速测试）
   - 按E键收获药草
7. 验证数据持久化：重启游戏后建筑仍然存在

## 7. 后续扩展

### 7.1 建筑升级系统
- 每个建筑可升级1-3级
- 升级消耗更多资源但提供更强功能
- 工作台：解锁更多制作配方
- 农田：减少生长时间，增加产量
- 篝火：增大光照半径，提供更强保护

### 7.2 更多建筑类型
- 仓库：增加资源存储上限
- 防御塔：自动攻击靠近的怪物
- 装饰建筑：提升主岛美观度

### 7.3 多人联机支持
- 同步建筑状态到所有玩家
- 处理建筑权限（谁可以建造/使用）
- 建筑损坏和修复机制

---
*设计文档版本：1.0*
*最后更新：2026年3月7日*
*对应游戏版本：原型阶段*