# TerrainChunk.gd
# 地形分块管理，支持大岛屿的分块加载（未来扩展）

extends Node2D

# 分块属性
@export var chunk_size: Vector2i = Vector2i(16, 16)  # 每个分块的单元格数量
@export var chunk_position: Vector2i = Vector2i.ZERO  # 分块在网格中的位置

# 分块数据
var heightmap: Array = []  # 本地高度图
var tile_data: Dictionary = {}  # 图块类型数据
var resource_nodes: Array = []  # 资源节点引用

# 状态标志
var is_loaded: bool = false
var is_visible: bool = false

func _ready():
	# 初始化空高度图
	_initialize_empty_heightmap()

# 初始化空高度图
func _initialize_empty_heightmap():
	heightmap = []
	for y in range(chunk_size.y):
		var row = []
		for x in range(chunk_size.x):
			row.append(0.0)
		heightmap.append(row)

# 生成分块地形
func generate_chunk(noise_generator: FastNoiseLite, global_chunk_pos: Vector2i, noise_scale: float, island_radius: float, island_center: Vector2) -> bool:
	"""
	生成分块地形数据
	
	参数:
		noise_generator: FastNoiseLite实例
		global_chunk_pos: 分块在全局网格中的位置
		noise_scale: 噪声缩放
		island_radius: 岛屿半径（相对于整个地图）
		island_center: 岛屿中心（全局坐标）
	
	返回:
		是否成功生成
	"""
	chunk_position = global_chunk_pos
	
	# 计算分块在世界中的起始位置
	var world_start_x = chunk_position.x * chunk_size.x
	var world_start_y = chunk_position.y * chunk_size.y
	
	# 生成高度图
	for local_y in range(chunk_size.y):
		for local_x in range(chunk_size.x):
			var world_x = world_start_x + local_x
			var world_y = world_start_y + local_y
			
			# 计算噪声值
			var nx = float(world_x) / noise_scale
			var ny = float(world_y) / noise_scale
			var noise_value = noise_generator.get_noise_2d(nx, ny)
			noise_value = (noise_value + 1.0) / 2.0  # 归一化到[0,1]
			
			# 应用岛屿形状（圆形衰减）
			var distance = Vector2(world_x - island_center.x, world_y - island_center.y).length()
			var max_distance = island_radius * min(island_center.x * 2, island_center.y * 2) / 2.0
			var radius_factor = distance / max_distance
			var island_mask = 1.0 - clamp(radius_factor, 0.0, 1.0)
			
			# 混合噪声和岛屿形状
			var final_value = (noise_value + island_mask) / 2.0
			heightmap[local_y][local_x] = final_value
	
	is_loaded = true
	return true

# 设置分块图块数据
func set_tile_data(local_pos: Vector2i, tile_type: String):
	tile_data[local_pos] = tile_type

# 获取分块图块数据
func get_tile_data(local_pos: Vector2i) -> String:
	return tile_data.get(local_pos, "water")

# 添加资源节点
func add_resource_node(resource_info: Dictionary):
	resource_nodes.append(resource_info)

# 获取所有资源节点
func get_resource_nodes() -> Array:
	return resource_nodes.duplicate()

# 清除分块数据
func clear_chunk():
	heightmap = _initialize_empty_heightmap()
	tile_data.clear()
	resource_nodes.clear()
	is_loaded = false
	is_visible = false

# 检查位置是否在分块内
func is_position_in_chunk(local_pos: Vector2i) -> bool:
	return (local_pos.x >= 0 and local_pos.x < chunk_size.x and 
			local_pos.y >= 0 and local_pos.y < chunk_size.y)

# 获取分块边界
func get_chunk_bounds() -> Rect2i:
	var world_start = chunk_position * chunk_size
	return Rect2i(world_start, chunk_size)

# 获取分块中心位置（世界坐标）
func get_chunk_center() -> Vector2:
	var bounds = get_chunk_bounds()
	return Vector2(bounds.position) + Vector2(bounds.size) / 2.0

# 获取高度图值
func get_height_value(local_pos: Vector2i) -> float:
	if is_position_in_chunk(local_pos):
		return heightmap[local_pos.y][local_pos.x]
	return 0.0

# 设置分块可见性
func set_visible(visible: bool):
	if is_visible != visible:
		is_visible = visible
		# 这里可以添加实际的渲染控制逻辑
		# 例如：显示/隐藏TileMap节点、资源节点等
		
		if visible:
			print("分块可见: ", chunk_position)
		else:
			print("分块隐藏: ", chunk_position)

# 序列化分块数据（用于保存/加载）
func serialize() -> Dictionary:
	var data = {
		"chunk_position": {"x": chunk_position.x, "y": chunk_position.y},
		"chunk_size": {"x": chunk_size.x, "y": chunk_size.y},
		"is_loaded": is_loaded,
		"heightmap": heightmap.duplicate(),
		"tile_data": {},
		"resource_nodes": resource_nodes.duplicate()
	}
	
	# 序列化tile_data字典（Vector2i需要特殊处理）
	for pos in tile_data.keys():
		var key = "%d,%d" % [pos.x, pos.y]
		data.tile_data[key] = tile_data[pos]
	
	return data

# 反序列化分块数据
func deserialize(data: Dictionary) -> bool:
	if not data.has("chunk_position") or not data.has("chunk_size"):
		return false
	
	chunk_position = Vector2i(data.chunk_position.x, data.chunk_position.y)
	chunk_size = Vector2i(data.chunk_size.x, data.chunk_size.y)
	
	if data.has("heightmap"):
		heightmap = data.heightmap.duplicate()
	
	if data.has("tile_data"):
		tile_data.clear()
		for key in data.tile_data.keys():
			var parts = key.split(",")
			if parts.size() == 2:
				var pos = Vector2i(int(parts[0]), int(parts[1]))
				tile_data[pos] = data.tile_data[key]
	
	if data.has("resource_nodes"):
		resource_nodes = data.resource_nodes.duplicate()
	
	is_loaded = data.get("is_loaded", false)
	
	return true

# 检查分块是否为空（全水域或无效）
func is_empty() -> bool:
	if not is_loaded:
		return true
	
	# 检查高度图是否全为低值（水域）
	for y in range(chunk_size.y):
		for x in range(chunk_size.x):
			if heightmap[y][x] > 0.3:  # 假设>0.3为陆地
				return false
	
	return true

# 获取分块内陆地单元格数量
func get_land_cell_count() -> int:
	var count = 0
	
	for y in range(chunk_size.y):
		for x in range(chunk_size.x):
			if heightmap[y][x] > 0.3:  # 假设>0.3为陆地
				count += 1
	
	return count

# 获取分块内资源数量
func get_resource_count() -> int:
	return resource_nodes.size()

# 获取分块内特定类型资源数量
func get_resource_count_by_type(resource_type: String) -> int:
	var count = 0
	
	for resource in resource_nodes:
		if resource.get("type") == resource_type:
			count += 1
	
	return count