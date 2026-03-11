# BiomeManager.gd
# 管理岛屿的生态环境类型及其属性

extends Node

enum BiomeType {
	FOREST,      # 森林：更多树木，木材资源丰富
	MINE,        # 矿山：更多矿石，山脉地形突出
	SWAMP,       # 沼泽：更多药草，水域较多
	SNOWY,       # 雪原：冰雪覆盖，资源稀缺
	VOLCANO,     # 火山：岩浆地形，特殊资源
	JUNGLE       # 丛林：密集植被，生物多样性
}

# 生态环境参数配置
class BiomeConfig:
	var name: String
	var color: Color
	var terrain_thresholds: Dictionary  # 水域、草地、森林、山脉的阈值
	var resource_weights: Dictionary    # 木材、矿石、药草的权重
	
	func _init(p_name: String, p_color: Color, p_thresholds: Dictionary, p_weights: Dictionary):
		name = p_name
		color = p_color
		terrain_thresholds = p_thresholds
		resource_weights = p_weights

var biome_configs: Dictionary

func _ready():
	_initialize_biomes()

func _initialize_biomes():
	# 森林生态环境
	var forest_thresholds = {
		"water": 0.25,
		"grass": 0.6,
		"forest": 0.8,
		"mountain": 1.0
	}
	var forest_weights = {
		"wood": 0.7,
		"ore": 0.1,
		"herb": 0.2
	}
	biome_configs[BiomeType.FOREST] = BiomeConfig.new(
		"Forest", Color("2a7e3e"), forest_thresholds, forest_weights
	)
	
	# 矿山生态环境
	var mine_thresholds = {
		"water": 0.35,
		"grass": 0.6,
		"forest": 0.75,
		"mountain": 1.0
	}
	var mine_weights = {
		"wood": 0.2,
		"ore": 0.7,
		"herb": 0.1
	}
	biome_configs[BiomeType.MINE] = BiomeConfig.new(
		"Mine", Color("8c7853"), mine_thresholds, mine_weights
	)
	
	# 沼泽生态环境
	var swamp_thresholds = {
		"water": 0.2,
		"grass": 0.4,
		"forest": 0.6,
		"mountain": 1.0
	}
	var swamp_weights = {
		"wood": 0.3,
		"ore": 0.1,
		"herb": 0.6
	}
	biome_configs[BiomeType.SWAMP] = BiomeConfig.new(
		"Swamp", Color("3a5a40"), swamp_thresholds, swamp_weights
	)
	
	# 雪原生态环境（基础实现，待扩展）
	var snowy_thresholds = {
		"water": 0.3,
		"grass": 0.5,
		"forest": 0.7,
		"mountain": 1.0
	}
	var snowy_weights = {
		"wood": 0.3,
		"ore": 0.3,
		"herb": 0.4
	}
	biome_configs[BiomeType.SNOWY] = BiomeConfig.new(
		"Snowy", Color("e8f4f8"), snowy_thresholds, snowy_weights
	)
	
	# 火山生态环境（基础实现，待扩展）
	var volcano_thresholds = {
		"water": 0.4,
		"grass": 0.55,
		"forest": 0.7,
		"mountain": 1.0
	}
	var volcano_weights = {
		"wood": 0.1,
		"ore": 0.6,
		"herb": 0.3
	}
	biome_configs[BiomeType.VOLCANO] = BiomeConfig.new(
		"Volcano", Color("d35400"), volcano_thresholds, volcano_weights
	)
	
	# 丛林生态环境（基础实现，待扩展）
	var jungle_thresholds = {
		"water": 0.28,
		"grass": 0.65,
		"forest": 0.85,
		"mountain": 1.0
	}
	var jungle_weights = {
		"wood": 0.5,
		"ore": 0.2,
		"herb": 0.3
	}
	biome_configs[BiomeType.JUNGLE] = BiomeConfig.new(
		"Jungle", Color("27ae60"), jungle_thresholds, jungle_weights
	)

# 获取生态环境配置
func get_biome_config(biome_type: BiomeType) -> BiomeConfig:
	return biome_configs.get(biome_type)

# 获取生态环境名称
func get_biome_name(biome_type: BiomeType) -> String:
	var config = get_biome_config(biome_type)
	return config.name if config else "Unknown"

# 获取生态环境颜色
func get_biome_color(biome_type: BiomeType) -> Color:
	var config = get_biome_config(biome_type)
	return config.color if config else Color.WHITE

# 根据噪声值获取图块类型
func get_tile_type_for_noise(noise_value: float, biome_type: BiomeType) -> String:
	var config = get_biome_config(biome_type)
	if not config:
		return "water"
	
	var thresholds = config.terrain_thresholds
	if noise_value < thresholds.water:
		return "water"
	elif noise_value < thresholds.grass:
		return "grass"
	elif noise_value < thresholds.forest:
		return "forest"
	else:
		return "mountain"

# 获取资源类型权重
func get_resource_weights(biome_type: BiomeType) -> Dictionary:
	var config = get_biome_config(biome_type)
	return config.resource_weights if config else {"wood": 0.33, "ore": 0.33, "herb": 0.34}

# 根据生态环境随机选择资源类型
func get_random_resource_type(biome_type: BiomeType) -> String:
	var weights = get_resource_weights(biome_type)
	var total = weights.values().reduce(func(a, b): return a + b, 0.0)
	var rand = randf_range(0.0, total)
	
	var cumulative = 0.0
	for resource_type in weights.keys():
		cumulative += weights[resource_type]
		if rand <= cumulative:
			return resource_type
	
	return "wood"  # 默认回退