# ResourceDistributor.gd
# 资源分布逻辑，负责在岛屿上放置资源节点

extends Node

# 资源分布参数
@export var base_density: float = 0.2  # 基础资源密度
@export var cluster_radius: int = 3    # 资源聚集半径
@export var min_distance: int = 2      # 资源间最小距离

# 资源类型配置
class ResourceConfig:
	var type: String
	var preferred_tile: String  # 偏好的图块类型
	var spawn_probability: float
	var min_amount: int
	var max_amount: int
	
	func _init(p_type: String, p_preferred_tile: String, p_prob: float, p_min: int, p_max: int):
		type = p_type
		preferred_tile = p_preferred_tile
		spawn_probability = p_prob
		min_amount = p_min
		max_amount = p_max

var resource_configs: Dictionary

func _ready():
	_initialize_resource_configs()

func _initialize_resource_configs():
	# 木材资源：偏好森林图块
	resource_configs["wood"] = ResourceConfig.new(
		"wood", "forest", 0.25, 1, 3
	)
	
	# 矿石资源：偏好山脉图块
	resource_configs["ore"] = ResourceConfig.new(
		"ore", "mountain", 0.2, 1, 4
	)
	
	# 药草资源：偏好草地图块
	resource_configs["herb"] = ResourceConfig.new(
		"herb", "grass", 0.15, 1, 2
	)

# 生成资源分布
func distribute_resources(heightmap: Array, tile_type_func: Callable, biome_resource_weights: Dictionary, width: int, height: int) -> Array:
	"""
	在岛屿上分布资源节点
	
	参数:
		heightmap: 二维噪声数组
		tile_type_func: 函数，接收噪声值返回图块类型
		biome_resource_weights: 生态环境资源权重字典
		width, height: 地图尺寸
	
	返回:
		资源位置数组，每个元素为字典：{
			"position": Vector2i,
			"type": String,
			"amount": int
		}
	"""
	var resources = []
	var occupied_positions = {}
	
	# 调整基础密度基于生态环境
	var adjusted_density = base_density * _get_biome_density_factor(biome_resource_weights)
	
	# 第一轮：在偏好图块上放置资源
	for y in range(height):
		for x in range(width):
			var noise_value = heightmap[y][x]
			var tile_type = tile_type_func.call(noise_value)
			
			# 跳过水域
			if tile_type == "water":
				continue
			
			# 检查是否已有资源在附近
			if is_position_occupied(x, y, occupied_positions, min_distance):
				continue
			
			# 根据图块类型决定可能的资源类型
			var possible_resources = get_possible_resources_for_tile(tile_type, biome_resource_weights)
			if possible_resources.size() == 0:
				continue
			
			# 随机决定是否生成资源
			if randf() < adjusted_density:
				# 选择资源类型（根据权重）
				var resource_type = select_resource_type(possible_resources, biome_resource_weights)
				var config = resource_configs.get(resource_type)
				
				if config:
					# 生成资源量
					var amount = randi_range(config.min_amount, config.max_amount)
					
					resources.append({
						"position": Vector2i(x, y),
						"type": resource_type,
						"amount": amount
					})
					
					# 标记位置为已占用
					occupied_positions[Vector2i(x, y)] = true
					
					# 概率性生成资源簇（聚集效果）
					if randf() < 0.3:  # 30%概率生成簇
						generate_resource_cluster(x, y, resource_type, heightmap, tile_type_func, 
							biome_resource_weights, width, height, resources, occupied_positions)
	
	return resources

# 检查位置是否被占用（考虑最小距离）
func is_position_occupied(x: int, y: int, occupied: Dictionary, min_dist: int) -> bool:
	var pos = Vector2i(x, y)
	
	# 精确位置检查
	if occupied.has(pos):
		return true
	
	# 最小距离检查
	for occupied_pos in occupied.keys():
		var distance = abs(occupied_pos.x - x) + abs(occupied_pos.y - y)  # 曼哈顿距离
		if distance < min_dist:
			return true
	
	return false

# 获取图块类型可能的资源类型
func get_possible_resources_for_tile(tile_type: String, biome_weights: Dictionary) -> Array:
	var possible = []
	
	for resource_type in resource_configs.keys():
		var config = resource_configs[resource_type]
		
		# 资源偏好匹配图块类型
		if config.preferred_tile == tile_type:
			# 检查生态环境权重是否支持此资源
			var weight = biome_weights.get(resource_type, 0.0)
			if weight > 0.0:
				possible.append(resource_type)
	
	return possible

# 根据权重选择资源类型
func select_resource_type(possible_resources: Array, biome_weights: Dictionary) -> String:
	if possible_resources.size() == 1:
		return possible_resources[0]
	
	# 计算总权重
	var total_weight = 0.0
	for resource_type in possible_resources:
		total_weight += biome_weights.get(resource_type, 0.0)
	
	if total_weight <= 0.0:
		# 权重为零，均等随机
		return possible_resources[randi_range(0, possible_resources.size() - 1)]
	
	# 加权随机选择
	var rand_value = randf_range(0.0, total_weight)
	var cumulative = 0.0
	
	for resource_type in possible_resources:
		cumulative += biome_weights.get(resource_type, 0.0)
		if rand_value <= cumulative:
			return resource_type
	
	return possible_resources[0]  # 回退

# 生成资源簇（聚集效果）
func generate_resource_cluster(center_x: int, center_y: int, resource_type: String, 
	heightmap: Array, tile_type_func: Callable, biome_weights: Dictionary,
	width: int, height: int, resources: Array, occupied: Dictionary):
	
	var config = resource_configs.get(resource_type)
	if not config:
		return
	
	var cluster_size = randi_range(2, 4)  # 簇大小2-4个资源
	
	for i in range(cluster_size - 1):  # 已有一个中心资源
		# 在中心周围随机偏移
		var attempts = 0
		var placed = false
		
		while attempts < 10 and not placed:
			var dx = randi_range(-cluster_radius, cluster_radius)
			var dy = randi_range(-cluster_radius, cluster_radius)
			
			var x = center_x + dx
			var y = center_y + dy
			
			# 边界检查
			if x < 0 or x >= width or y < 0 or y >= height:
				attempts += 1
				continue
			
			# 检查是否已占用
			if is_position_occupied(x, y, occupied, 1):  # 簇内资源最小距离为1
				attempts += 1
				continue
			
			# 检查图块类型是否合适
			var noise_value = heightmap[y][x]
			var tile_type = tile_type_func.call(noise_value)
			
			if tile_type == "water":
				attempts += 1
				continue
			
			# 检查资源类型是否适合此图块
			var possible = get_possible_resources_for_tile(tile_type, biome_weights)
			if not (resource_type in possible):
				attempts += 1
				continue
			
			# 生成资源
			var amount = randi_range(config.min_amount, config.max_amount)
			
			resources.append({
				"position": Vector2i(x, y),
				"type": resource_type,
				"amount": amount
			})
			
			occupied[Vector2i(x, y)] = true
			placed = true
	
	print("生成资源簇: %s (%d个资源)" % [resource_type, cluster_size])

# 根据生态环境获取密度因子
func _get_biome_density_factor(biome_weights: Dictionary) -> float:
	# 计算总权重
	var total_weight = 0.0
	for weight in biome_weights.values():
		total_weight += weight
	
	if total_weight <= 0.0:
		return 1.0
	
	# 密度因子基于资源权重总和
	# 权重总和越高，资源越丰富
	var density_factor = total_weight * 3.0  # 缩放因子
	
	# 限制在合理范围
	return clamp(density_factor, 0.5, 2.0)

# 获取资源场景路径（供外部调用）
func get_resource_scene_path(resource_type: String) -> String:
	match resource_type:
		"wood":
			return "res://scenes/resources/WoodResource.tscn"
		"ore":
			return "res://scenes/resources/OreResource.tscn"
		"herb":
			return "res://scenes/resources/HerbResource.tscn"
		_:
			return ""

# 验证资源位置是否有效
func validate_resource_position(x: int, y: int, heightmap: Array, tile_type_func: Callable, resource_type: String) -> bool:
	if x < 0 or y < 0:
		return false
	
	if x >= heightmap[0].size() or y >= heightmap.size():
		return false
	
	var noise_value = heightmap[y][x]
	var tile_type = tile_type_func.call(noise_value)
	
	if tile_type == "water":
		return false
	
	# 检查资源类型是否适合图块类型
	var config = resource_configs.get(resource_type)
	if not config:
		return false
	
	if config.preferred_tile != tile_type:
		# 允许非偏好图块，但概率较低
		return randf() < 0.2  # 20%概率
	
	return true