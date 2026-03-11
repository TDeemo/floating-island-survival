## 怪物生成器
## 根据生态环境和岛屿生成规则在岛屿上分布怪物生成点
class_name MonsterSpawner
extends Node2D

# 生成点配置
class SpawnPoint:
	var position: Vector2
	var monster_type: PackedScene
	var is_active: bool = true
	var respawn_timer: float = 0.0
	var respawn_delay: float = 30.0  # 重生时间（秒）
	
	func _init(pos: Vector2, type: PackedScene, delay: float = 30.0):
		position = pos
		monster_type = type
		respawn_delay = delay

# 导出配置
## 每个生态环境的基础生成点数量
@export var base_spawn_points_per_biome: Dictionary = {
	0: 8,   # FOREST
	1: 6,   # MINE
	2: 10,  # SWAMP
	3: 5,   # SNOWY
	4: 7,   # VOLCANO
	5: 9    # JUNGLE
}
## 难度对生成点数量的影响倍数（每星级）
@export var difficulty_spawn_multiplier: float = 0.2
## 生成点离港口的最小距离（避免怪物堵住撤离点）
@export var min_distance_from_harbor: float = 200.0
## 生成点之间的最小距离
@export var min_distance_between_spawns: float = 100.0
## 是否启用动态生成（根据玩家位置）
@export var enable_dynamic_spawning: bool = true
## 动态生成半径（像素）
@export var dynamic_spawn_radius: float = 600.0
## 动态生成检查间隔（秒）
@export var dynamic_spawn_check_interval: float = 10.0

# 内部变量
var spawn_points: Array[SpawnPoint] = []
var active_monsters: Dictionary = {}  # spawn_point_index -> MonsterBase
var current_biome: int = -1
var current_difficulty: int = 1
var island_size: Vector2 = Vector2(512, 512)
var harbor_position: Vector2 = Vector2.ZERO
var terrain_map: TileMap = null
var player: Node2D = null
var dynamic_spawn_timer: float = 0.0
var monster_manager: MonsterManager = null

# 预设怪物场景（应在外部加载）
var monster_scenes_by_biome: Dictionary = {}  # biome_type -> Array[PackedScene]

func _ready() -> void:
	# 查找相关节点
	player = get_tree().get_first_node_in_group("player")
	terrain_map = get_tree().get_first_node_in_group("terrain_tilemap")
	monster_manager = get_tree().get_first_node_in_group("monster_manager")
	
	# 初始化计时器
	dynamic_spawn_timer = dynamic_spawn_check_interval
	
	print("MonsterSpawner: 初始化完成")

func setup_island(biome_type: int, difficulty: int, size: Vector2, harbor_pos: Vector2) -> void:
	current_biome = biome_type
	current_difficulty = difficulty
	island_size = size
	harbor_position = harbor_pos
	
	# 清空现有生成点和怪物
	_clear_all_spawns()
	
	# 生成新的生成点
	_generate_spawn_points()
	
	print("MonsterSpawner: 设置岛屿 - 生态环境: %d, 难度: %d, 大小: %s, 港口位置: %s" % 
		  [biome_type, difficulty, size, harbor_pos])

func _process(delta: float) -> void:
	# 更新重生计时器
	_update_respawn_timers(delta)
	
	# 动态生成检查
	if enable_dynamic_spawning:
		dynamic_spawn_timer -= delta
		if dynamic_spawn_timer <= 0:
			_dynamic_spawn_check()
			dynamic_spawn_timer = dynamic_spawn_check_interval

func _generate_spawn_points() -> void:
	spawn_points.clear()
	
	# 获取基础生成点数量
	var base_count = base_spawn_points_per_biome.get(current_biome, 5)
	# 根据难度调整
	var total_count = base_count + round(base_count * difficulty_spawn_multiplier * (current_difficulty - 1))
	total_count = int(max(total_count, 3))
	
	# 获取当前生态环境的怪物类型
	var available_monsters = _get_monster_scenes_for_biome(current_biome)
	if available_monsters.size() == 0:
		push_warning("MonsterSpawner: 生态环境 %d 没有可用的怪物场景" % current_biome)
		return
	
	print("MonsterSpawner: 生成 %d 个生成点，可用怪物类型: %d" % [total_count, available_monsters.size()])
	
	# 生成点
	var attempts = 0
	var max_attempts = total_count * 10
	
	while spawn_points.size() < total_count and attempts < max_attempts:
		attempts += 1
		
		# 随机位置
		var pos = Vector2(
			randf_range(50.0, island_size.x - 50.0),
			randf_range(50.0, island_size.y - 50.0)
		)
		
		# 检查离港口的距离
		if harbor_position != Vector2.ZERO:
			if pos.distance_to(harbor_position) < min_distance_from_harbor:
				continue
		
		# 检查离其他生成点的距离
		var too_close = false
		for existing_point in spawn_points:
			if pos.distance_to(existing_point.position) < min_distance_between_spawns:
				too_close = true
				break
		
		if too_close:
			continue
		
		# 检查地形是否适合（如果地形地图存在）
		if terrain_map and not _is_position_valid_for_spawn(pos):
			continue
		
		# 随机选择怪物类型
		var monster_scene = available_monsters[randi() % available_monsters.size()]
		
		# 创建生成点
		var spawn_point = SpawnPoint.new(pos, monster_scene)
		spawn_points.append(spawn_point)
		
		print("MonsterSpawner: 生成点 %d 在位置 %s" % [spawn_points.size(), pos])
	
	if spawn_points.size() < total_count:
		print("MonsterSpawner: 只成功生成 %d/%d 个生成点" % [spawn_points.size(), total_count])

func _get_monster_scenes_for_biome(biome_type: int) -> Array[PackedScene]:
	# 如果已经加载了场景，返回缓存
	if monster_scenes_by_biome.has(biome_type):
		return monster_scenes_by_biome[biome_type]
	
	# 否则根据生态环境加载预设怪物
	var scenes: Array[PackedScene] = []
	
	# 示例：根据生态环境加载不同的怪物
	match biome_type:
		0:  # FOREST - 森林
			# scenes.append(load("res://scenes/monsters/forest_zombie.tscn"))
			# scenes.append(load("res://scenes/monsters/forest_wolf.tscn"))
			pass
		1:  # MINE - 矿山
			# scenes.append(load("res://scenes/monsters/mine_bat.tscn"))
			# scenes.append(load("res://scenes/monsters/rock_golem.tscn"))
			pass
		2:  # SWAMP - 沼泽
			# scenes.append(load("res://scenes/monsters/swamp_zombie.tscn"))
			# scenes.append(load("res://scenes/monsters/poison_frog.tscn"))
			pass
		# 其他生态环境...
	
	# 缓存结果
	monster_scenes_by_biome[biome_type] = scenes
	return scenes

func _is_position_valid_for_spawn(position: Vector2) -> bool:
	if not terrain_map:
		return true
	
	# 获取地形类型（假设地形图块层）
	var cell = terrain_map.local_to_map(position)
	var tile_data = terrain_map.get_cell_tile_data(0, cell)
	
	if not tile_data:
		return false
	
	# 检查是否是可通行的地形（例如不是水域）
	# 这里需要根据实际地形系统实现
	var terrain_type = tile_data.get_custom_data("terrain_type")
	if terrain_type == "water" or terrain_type == "lava":
		return false
	
	return true

func spawn_all_initial_monsters() -> void:
	# 生成所有初始怪物
	for i in range(spawn_points.size()):
		_spawn_at_point(i)

func _spawn_at_point(spawn_index: int) -> void:
	if spawn_index < 0 or spawn_index >= spawn_points.size():
		return
	
	var spawn_point = spawn_points[spawn_index]
	if not spawn_point.is_active:
		return
	
	# 如果该生成点已经有活跃怪物，跳过
	if active_monsters.has(spawn_index):
		var existing_monster = active_monsters[spawn_index]
		if is_instance_valid(existing_monster) and not existing_monster.is_queued_for_deletion():
			return
	
	# 实例化怪物
	var monster_instance = spawn_point.monster_type.instantiate() as MonsterBase
	if not monster_instance:
		push_error("MonsterSpawner: 无法实例化怪物场景")
		return
	
	# 添加到场景
	get_parent().add_child(monster_instance)
	monster_instance.global_position = spawn_point.position
	
	# 设置怪物属性
	monster_instance.associated_biome = current_biome
	
	# 设置巡逻点
	_setup_monster_patrol(monster_instance, spawn_point.position)
	
	# 记录活跃怪物
	active_monsters[spawn_index] = monster_instance
	
	# 连接死亡信号
	monster_instance.monster_died.connect(_on_monster_died_at_point.bind(spawn_index))
	
	print("MonsterSpawner: 在生成点 %d 生成怪物 %s" % [spawn_index, monster_instance.monster_name])

func _setup_monster_patrol(monster: MonsterBase, spawn_position: Vector2) -> void:
	# 生成巡逻点
	var patrol_points: Array[Vector2] = []
	var point_count = randi_range(3, 6)
	
	for i in range(point_count):
		var angle = randf() * TAU
		var distance = randf_range(80.0, 200.0)
		var point = spawn_position + Vector2(cos(angle), sin(angle)) * distance
		
		# 确保在岛屿范围内
		point.x = clamp(point.x, 0, island_size.x)
		point.y = clamp(point.y, 0, island_size.y)
		
		patrol_points.append(point)
	
	monster.set_patrol_points(patrol_points)

func _on_monster_died_at_point(spawn_index: int, monster: MonsterBase) -> void:
	# 从活跃列表中移除
	active_monsters.erase(spawn_index)
	
	# 如果生成点还有效，启动重生计时器
	if spawn_index < spawn_points.size():
		var spawn_point = spawn_points[spawn_index]
		if spawn_point.is_active:
			spawn_point.respawn_timer = spawn_point.respawn_delay
	
	print("MonsterSpawner: 生成点 %d 的怪物死亡，重生计时器启动" % spawn_index)

func _update_respawn_timers(delta: float) -> void:
	for i in range(spawn_points.size()):
		var spawn_point = spawn_points[i]
		if spawn_point.respawn_timer > 0:
			spawn_point.respawn_timer -= delta
			if spawn_point.respawn_timer <= 0:
				# 重生怪物
				_spawn_at_point(i)
				spawn_point.respawn_timer = 0

func _dynamic_spawn_check() -> void:
	if not player or not enable_dynamic_spawning:
		return
	
	# 检查玩家附近的生成点
	for i in range(spawn_points.size()):
		var spawn_point = spawn_points[i]
		var distance_to_player = spawn_point.position.distance_to(player.global_position)
		
		# 如果玩家在生成点附近且该生成点没有活跃怪物，生成怪物
		if distance_to_player <= dynamic_spawn_radius and not active_monsters.has(i):
			if spawn_point.is_active:
				_spawn_at_point(i)

func get_spawn_point_count() -> int:
	return spawn_points.size()

func get_active_monster_count() -> int:
	return active_monsters.size()

func get_spawn_point_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for point in spawn_points:
		positions.append(point.position)
	return positions

func toggle_spawn_point(index: int, active: bool) -> void:
	if index >= 0 and index < spawn_points.size():
		spawn_points[index].is_active = active
		
		# 如果设置为非活跃且该点有怪物，移除怪物
		if not active and active_monsters.has(index):
			var monster = active_monsters[index]
			if is_instance_valid(monster):
				monster.queue_free()
			active_monsters.erase(index)

func _clear_all_spawns() -> void:
	# 移除所有怪物
	for monster in active_monsters.values():
		if is_instance_valid(monster):
			monster.queue_free()
	
	active_monsters.clear()
	spawn_points.clear()

func set_monster_scenes_for_biome(biome_type: int, scenes: Array[PackedScene]) -> void:
	# 允许外部设置怪物场景
	monster_scenes_by_biome[biome_type] = scenes
	print("MonsterSpawner: 为生态环境 %d 设置 %d 种怪物场景" % [biome_type, scenes.size()])