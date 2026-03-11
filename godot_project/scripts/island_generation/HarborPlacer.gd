# HarborPlacer.gd
# 港口生成逻辑，负责在岛屿边缘寻找合适的港口位置

extends Node

# 港口生成参数
@export var min_land_neighbors: int = 3  # 最少陆地邻居数量
@export var max_water_neighbors: int = 5  # 最多水域邻居数量
@export var require_coastal: bool = true  # 必须邻水

# 生成港口位置
func find_harbor_position(heightmap: Array, tile_type_func: Callable, width: int, height: int) -> Vector2i:
	"""
	在岛屿上寻找合适的港口位置
	
	参数:
		heightmap: 二维数组，每个元素是噪声值
		tile_type_func: 函数，接收噪声值返回图块类型字符串
		width, height: 地图尺寸
	
	返回:
		港口位置（Vector2i），如未找到返回 Vector2i(-1, -1)
	"""
	var candidate_positions = []
	
	# 第一轮扫描：寻找边缘草地图块
	for y in range(height):
		for x in range(width):
			# 只检查边缘区域（距离边界3格以内）
			if x > 3 and x < width - 4 and y > 3 and y < height - 4:
				continue
			
			var noise_value = heightmap[y][x]
			var tile_type = tile_type_func.call(noise_value)
			
			# 只考虑草地图块（适合建造）
			if tile_type != "grass":
				continue
			
			# 检查邻居条件
			if check_harbor_conditions(x, y, heightmap, tile_type_func, width, height):
				candidate_positions.append(Vector2i(x, y))
	
	# 如果没有找到符合条件的草地图块，放宽条件
	if candidate_positions.size() == 0:
		# 第二轮扫描：考虑森林图块
		for y in range(height):
			for x in range(width):
				if x > 3 and x < width - 4 and y > 3 and y < height - 4:
					continue
				
				var noise_value = heightmap[y][x]
				var tile_type = tile_type_func.call(noise_value)
				
				if tile_type != "forest":
					continue
				
				if check_harbor_conditions(x, y, heightmap, tile_type_func, width, height):
					candidate_positions.append(Vector2i(x, y))
	
	# 选择最佳位置
	if candidate_positions.size() > 0:
		return select_best_harbor_position(candidate_positions, heightmap, tile_type_func, width, height)
	
	return Vector2i(-1, -1)

# 检查港口位置条件
func check_harbor_conditions(x: int, y: int, heightmap: Array, tile_type_func: Callable, width: int, height: int) -> bool:
	var land_neighbors = 0
	var water_neighbors = 0
	
	# 检查8方向邻居
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue  # 跳过自身
			
			var nx = x + dx
			var ny = y + dy
			
			if nx >= 0 and nx < width and ny >= 0 and ny < height:
				var neighbor_noise = heightmap[ny][nx]
				var neighbor_type = tile_type_func.call(neighbor_noise)
				
				if neighbor_type == "water":
					water_neighbors += 1
				else:
					land_neighbors += 1
	
	# 必须满足最少陆地邻居条件
	if land_neighbors < min_land_neighbors:
		return false
	
	# 如果要求沿海，必须至少有一个水域邻居
	if require_coastal and water_neighbors == 0:
		return false
	
	# 水域邻居不能太多（避免孤立小岛）
	if water_neighbors > max_water_neighbors:
		return false
	
	# 检查是否有足够的空地（3x3区域）
	if not has_enough_space(x, y, heightmap, tile_type_func, width, height):
		return false
	
	return true

# 检查3x3区域是否有足够空地
func has_enough_space(center_x: int, center_y: int, heightmap: Array, tile_type_func: Callable, width: int, height: int) -> bool:
	var passable_tiles = ["grass", "forest"]
	
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var x = center_x + dx
			var y = center_y + dy
			
			if x < 0 or x >= width or y < 0 or y >= height:
				return false  # 超出边界，空间不足
			
			var noise_value = heightmap[y][x]
			var tile_type = tile_type_func.call(noise_value)
			
			if not (tile_type in passable_tiles):
				return false  # 有不可通行图块
	
	return true

# 从候选位置中选择最佳港口位置
func select_best_harbor_position(candidates: Array, heightmap: Array, tile_type_func: Callable, width: int, height: int) -> Vector2i:
	# 简单的选择策略：选择最靠近地图中心且沿海的位置
	
	var best_position = candidates[0]
	var best_score = -9999.0
	
	var center_x = width / 2.0
	var center_y = height / 2.0
	
	for pos in candidates:
		var score = 0.0
		
		# 距离中心越近，分数越高
		var distance_to_center = Vector2(pos.x - center_x, pos.y - center_y).length()
		score += 100.0 / (distance_to_center + 1.0)
		
		# 水域邻居数量适中（3-5个）分数高
		var water_neighbors = count_water_neighbors(pos.x, pos.y, heightmap, tile_type_func, width, height)
		if water_neighbors >= 3 and water_neighbors <= 5:
			score += 50.0
		elif water_neighbors > 0:
			score += 20.0
		
		# 陆地邻居多分数高
		var land_neighbors = count_land_neighbors(pos.x, pos.y, heightmap, tile_type_func, width, height)
		score += land_neighbors * 5.0
		
		if score > best_score:
			best_score = score
			best_position = pos
	
	return best_position

# 计算水域邻居数量
func count_water_neighbors(x: int, y: int, heightmap: Array, tile_type_func: Callable, width: int, height: int) -> int:
	var count = 0
	
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			
			var nx = x + dx
			var ny = y + dy
			
			if nx >= 0 and nx < width and ny >= 0 and ny < height:
				var neighbor_noise = heightmap[ny][nx]
				var neighbor_type = tile_type_func.call(neighbor_noise)
				
				if neighbor_type == "water":
					count += 1
	
	return count

# 计算陆地邻居数量
func count_land_neighbors(x: int, y: int, heightmap: Array, tile_type_func: Callable, width: int, height: int) -> int:
	var count = 0
	
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			
			var nx = x + dx
			var ny = y + dy
			
			if nx >= 0 and nx < width and ny >= 0 and ny < height:
				var neighbor_noise = heightmap[ny][nx]
				var neighbor_type = tile_type_func.call(neighbor_noise)
				
				if neighbor_type != "water":
					count += 1
	
	return count

# 计算港口朝向（面向水域的方向）
func calculate_harbor_orientation(x: int, y: int, heightmap: Array, tile_type_func: Callable, width: int, height: int) -> float:
	"""
	计算港口朝向（弧度）
	
	返回:
		港口朝向弧度，0表示向右（东），PI/2表示向下（南），以此类推
	"""
	# 计算水域邻居的平均方向
	var water_direction = Vector2.ZERO
	
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			
			var nx = x + dx
			var ny = y + dy
			
			if nx >= 0 and nx < width and ny >= 0 and ny < height:
				var neighbor_noise = heightmap[ny][nx]
				var neighbor_type = tile_type_func.call(neighbor_noise)
				
				if neighbor_type == "water":
					water_direction += Vector2(dx, dy)
	
	# 如果没有水域邻居，默认朝向右（东）
	if water_direction == Vector2.ZERO:
		return 0.0
	
	# 计算角度（Godot坐标系：Y轴向下）
	var angle = water_direction.angle()
	
	# 调整角度，使港口面向水域
	angle += PI  # 反转方向，面向水域
	
	# 标准化到 [0, 2PI)
	while angle < 0:
		angle += 2 * PI
	while angle >= 2 * PI:
		angle -= 2 * PI
	
	return angle