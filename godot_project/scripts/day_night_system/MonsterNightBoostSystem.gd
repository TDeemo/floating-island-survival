## 怪物夜晚强化系统
## 在夜晚阶段提升怪物属性（攻击力、移动速度、追逐范围等）
class_name MonsterNightBoostSystem
extends Node

# 导出变量 - 可在编辑器中配置
## 是否启用夜晚强化
@export var enabled: bool = true
## 怪物组名（用于查找场景中的怪物）
@export var monster_group_name: String = "monsters"
## 夜晚攻击力倍率（基础值的倍数）
@export var night_attack_multiplier: float = 1.5  # +50%
## 夜晚移动速度倍率
@export var night_speed_multiplier: float = 1.2  # +20%
## 夜晚追逐范围倍率
@export var night_chase_range_multiplier: float = 2.0  # +100%
## 夜晚视野范围倍率
@export var night_sight_range_multiplier: float = 1.5  # +50%
## 是否在黄昏阶段开始部分增强（渐进过渡）
@export var progressive_enhancement: bool = true
## 黄昏阶段增强比例（0-1，1表示完全夜晚增强）
@export var dusk_enhancement_ratio: float = 0.5

# 内部变量
var _time_manager: TimeManager = null
var _current_phase: TimeManager.DayPhase = TimeManager.DayPhase.DAY
var _is_night_boost_active: bool = false
var _night_boost_multiplier: float = 1.0  # 当前实际应用的倍率（渐进过渡）

# 怪物数据缓存：存储每个怪物的原始属性
class MonsterData:
	var node: Node
	var original_attack: float = 0.0
	var original_speed: float = 0.0
	var original_chase_range: float = 0.0
	var original_sight_range: float = 0.0

var _monster_data_map: Dictionary = {}  # 键：怪物实例ID，值：MonsterData

func _ready() -> void:
	# 获取TimeManager
	_time_manager = _find_time_manager()
	if not _time_manager:
		push_warning("MonsterNightBoostSystem: 无法找到TimeManager，夜晚强化将无法工作")
		return
	
	# 连接信号
	_time_manager.day_phase_changed.connect(_on_day_phase_changed)
	
	# 初始化当前阶段
	_current_phase = _time_manager.get_current_phase()
	_update_night_boost_state()

# 查找TimeManager节点
func _find_time_manager() -> TimeManager:
	# 方法1：通过全局单例（如果TimeManager注册为单例）
	if Engine.has_singleton("TimeManager"):
		return Engine.get_singleton("TimeManager")
	
	# 方法2：通过组查找
	var nodes = get_tree().get_nodes_in_group("time_manager")
	if nodes.size() > 0:
		return nodes[0] as TimeManager
	
	# 方法3：在根节点下查找
	var root = get_tree().root
	for child in root.get_children():
		if child is TimeManager:
			return child
	
	return null

# 注册怪物（应在怪物_ready时调用）
func register_monster(monster_node: Node, base_attack: float, base_speed: float, base_chase_range: float, base_sight_range: float) -> void:
	if not enabled:
		return
	
	var monster_data = MonsterData.new()
	monster_data.node = monster_node
	monster_data.original_attack = base_attack
	monster_data.original_speed = base_speed
	monster_data.original_chase_range = base_chase_range
	monster_data.original_sight_range = base_sight_range
	
	_monster_data_map[monster_node.get_instance_id()] = monster_data
	
	# 如果当前已激活夜晚强化，立即应用
	if _is_night_boost_active:
		_apply_night_boost_to_monster(monster_data, _night_boost_multiplier)

# 注销怪物（应在怪物退出场景时调用）
func unregister_monster(monster_node: Node) -> void:
	var instance_id = monster_node.get_instance_id()
	if _monster_data_map.has(instance_id):
		# 如果当前有夜晚强化，先恢复原始属性（尽管怪物将被销毁）
		if _is_night_boost_active:
			var monster_data = _monster_data_map[instance_id]
			_remove_night_boost_from_monster(monster_data)
		
		_monster_data_map.erase(instance_id)

# 更新夜晚强化状态
func _update_night_boost_state() -> void:
	if not enabled:
		return
	
	var should_be_active = false
	var multiplier = 1.0
	
	match _current_phase:
		TimeManager.DayPhase.NIGHT:
			should_be_active = true
			multiplier = 1.0  # 完全夜晚强化
		TimeManager.DayPhase.DUSK:
			if progressive_enhancement:
				should_be_active = true
				multiplier = dusk_enhancement_ratio  # 黄昏部分强化
			else:
				should_be_active = false
		_:
			should_be_active = false
	
	if should_be_active != _is_night_boost_active or (_is_night_boost_active and multiplier != _night_boost_multiplier):
		_is_night_boost_active = should_be_active
		_night_boost_multiplier = multiplier
		
		if _is_night_boost_active:
			_apply_night_boost_to_all_monsters(_night_boost_multiplier)
		else:
			_remove_night_boost_from_all_monsters()

# 应用夜晚强化到单个怪物
func _apply_night_boost_to_monster(monster_data: MonsterData, multiplier: float) -> void:
	var monster = monster_data.node
	
	# 应用属性倍率
	var attack_boost = monster_data.original_attack * (night_attack_multiplier - 1.0) * multiplier
	var speed_boost = monster_data.original_speed * (night_speed_multiplier - 1.0) * multiplier
	var chase_range_boost = monster_data.original_chase_range * (night_chase_range_multiplier - 1.0) * multiplier
	var sight_range_boost = monster_data.original_sight_range * (night_sight_range_multiplier - 1.0) * multiplier
	
	# 设置提升后的属性
	# 这里假设怪物有相应的属性或方法，实际实现需要根据怪物脚本调整
	# 例如，如果怪物有MonsterBase脚本，可以通过setter方法
	if monster.has_method("set_attack"):
		monster.call("set_attack", monster_data.original_attack + attack_boost)
	
	if monster.has_method("set_move_speed"):
		monster.call("set_move_speed", monster_data.original_speed + speed_boost)
	
	if monster.has_method("set_chase_range"):
		monster.call("set_chase_range", monster_data.original_chase_range + chase_range_boost)
	
	if monster.has_method("set_sight_range"):
		monster.call("set_sight_range", monster_data.original_sight_range + sight_range_boost)

# 移除单个怪物的夜晚强化
func _remove_night_boost_from_monster(monster_data: MonsterData) -> void:
	var monster = monster_data.node
	
	# 恢复原始属性
	if monster.has_method("set_attack"):
		monster.call("set_attack", monster_data.original_attack)
	
	if monster.has_method("set_move_speed"):
		monster.call("set_move_speed", monster_data.original_speed)
	
	if monster.has_method("set_chase_range"):
		monster.call("set_chase_range", monster_data.original_chase_range)
	
	if monster.has_method("set_sight_range"):
		monster.call("set_sight_range", monster_data.original_sight_range)

# 应用到所有已注册怪物
func _apply_night_boost_to_all_monsters(multiplier: float) -> void:
	for monster_data in _monster_data_map.values():
		_apply_night_boost_to_monster(monster_data, multiplier)

# 从所有已注册怪物移除强化
func _remove_night_boost_from_all_monsters() -> void:
	for monster_data in _monster_data_map.values():
		_remove_night_boost_from_monster(monster_data)

# 处理昼夜阶段变化
func _on_day_phase_changed(new_phase: TimeManager.DayPhase, previous_phase: TimeManager.DayPhase) -> void:
	_current_phase = new_phase
	_update_night_boost_state()

# 手动启用/禁用强化系统
func set_enabled(value: bool) -> void:
	if enabled == value:
		return
	
	enabled = value
	
	if not enabled and _is_night_boost_active:
		# 禁用时移除所有强化
		_remove_night_boost_from_all_monsters()
		_is_night_boost_active = false
	elif enabled:
		# 重新启用时更新状态
		_update_night_boost_state()

# 获取当前是否处于夜晚强化状态
func is_night_boost_active() -> bool:
	return _is_night_boost_active

# 获取当前强化倍率（0-1）
func get_current_boost_multiplier() -> float:
	return _night_boost_multiplier if _is_night_boost_active else 0.0

# 调试功能：打印所有已注册怪物
func debug_print_monsters() -> void:
	print("MonsterNightBoostSystem: 已注册怪物数量 %d" % _monster_data_map.size())
	for instance_id in _monster_data_map.keys():
		var monster_data = _monster_data_map[instance_id]
		var node_name = monster_data.node.name if monster_data.node else "未知"
		print("  怪物: %s (ID: %d)" % [node_name, instance_id])