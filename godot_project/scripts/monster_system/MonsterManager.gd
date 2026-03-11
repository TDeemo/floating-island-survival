## 怪物管理器
## 负责怪物的生成、生命周期管理和场景中的怪物总数控制
class_name MonsterManager
extends Node

# 怪物生成配置
class MonsterSpawnConfig:
	var monster_scene: PackedScene
	var biome_type: int  # BiomeManager.BiomeType
	var spawn_weight: float = 1.0
	var min_difficulty: int = 1  # 难度星级
	var max_difficulty: int = 5
	var max_count_per_island: int = 5
	var spawn_radius: float = 100.0  # 生成半径（离玩家初始点）
	
	func _init(p_scene: PackedScene, p_biome: int, p_weight: float = 1.0,
			  p_min_diff: int = 1, p_max_diff: int = 5, p_max_count: int = 5):
		monster_scene = p_scene
		biome_type = p_biome
		spawn_weight = p_weight
		min_difficulty = p_min_diff
		max_difficulty = p_max_count
		max_count_per_island = p_max_count

# 导出变量
## 最大同时存在的怪物数量
@export var max_monsters_on_screen: int = 20
## 生成检查间隔（秒）
@export var spawn_check_interval: float = 5.0
## 生成点离玩家的最小安全距离
@export var min_spawn_distance_from_player: float = 150.0
## 生成点离玩家的最大距离
@export var max_spawn_distance_from_player: float = 500.0

# 内部变量
var spawn_configs: Array[MonsterSpawnConfig] = []
var active_monsters: Array[MonsterBase] = []
var dead_monsters: Array[MonsterBase] = []
var spawn_timer: float = 0.0
var current_biome: int = -1
var current_difficulty: int = 1
var island_size: Vector2 = Vector2(512, 512)  # 默认岛屿大小

# 引用
var player: Node2D = null
var biome_manager: Node = null
var navigation_map: RID  # 用于路径查找（如果使用Navigation2D）

func _ready() -> void:
	# 查找玩家
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("MonsterManager: 未找到玩家节点")
	
	# 查找BiomeManager
	biome_manager = get_tree().get_first_node_in_group("biome_manager")
	if not biome_manager:
		push_warning("MonsterManager: 未找到BiomeManager节点")
	
	# 初始化生成配置（应在外部调用setup_spawn_configs配置）
	spawn_timer = spawn_check_interval

func _process(delta: float) -> void:
	# 更新生成计时器
	spawn_timer -= delta
	if spawn_timer <= 0:
		_spawn_check()
		spawn_timer = spawn_check_interval
	
	# 清理已死亡的怪物
	_cleanup_dead_monsters()

func setup_spawn_configs() -> void:
	# 清空现有配置
	spawn_configs.clear()
	
	# 这里应该根据实际怪物预制体进行配置
	# 示例：森林生态环境的怪物
	# var forest_zombie_scene = load("res://scenes/monsters/forest_zombie.tscn")
	# spawn_configs.append(MonsterSpawnConfig.new(
	# 	forest_zombie_scene, 
	# 	BiomeManager.BiomeType.FOREST,
	# 	0.7, 1, 3, 10
	# ))
	
	# 这是一个模板，实际使用时需要加载真实资源
	print("MonsterManager: 需要设置实际的生成配置")

func set_island_parameters(biome_type: int, difficulty: int, size: Vector2) -> void:
	current_biome = biome_type
	current_difficulty = difficulty
	island_size = size
	
	print("MonsterManager: 设置岛屿参数 - 生态环境: %d, 难度: %d, 大小: %s" % [biome_type, difficulty, size])

func _spawn_check() -> void:
	# 检查是否满足生成条件
	if not player:
		return
	
	if active_monsters.size() >= max_monsters_on_screen:
		return
	
	# 获取当前生态环境的生成配置
	var valid_configs = _get_valid_spawn_configs()
	if valid_configs.size() == 0:
		return
	
	# 计算需要生成的怪物数量
	var desired_count = _calculate_desired_monster_count()
	var current_count = active_monsters.size()
	var to_spawn = max(0, desired_count - current_count)
	
	# 限制一次生成的数量
	to_spawn = min(to_spawn, 3)
	
	# 生成怪物
	for i in range(to_spawn):
		_spawn_monster(valid_configs)

func _get_valid_spawn_configs() -> Array[MonsterSpawnConfig]:
	var result: Array[MonsterSpawnConfig] = []
	
	for config in spawn_configs:
		# 检查生态环境匹配
		if config.biome_type != current_biome:
			continue
		
		# 检查难度范围
		if current_difficulty < config.min_difficulty or current_difficulty > config.max_difficulty:
			continue
		
		# 检查当前岛屿上该类型怪物的数量
		var count = _count_monsters_of_type(config.monster_scene)
		if count >= config.max_count_per_island:
			continue
		
		result.append(config)
	
	return result

func _count_monsters_of_type(scene: PackedScene) -> int:
	var count = 0
	for monster in active_monsters:
		if is_instance_valid(monster) and monster.scene_file_path == scene.resource_path:
			count += 1
	return count

func _calculate_desired_monster_count() -> int:
	# 基础数量 + 难度加成 + 时间加成（夜晚更多）
	var base_count = 5
	var difficulty_bonus = (current_difficulty - 1) * 2
	
	# 检查是否是夜晚（需要时间系统集成）
	var is_night = false  # 暂时假设为false
	var night_bonus = 5 if is_night else 0
	
	return base_count + difficulty_bonus + night_bonus

func _spawn_monster(valid_configs: Array[MonsterSpawnConfig]) -> void:
	if valid_configs.size() == 0:
		return
	
	# 根据权重随机选择生成配置
	var total_weight = 0.0
	for config in valid_configs:
		total_weight += config.spawn_weight
	
	var random_value = randf() * total_weight
	var current_weight = 0.0
	var selected_config: MonsterSpawnConfig = null
	
	for config in valid_configs:
		current_weight += config.spawn_weight
		if random_value <= current_weight:
			selected_config = config
			break
	
	if not selected_config:
		selected_config = valid_configs[0]
	
	# 计算生成位置
	var spawn_position = _calculate_spawn_position(selected_config)
	if spawn_position == Vector2.ZERO:
		return
	
	# 实例化怪物
	var monster_instance = selected_config.monster_scene.instantiate() as MonsterBase
	if not monster_instance:
		push_error("MonsterManager: 无法实例化怪物场景")
		return
	
	# 添加到场景
	get_parent().add_child(monster_instance)
	monster_instance.global_position = spawn_position
	
	# 设置怪物属性
	monster_instance.associated_biome = current_biome
	
	# 设置巡逻点（如果适用）
	_setup_monster_patrol(monster_instance, spawn_position)
	
	# 添加到活跃列表
	active_monsters.append(monster_instance)
	
	# 连接信号
	monster_instance.monster_died.connect(_on_monster_died.bind(monster_instance))
	
	print("MonsterManager: 生成怪物 %s 在位置 %s" % [monster_instance.monster_name, spawn_position])

func _calculate_spawn_position(config: MonsterSpawnConfig) -> Vector2:
	if not player:
		return Vector2.ZERO
	
	# 随机角度
	var angle = randf() * TAU
	# 随机距离（在最小和最大距离之间）
	var distance = randf_range(min_spawn_distance_from_player, max_spawn_distance_from_player)
	
	# 计算相对于玩家的位置
	var offset = Vector2(cos(angle), sin(angle)) * distance
	var spawn_pos = player.global_position + offset
	
	# 确保位置在岛屿范围内
	spawn_pos.x = clamp(spawn_pos.x, 0, island_size.x)
	spawn_pos.y = clamp(spawn_pos.y, 0, island_size.y)
	
	# 检查位置是否有效（例如不在水中）
	# 这里需要地形系统集成
	# var terrain_type = terrain_system.get_terrain_at(spawn_pos)
	# if terrain_type == "water":
	# 	return _calculate_spawn_position(config)  # 递归重试
	
	return spawn_pos

func _setup_monster_patrol(monster: MonsterBase, spawn_position: Vector2) -> void:
	# 为怪物设置巡逻点
	var patrol_points: Array[Vector2] = []
	
	# 生成3-5个巡逻点
	var point_count = randi_range(3, 5)
	for i in range(point_count):
		# 在生成点周围随机位置
		var angle = randf() * TAU
		var distance = randf_range(50.0, 150.0)
		var point = spawn_position + Vector2(cos(angle), sin(angle)) * distance
		
		# 确保在岛屿范围内
		point.x = clamp(point.x, 0, island_size.x)
		point.y = clamp(point.y, 0, island_size.y)
		
		patrol_points.append(point)
	
	monster.set_patrol_points(patrol_points)

func _on_monster_died(monster: MonsterBase) -> void:
	# 从活跃列表移到死亡列表
	var index = active_monsters.find(monster)
	if index != -1:
		active_monsters.remove_at(index)
		dead_monsters.append(monster)
	
	print("MonsterManager: 怪物死亡 %s" % monster.monster_name)

func _cleanup_dead_monsters() -> void:
	# 清理已经队列释放的怪物
	var to_remove: Array[int] = []
	
	for i in range(dead_monsters.size() - 1, -1, -1):
		var monster = dead_monsters[i]
		if not is_instance_valid(monster) or monster.is_queued_for_deletion():
			dead_monsters.remove_at(i)

func get_active_monster_count() -> int:
	return active_monsters.size()

func get_dead_monster_count() -> int:
	return dead_monsters.size()

func get_total_monster_count() -> int:
	return active_monsters.size() + dead_monsters.size()

func clear_all_monsters() -> void:
	# 移除所有怪物
	for monster in active_monsters:
		if is_instance_valid(monster):
			monster.queue_free()
	
	for monster in dead_monsters:
		if is_instance_valid(monster) and not monster.is_queued_for_deletion():
			monster.queue_free()
	
	active_monsters.clear()
	dead_monsters.clear()

func spawn_specific_monster(scene: PackedScene, position: Vector2) -> MonsterBase:
	# 直接生成指定类型的怪物
	var monster_instance = scene.instantiate() as MonsterBase
	if not monster_instance:
		push_error("MonsterManager: 无法实例化指定怪物场景")
		return null
	
	get_parent().add_child(monster_instance)
	monster_instance.global_position = position
	monster_instance.associated_biome = current_biome
	
	active_monsters.append(monster_instance)
	monster_instance.monster_died.connect(_on_monster_died.bind(monster_instance))
	
	return monster_instance