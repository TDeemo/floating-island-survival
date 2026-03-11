## 全局光照管理器
## 管理场景中所有光源，处理多光源叠加、怪物吸引机制、夜间视野限制
class_name LightManager
extends Node

# 导出配置
## 是否启用全局光照管理
@export var enabled: bool = true
## 最大同时处理的光源数量（性能优化）
@export var max_lights_processed: int = 20
## 怪物吸引检测间隔（秒）
@export var monster_detection_interval: float = 1.0
## 是否启用夜间视野限制
@export var enable_night_vision_restriction: bool = true
## 基础夜间视野范围（无光源时）
@export var base_night_vision_range: float = 100.0

# 内部数据结构
var _all_lights: Array[LightSource] = []
var _active_lights: Array[LightSource] = []
var _light_by_id: Dictionary = {}  # id -> LightSource
var _next_light_id: int = 1

# 怪物吸引相关
var _monster_detection_timer: float = 0.0
var _monsters_in_scene: Array[Node] = []
var _monster_attraction_map: Dictionary = {}  # monster -> {light: attraction_strength}

# 夜间视野系统
var _night_vision_system: NightVisionSystem = null
var _time_manager: TimeManager = null

# 信号定义
## 光源注册/注销
signal light_registered(light: LightSource, light_id: int)
signal light_unregistered(light: LightSource, light_id: int)
## 怪物吸引状态更新
signal monster_attracted(monster: Node, light: LightSource, strength: float)
signal monster_released(monster: Node, light: LightSource)
## 全局光照变化（例如进入/离开黑暗区域）
signal global_lighting_changed(is_dark: bool, player_has_light: bool)

func _ready() -> void:
	# 查找依赖系统
	_find_dependencies()
	
	# 初始化夜间视野系统（如果启用）
	if enable_night_vision_restriction:
		_setup_night_vision_system()
	
	# 初始化计时器
	_monster_detection_timer = monster_detection_interval

## 查找依赖系统
func _find_dependencies() -> void:
	var root = get_tree().root
	
	# 查找TimeManager
	for node in root.get_children():
		if node is TimeManager:
			_time_manager = node as TimeManager
			break
	
	# 查找现有怪物
	_update_monster_list()

func _process(delta: float) -> void:
	if not enabled:
		return
	
	# 更新怪物检测计时器
	_monster_detection_timer -= delta
	if _monster_detection_timer <= 0:
		_update_monster_attraction()
		_monster_detection_timer = monster_detection_interval
	
	# 更新夜间视野系统
	if _night_vision_system:
		_night_vision_system.process(delta)
	
	# 更新活动光源列表
	_update_active_lights()

## 注册光源
func register_light(light: LightSource) -> int:
	if not light:
		push_error("尝试注册空光源")
		return -1
	
	# 检查是否已注册
	for existing in _all_lights:
		if existing == light:
			push_warning("光源已注册")
			return _get_light_id(light)
	
	# 分配ID并注册
	var light_id = _next_light_id
	_next_light_id += 1
	
	_all_lights.append(light)
	_light_by_id[light_id] = light
	
	# 连接信号
	_connect_light_signals(light)
	
	# 立即更新活动状态
	if light.enabled:
		_active_lights.append(light)
	
	light_registered.emit(light, light_id)
	print("光源注册: ID=%d, 位置=%s" % [light_id, light.global_position])
	
	return light_id

## 注销光源
func unregister_light(light: LightSource) -> void:
	if not light:
		return
	
	# 从所有列表中移除
	_all_lights.erase(light)
	_active_lights.erase(light)
	
	# 查找并移除ID
	var light_id = _get_light_id(light)
	if light_id != -1:
		_light_by_id.erase(light_id)
	
	# 断开信号连接
	_disconnect_light_signals(light)
	
	# 释放所有被此光源吸引的怪物
	_release_monsters_from_light(light)
	
	light_unregistered.emit(light, light_id)
	print("光源注销: ID=%d" % light_id)

## 获取光源ID
func _get_light_id(light: LightSource) -> int:
	for id in _light_by_id:
		if _light_by_id[id] == light:
			return id
	return -1

## 连接光源信号
func _connect_light_signals(light: LightSource) -> void:
	if not light:
		return
	
	if light.has_signal("light_toggled"):
		light.light_toggled.connect(_on_light_toggled.bind(light))
	
	if light.has_signal("monster_attraction_changed"):
		light.monster_attraction_changed.connect(_on_monster_attraction_changed.bind(light))

## 断开光源信号连接
func _disconnect_light_signals(light: LightSource) -> void:
	if not light or not is_instance_valid(light):
		return
	
	# Godot 4 自动断开连接，但为确保安全可以手动处理
	pass

## 光源开关状态变化处理
func _on_light_toggled(is_enabled: bool, light: LightSource) -> void:
	if not light:
		return
	
	if is_enabled:
		if not _active_lights.has(light):
			_active_lights.append(light)
	else:
		_active_lights.erase(light)
		# 释放被此光源吸引的怪物
		_release_monsters_from_light(light)

## 怪物吸引状态变化处理
func _on_monster_attraction_changed(is_attracting: bool, light: LightSource) -> void:
	if not is_attracting:
		# 停止吸引，释放怪物
		_release_monsters_from_light(light)

## 更新活动光源列表
func _update_active_lights() -> void:
	# 移除无效或禁用光源
	var to_remove: Array[LightSource] = []
	for light in _active_lights:
		if not is_instance_valid(light) or not light.enabled:
			to_remove.append(light)
	
	for light in to_remove:
		_active_lights.erase(light)

## 更新怪物列表
func _update_monster_list() -> void:
	_monsters_in_scene.clear()
	
	# 查找所有MonsterBase节点
	var root = get_tree().root
	var all_monsters = _find_nodes_by_class(root, "MonsterBase")
	
	for monster in all_monsters:
		if is_instance_valid(monster):
			_monsters_in_scene.append(monster)
	
	print("发现怪物数量: %d" % _monsters_in_scene.size())

## 递归查找特定类节点
func _find_nodes_by_class(root: Node, class_name: String) -> Array[Node]:
	var result: Array[Node] = []
	
	if root.get_class() == class_name:
		result.append(root)
	
	for child in root.get_children():
		result.append_array(_find_nodes_by_class(child, class_name))
	
	return result

## 更新怪物吸引逻辑
func _update_monster_attraction() -> void:
	if not enabled or _active_lights.is_empty():
		return
	
	# 清空当前吸引映射
	var new_attraction_map: Dictionary = {}
	
	# 对每个怪物，计算最近的有效光源
	for monster in _monsters_in_scene:
		if not is_instance_valid(monster):
			continue
		
		var best_light: LightSource = null
		var best_strength: float = 0.0
		var best_distance: float = INF
		
		# 查找范围内最吸引人的光源
		for light in _active_lights:
			if not light or not light.enabled or not light.attract_monsters:
				continue
			
			# 计算距离
			var distance = monster.global_position.distance_to(light.global_position)
			var attraction_range = light.get_attraction_range()
			
			if distance <= attraction_range:
				# 计算吸引强度（距离越近强度越高）
				var strength = light.get_attraction_strength() * (1.0 - distance / attraction_range)
				
				if strength > best_strength:
					best_strength = strength
					best_light = light
					best_distance = distance
		
		# 如果找到有效光源，记录吸引关系
		if best_light and best_strength > 0:
			if not new_attraction_map.has(monster):
				new_attraction_map[monster] = {}
			
			new_attraction_map[monster][best_light] = best_strength
			
			# 触发吸引信号
			monster_attracted.emit(monster, best_light, best_strength)
			
			# 应用吸引效果到怪物（调用怪物AI方法）
			_apply_attraction_to_monster(monster, best_light, best_strength, best_distance)
	
	# 处理不再被吸引的怪物
	_process_released_monsters(new_attraction_map)
	
	# 更新映射
	_monster_attraction_map = new_attraction_map

## 应用吸引效果到怪物
func _apply_attraction_to_monster(monster: Node, light: LightSource, strength: float, distance: float) -> void:
	if not monster or not light:
		return
	
	# 尝试调用怪物的被吸引方法
	if monster.has_method("set_attracted_to_light"):
		monster.set_attracted_to_light.call(light.global_position, strength, distance)
	elif monster.has_method("set_target_position"):
		# 通用方法：设置目标位置为光源位置
		monster.set_target_position.call(light.global_position)

## 处理不再被吸引的怪物
func _process_released_monsters(new_map: Dictionary) -> void:
	# 查找之前被吸引但新映射中没有的怪物
	for monster in _monster_attraction_map:
		if not new_map.has(monster):
			# 释放这个怪物
			var old_lights = _monster_attraction_map[monster]
			for light in old_lights:
				monster_released.emit(monster, light)
				
				# 清除怪物的吸引状态
				if monster.has_method("clear_light_attraction"):
					monster.clear_light_attraction.call()
				elif monster.has_method("clear_target"):
					monster.clear_target.call()

## 释放光源吸引的所有怪物
func _release_monsters_from_light(light: LightSource) -> void:
	if not light:
		return
	
	# 遍历当前映射，移除与该光源相关的条目
	var monsters_to_release: Array[Node] = []
	
	for monster in _monster_attraction_map:
		var lights = _monster_attraction_map[monster]
		if lights.has(light):
			monsters_to_release.append(monster)
			monster_released.emit(monster, light)
			
			# 清除怪物的吸引状态
			if monster.has_method("clear_light_attraction"):
				monster.clear_light_attraction.call()
	
	# 从映射中移除
	for monster in monsters_to_release:
		var lights = _monster_attraction_map[monster]
		lights.erase(light)
		if lights.is_empty():
			_monster_attraction_map.erase(monster)

## 设置夜间视野系统
func _setup_night_vision_system() -> void:
	if not _night_vision_system:
		_night_vision_system = NightVisionSystem.new()
		_night_vision_system.base_vision_range = base_night_vision_range
		
		# 连接到玩家和光源变化
		global_lighting_changed.connect(_night_vision_system._on_global_lighting_changed)
		
		add_child(_night_vision_system)
		print("夜间视野系统已初始化")

## 获取所有光源信息
func get_light_info() -> Dictionary:
	return {
		"total_lights": _all_lights.size(),
		"active_lights": _active_lights.size(),
		"monsters_attracted": _monster_attraction_map.size()
	}

## 查找玩家附近的光源
func get_lights_near_player(player_position: Vector2, max_distance: float = 500.0) -> Array[LightSource]:
	var nearby_lights: Array[LightSource] = []
	
	for light in _active_lights:
		if not light or not light.enabled:
			continue
		
		var distance = player_position.distance_to(light.global_position)
		if distance <= max_distance:
			nearby_lights.append(light)
	
	return nearby_lights

## 检查玩家是否有有效光源
func player_has_light(player_position: Vector2) -> bool:
	var nearby_lights = get_lights_near_player(player_position, 300.0)
	return not nearby_lights.is_empty()

## 强制更新怪物列表（可由其他系统调用）
func refresh_monster_list() -> void:
	_update_monster_list()

## 启用/禁用怪物吸引
func set_monster_attraction_enabled(enabled: bool) -> void:
	if not enabled:
		# 立即释放所有被吸引的怪物
		_clear_all_attractions()
	
	# 更新后续处理
	pass

## 清除所有吸引关系
func _clear_all_attractions() -> void:
	for monster in _monster_attraction_map:
		var lights = _monster_attraction_map[monster]
		for light in lights:
			monster_released.emit(monster, light)
	
	_monster_attraction_map.clear()