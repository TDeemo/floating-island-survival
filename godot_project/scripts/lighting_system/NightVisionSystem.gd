## 夜间视野限制系统
## 管理与昼夜循环系统集成的玩家视野限制，处理黑暗环境下的视野计算
class_name NightVisionSystem
extends Node

# 导出配置
## 是否启用夜间视野限制
@export var enabled: bool = true
## 基础夜间视野范围（无光源时，像素）
@export var base_vision_range: float = 100.0
## 最大视野范围（有强光源时，像素）
@export var max_vision_range: float = 800.0
## 视野过渡平滑时间（秒）
@export var transition_smooth_time: float = 0.5
## 是否启用黑暗迷雾效果
@export var enable_dark_fog: bool = true
## 黑暗迷雾不透明度（0.0-1.0）
@export var dark_fog_opacity: float = 0.8

# 引用
var _time_manager: TimeManager = null
var _day_night_cycle: DayNightCycle = null
var _light_manager: LightManager = null
var _player_node: Node2D = null

# 当前状态
var _current_vision_range: float = max_vision_range
var _target_vision_range: float = max_vision_range
var _vision_transition_timer: float = 0.0
var _is_in_transition: bool = false

# 黑暗迷雾节点（可选）
var _dark_fog_node: CanvasItem = null

# 信号定义
## 视野范围变化
signal vision_range_changed(new_range: float, target_range: float)
## 黑暗状态变化（进入/离开黑暗）
signal dark_state_changed(is_in_dark: bool, darkness_level: float)
## 需要视觉提示（例如边缘变暗）
signal visual_cue_requested(cue_type: String, intensity: float)

func _ready() -> void:
	# 查找依赖系统
	_find_dependencies()
	
	# 初始化视野范围为最大值
	_current_vision_range = max_vision_range
	_target_vision_range = max_vision_range
	
	# 设置黑暗迷雾（如果启用）
	if enable_dark_fog:
		_setup_dark_fog()

## 查找依赖系统
func _find_dependencies() -> void:
	var root = get_tree().root
	
	# 查找TimeManager
	for node in root.get_children():
		if node is TimeManager:
			_time_manager = node as TimeManager
			break
	
	# 查找DayNightCycle
	for node in root.get_children():
		if node is DayNightCycle:
			_day_night_cycle = node as DayNightCycle
			break
	
	# 查找LightManager
	for node in root.get_children():
		if node is LightManager:
			_light_manager = node as LightManager
			break
	
	# 查找玩家节点（简化：查找第一个PlayerController）
	var all_players = _find_nodes_by_class(root, "PlayerController")
	if not all_players.is_empty():
		_player_node = all_players[0] as Node2D

## 递归查找特定类节点
func _find_nodes_by_class(root: Node, class_name: String) -> Array[Node]:
	var result: Array[Node] = []
	
	if root.get_class() == class_name:
		result.append(root)
	
	for child in root.get_children():
		result.append_array(_find_nodes_by_class(child, class_name))
	
	return result

func _process(delta: float) -> void:
	if not enabled:
		return
	
	# 更新视野范围计算
	_update_vision_range(delta)
	
	# 处理视野过渡
	_process_vision_transition(delta)
	
	# 更新黑暗迷雾效果
	if _dark_fog_node:
		_update_dark_fog(delta)

## 更新视野范围计算
func _update_vision_range(delta: float) -> void:
	if not _player_node:
		return
	
	# 获取当前时间阶段
	var current_phase = _get_current_day_phase()
	var is_night = current_phase == TimeManager.DayPhase.NIGHT
	var is_dusk = current_phase == TimeManager.DayPhase.DUSK
	
	# 如果没有时间管理器，假设是白天
	if not _time_manager:
		_target_vision_range = max_vision_range
		return
	
	# 计算基础黑暗程度
	var darkness_level = 0.0
	if is_night:
		darkness_level = 1.0
	elif is_dusk:
		# 黄昏部分黑暗
		darkness_level = 0.5
	else:
		darkness_level = 0.0
	
	# 如果有光照系统，计算光源影响
	var light_boost = 0.0
	if _light_manager:
		light_boost = _calculate_light_boost()
	
	# 计算目标视野范围
	# 公式：基础范围 + (最大范围 - 基础范围) * (1 - 黑暗程度 + 光照增强)
	var dark_factor = 1.0 - darkness_level
	_target_vision_range = base_vision_range + (max_vision_range - base_vision_range) * (dark_factor + light_boost)
	
	# 确保在合理范围内
	_target_vision_range = clamp(_target_vision_range, base_vision_range, max_vision_range)
	
	# 如果变化超过阈值，开始过渡
	var change_threshold = 10.0
	if abs(_target_vision_range - _current_vision_range) > change_threshold:
		_start_vision_transition()

## 计算光照增强
func _calculate_light_boost() -> float:
	if not _player_node or not _light_manager:
		return 0.0
	
	# 获取玩家附近的光源
	var nearby_lights = _light_manager.get_lights_near_player(_player_node.global_position, 500.0)
	
	if nearby_lights.is_empty():
		return 0.0
	
	# 计算最近/最强的光源影响
	var total_boost = 0.0
	for light in nearby_lights:
		if not light or not light.enabled:
			continue
		
		# 计算距离和强度
		var distance = _player_node.global_position.distance_to(light.global_position)
		var normalized_distance = distance / light.radius
		
		# 距离越近，强度越大
		var distance_factor = 1.0 - clamp(normalized_distance, 0.0, 1.0)
		var light_boost = light.intensity * distance_factor
		
		total_boost = max(total_boost, light_boost)
	
	return clamp(total_boost, 0.0, 1.0)

## 获取当前昼夜阶段
func _get_current_day_phase() -> int:
	if not _time_manager:
		return TimeManager.DayPhase.DAY  # 默认白天
	
	return _time_manager.current_phase

## 开始视野过渡
func _start_vision_transition() -> void:
	if _is_in_transition:
		return  # 已经在过渡中
	
	_is_in_transition = true
	_vision_transition_timer = transition_smooth_time

## 处理视野过渡
func _process_vision_transition(delta: float) -> void:
	if not _is_in_transition:
		return
	
	_vision_transition_timer -= delta
	if _vision_transition_timer <= 0:
		# 过渡完成
		_current_vision_range = _target_vision_range
		_is_in_transition = false
		vision_range_changed.emit(_current_vision_range, _target_vision_range)
		
		# 检查黑暗状态变化
		_check_dark_state_change()
	else:
		# 线性插值
		var t = 1.0 - (_vision_transition_timer / transition_smooth_time)
		_current_vision_range = lerp(_current_vision_range, _target_vision_range, t)
		
		# 部分更新信号（可选，避免每帧触发）
		if fmod(t * 10, 1.0) < 0.1:  # 每10%进度触发一次
			vision_range_changed.emit(_current_vision_range, _target_vision_range)

## 检查黑暗状态变化
func _check_dark_state_change() -> void:
	var is_in_dark = _current_vision_range <= base_vision_range * 1.5
	var was_in_dark = _previous_dark_state if has_method("_get_previous_dark_state") else false
	
	if is_in_dark != was_in_dark:
		var darkness_level = 1.0 - (_current_vision_range - base_vision_range) / (max_vision_range - base_vision_range)
		dark_state_changed.emit(is_in_dark, darkness_level)
		
		# 请求视觉提示
		if is_in_dark:
			visual_cue_requested.emit("enter_dark", darkness_level)
		else:
			visual_cue_requested.emit("exit_dark", darkness_level)

## 设置黑暗迷雾
func _setup_dark_fog() -> void:
	# 创建一个简单的CanvasItem作为黑暗迷雾层
	# 简化实现：创建一个ColorRect覆盖整个屏幕
	_dark_fog_node = ColorRect.new()
	_dark_fog_node.color = Color(0.0, 0.0, 0.0, dark_fog_opacity)
	_dark_fog_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 添加到场景（作为UI层）
	var viewport = get_viewport()
	if viewport:
		viewport.add_child(_dark_fog_node)
		_dark_fog_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		# 初始隐藏
		_dark_fog_node.visible = false

## 更新黑暗迷雾效果
func _update_dark_fog(delta: float) -> void:
	if not _dark_fog_node:
		return
	
	# 根据视野范围决定迷雾可见性和透明度
	var vision_ratio = _current_vision_range / max_vision_range
	var should_be_visible = vision_ratio < 0.7  # 视野小于70%时显示迷雾
	
	# 平滑过渡
	if should_be_visible:
		if not _dark_fog_node.visible:
			_dark_fog_node.visible = true
		
		# 计算不透明度：视野越小，迷雾越浓
		var target_opacity = dark_fog_opacity * (1.0 - vision_ratio / 0.7)
		target_opacity = clamp(target_opacity, 0.0, dark_fog_opacity)
		
		# 平滑过渡
		var current_color = _dark_fog_node.color
		var new_color = Color(0.0, 0.0, 0.0, target_opacity)
		_dark_fog_node.color = current_color.lerp(new_color, delta * 2.0)
	else:
		if _dark_fog_node.visible:
			# 淡出后隐藏
			var current_alpha = _dark_fog_node.color.a
			if current_alpha < 0.05:
				_dark_fog_node.visible = false
			else:
				var new_color = Color(0.0, 0.0, 0.0, current_alpha * 0.8)
				_dark_fog_node.color = new_color

## 处理全局光照变化（由LightManager调用）
func _on_global_lighting_changed(is_dark: bool, player_has_light: bool) -> void:
	if not enabled:
		return
	
	# 立即重新计算视野范围
	_update_vision_range(0.0)
	_start_vision_transition()
	
	# 如果玩家在黑暗中且没有光源，触发警告提示
	if is_dark and not player_has_light:
		visual_cue_requested.emit("warning_no_light", 1.0)

## 获取当前视野范围
func get_vision_range() -> float:
	return _current_vision_range

## 获取目标视野范围
func get_target_vision_range() -> float:
	return _target_vision_range

## 获取黑暗程度（0.0-1.0，1.0为完全黑暗）
func get_darkness_level() -> float:
	var range_span = max_vision_range - base_vision_range
	if range_span <= 0:
		return 1.0
	
	return 1.0 - (_current_vision_range - base_vision_range) / range_span

## 检查玩家是否在黑暗中
func is_player_in_dark() -> bool:
	return get_darkness_level() > 0.7  # 自定义阈值

## 设置玩家节点引用
func set_player_node(player: Node2D) -> void:
	_player_node = player

## 强制更新视野计算
func force_update() -> void:
	_update_vision_range(0.0)
	_current_vision_range = _target_vision_range
	vision_range_changed.emit(_current_vision_range, _target_vision_range)

## 启用/禁用黑暗迷雾
func set_dark_fog_enabled(enabled: bool) -> void:
	enable_dark_fog = enabled
	
	if not enabled and _dark_fog_node:
		_dark_fog_node.visible = false

## 清理资源
func _exit_tree() -> void:
	if _dark_fog_node and is_instance_valid(_dark_fog_node):
		_dark_fog_node.queue_free()