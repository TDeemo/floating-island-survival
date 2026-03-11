# BuildingManager.gd - 建造系统管理器 (占位符)
# 用于集成测试场景，完整实现将在后续任务中完成

extends Node

class_name BuildingManager

# 建筑类型枚举
enum BuildingType {
	WORKBENCH,    # 工作台
	STORAGE_CHEST, # 储物箱
	FARMLAND,      # 农田
	CAMPFIRE       # 篝火
}

# 建筑数据类
class BuildingData:
	var type: BuildingType
	var name: String
	var resource_cost: Dictionary
	var build_time: float
	var prefab_path: String
	
	func _init(_type: BuildingType, _name: String, _cost: Dictionary, _time: float, _path: String):
		type = _type
		name = _name
		resource_cost = _cost
		build_time = _time
		prefab_path = _path

# 可建造建筑列表
var available_buildings: Array[BuildingData] = []
# 已建造建筑列表
var built_buildings: Array = []

signal building_placed(building_type: BuildingType, position: Vector2)
signal building_demolished(building_type: BuildingType, position: Vector2)
signal building_upgraded(building_type: BuildingType, position: Vector2)

func _ready():
	# 初始化基础建筑数据 (占位符)
	_init_building_data()
	print("BuildingManager initialized (placeholder)")

func _init_building_data():
	# 工作台
	var workbench = BuildingData.new(
		BuildingType.WORKBENCH,
		"工作台",
		{"wood": 10, "stone": 5},
		5.0,
		"res://scenes/buildings/workbench.tscn"
	)
	
	# 储物箱
	var storage_chest = BuildingData.new(
		BuildingType.STORAGE_CHEST,
		"储物箱",
		{"wood": 15},
		3.0,
		"res://scenes/buildings/storage_chest.tscn"
	)
	
	# 农田
	var farmland = BuildingData.new(
		BuildingType.FARMLAND,
		"农田",
		{"wood": 5, "stone": 10},
		10.0,
		"res://scenes/buildings/farmland.tscn"
	)
	
	# 篝火
	var campfire = BuildingData.new(
		BuildingType.CAMPFIRE,
		"篝火",
		{"wood": 8, "stone": 3},
		2.0,
		"res://scenes/buildings/campfire.tscn"
	)
	
	available_buildings = [workbench, storage_chest, farmland, campfire]

# 检查是否可以建造
func can_build(building_type: BuildingType, inventory: Dictionary) -> bool:
	for building in available_buildings:
		if building.type == building_type:
			for resource in building.resource_cost:
				if inventory.get(resource, 0) < building.resource_cost[resource]:
					return false
			return true
	return false

# 放置建筑 (占位符实现)
func place_building(building_type: BuildingType, position: Vector2, inventory: Dictionary) -> bool:
	print("Place building (placeholder): ", building_type, " at ", position)
	# 发出信号供其他系统监听
	building_placed.emit(building_type, position)
	return true

# 获取建筑信息
func get_building_info(building_type: BuildingType) -> BuildingData:
	for building in available_buildings:
		if building.type == building_type:
			return building
	return null