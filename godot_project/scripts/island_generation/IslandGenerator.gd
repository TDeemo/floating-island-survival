# IslandGenerator.gd
# 主岛屿生成器，负责协调地形、资源、港口生成

extends Node2D

# 导出变量，便于编辑器调整
@export var island_width: int = 64
@export var island_height: int = 64
@export var island_radius: float = 0.4  # 相对于地图尺寸的半径比例
@export var noise_scale: float = 10.0
@export var use_random_seed: bool = true
@export var seed_value: int = 0
@export var biome_type: BiomeManager.BiomeType = BiomeManager.BiomeType.FOREST

# 节点引用
@onready var tilemap: TileMap = $TileMap
@onready var biome_manager: BiomeManager = $BiomeManager
@onready var resource_container: Node2D = $ResourceContainer
@onready var harbor_marker: Marker2D = $HarborMarker

# 噪声生成器
var noise: FastNoiseLite
var generated_seed: int

# 生成数据
var generation_data: Dictionary = {}

# 图块类型到图块ID的映射（需要在TileSet中配置）
var tile_ids: Dictionary = {
	"water": 0,
	"grass": 1,
	"forest": 2,
	"mountain": 3
}

# 资源场景（需要提前加载）
var resource_scenes: Dictionary = {
	"wood": preload("res://scenes/resources/WoodResource.tscn"),
	"ore": preload("res://scenes/resources/OreResource.tscn"),
	"herb": preload("res://scenes/resources/HerbResource.tscn")
}

func _ready():
	# 初始化噪声生成器
	initialize_noise()
	
	# 如果自动生成标志启用，则生成岛屿
	if not Engine.is_editor_hint() and has_meta("auto_generate"):
		generate_island()

# 初始化噪声生成器
func initialize_noise():
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.05  # 默认频率，可通过noise_scale调整
	
	# 设置随机种子
	if use_random_seed:
		generated_seed = randi()
	else:
		generated_seed = seed_value
	
	noise.seed = generated_seed
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.5
	noise.fractal_lacunarity = 2.0

# 生成岛屿主函数
func generate_island(custom_biome: BiomeManager.BiomeType = biome_type, custom_seed: int = generated_seed) -> Dictionary:
	# 设置生成参数
	if custom_biome != biome_type:
		biome_type = custom_biome
	
	if custom_seed != generated_seed:
		generated_seed = custom_seed
		noise.seed = generated_seed
	
	# 清除现有数据
	clear_island()
	
	# 生成地形高度图
	var heightmap = generate_heightmap()
	
	# 生成地形图块
	generate_terrain(heightmap)
	
	# 生成港口
	var harbor_pos = generate_harbor(heightmap)
	if harbor_pos != Vector2i(-1, -1):
		harbor_marker.position = tilemap.map_to_local(harbor_pos)
		harbor_marker.visible = true
	
	# 生成资源
	generate_resources(heightmap)
	
	# 收集生成数据
	collect_generation_data(heightmap, harbor_pos)
	
	# 输出日志
	print("岛屿生成完成 - 生态环境: %s, 种子: %d" % [biome_manager.get_biome_name(biome_type), generated_seed])
	print("  尺寸: %d x %d" % [island_width, island_height])
	print("  港口位置: ", harbor_pos)
	print("  资源数量: ", generation_data.resource_count)
	
	return generation_data

# 生成高度图（噪声 + 岛屿形状）
func generate_heightmap() -> Array:
	var heightmap = []
	var center_x = island_width / 2.0
	var center_y = island_height / 2.0
	var max_distance = min(island_width, island_height) * island_radius / 2.0
	
	for y in range(island_height):
		var row = []
		for x in range(island_width):
			# 基础噪声值
			var nx = float(x) / island_width * noise_scale
			var ny = float(y) / island_height * noise_scale
			var noise_value = noise.get_noise_2d(nx, ny)
			# 归一化到 [0, 1]
			noise_value = (noise_value + 1.0) / 2.0
			
			# 应用岛屿形状掩码
			var distance = Vector2(x - center_x, y - center_y).length()
			var radius_factor = distance / max_distance
			var island_mask = 1.0 - clamp(radius_factor, 0.0, 1.0)
			
			# 混合噪声和岛屿形状
			var final_value = (noise_value + island_mask) / 2.0
			row.append(final_value)
		
		heightmap.append(row)
	
	return heightmap

# 根据高度图生成地形图块
func generate_terrain(heightmap: Array):
	var cells = []
	
	for y in range(island_height):
		for x in range(island_width):
			var noise_value = heightmap[y][x]
			var tile_type = biome_manager.get_tile_type_for_noise(noise_value, biome_type)
			var tile_id = tile_ids.get(tile_type, 0)
			
			cells.append(Vector2i(x, y))
	
	# 批量设置图块（假设使用第0个图块层）
	tilemap.set_cells_terrain_connect(0, cells, 0, 0)

# 生成港口位置
func generate_harbor(heightmap: Array) -> Vector2i:
	# 简单的港口生成算法：寻找岛屿边缘的草地图块
	
	var edge_positions = []
	
	# 扫描地图边缘
	for y in range(island_height):
		for x in range(island_width):
			# 只检查边缘附近的单元格
			if x > 2 and x < island_width - 3 and y > 2 and y < island_height - 3:
				continue
			
			var noise_value = heightmap[y][x]
			var tile_type = biome_manager.get_tile_type_for_noise(noise_value, biome_type)
			
			# 寻找草地图块（适合建造港口）
			if tile_type == "grass":
				# 检查是否有相邻水域（确保是海岸）
				var has_adjacent_water = false
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var nx = x + dx
						var ny = y + dy
						if nx >= 0 and nx < island_width and ny >= 0 and ny < island_height:
							var adj_noise = heightmap[ny][nx]
							var adj_tile = biome_manager.get_tile_type_for_noise(adj_noise, biome_type)
							if adj_tile == "water":
								has_adjacent_water = true
								break
					if has_adjacent_water:
						break
				
				if has_adjacent_water:
					edge_positions.append(Vector2i(x, y))
	
	if edge_positions.size() > 0:
		# 随机选择一个边缘位置
		var idx = randi_range(0, edge_positions.size() - 1)
		return edge_positions[idx]
	
	return Vector2i(-1, -1)  # 未找到合适位置

# 生成资源节点
func generate_resources(heightmap: Array):
	# 清除现有资源
	for child in resource_container.get_children():
		child.queue_free()
	
	var resource_count = 0
	
	# 遍历所有陆地单元格，按概率放置资源
	for y in range(island_height):
		for x in range(island_width):
			var noise_value = heightmap[y][x]
			var tile_type = biome_manager.get_tile_type_for_noise(noise_value, biome_type)
			
			# 水域不放置资源
			if tile_type == "water":
				continue
			
			# 根据图块类型确定基础资源概率
			var base_probability = 0.0
			match tile_type:
				"grass":
					base_probability = 0.15  # 草地资源概率较低
				"forest":
					base_probability = 0.25  # 森林资源概率较高
				"mountain":
					base_probability = 0.2   # 山脉资源概率中等
			
			# 随机决定是否放置资源
			if randf() < base_probability:
				# 根据生态环境随机选择资源类型
				var resource_type = biome_manager.get_random_resource_type(biome_type)
				
				# 确保资源类型与图块类型匹配
				if (resource_type == "wood" and tile_type != "forest") or \
				   (resource_type == "ore" and tile_type != "mountain") or \
				   (resource_type == "herb" and tile_type != "grass"):
					# 不匹配，跳过
					continue
				
				# 实例化资源场景
				var resource_scene = resource_scenes.get(resource_type)
				if resource_scene:
					var resource = resource_scene.instantiate()
					resource.position = tilemap.map_to_local(Vector2i(x, y))
					resource_container.add_child(resource)
					resource_count += 1
	
	generation_data["resource_count"] = resource_count

# 收集生成数据
func collect_generation_data(heightmap: Array, harbor_pos: Vector2i):
	generation_data = {
		"width": island_width,
		"height": island_height,
		"seed": generated_seed,
		"biome": biome_manager.get_biome_name(biome_type),
		"harbor_position": harbor_pos,
		"resource_count": generation_data.get("resource_count", 0),
		"tile_distribution": calculate_tile_distribution(heightmap)
	}

# 计算图块类型分布
func calculate_tile_distribution(heightmap: Array) -> Dictionary:
	var distribution = {
		"water": 0,
		"grass": 0,
		"forest": 0,
		"mountain": 0
	}
	
	for y in range(island_height):
		for x in range(island_width):
			var noise_value = heightmap[y][x]
			var tile_type = biome_manager.get_tile_type_for_noise(noise_value, biome_type)
			distribution[tile_type] += 1
	
	return distribution

# 清除岛屿数据
func clear_island():
	# 清除图块
	tilemap.clear()
	
	# 清除资源
	for child in resource_container.get_children():
		child.queue_free()
	
	# 隐藏港口标记
	harbor_marker.visible = false
	
	# 重置生成数据
	generation_data = {}
	
	print("岛屿已清除")

# 编辑器工具：生成按钮
func _on_generate_button_pressed():
	generate_island()

# 编辑器工具：清除按钮
func _on_clear_button_pressed():
	clear_island()

# 设置图块ID映射（用于动态加载TileSet）
func set_tile_ids(water_id: int, grass_id: int, forest_id: int, mountain_id: int):
	tile_ids["water"] = water_id
	tile_ids["grass"] = grass_id
	tile_ids["forest"] = forest_id
	tile_ids["mountain"] = mountain_id