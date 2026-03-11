## 港口撤离计时器
## 显示剩余撤离时间并触发撤离事件
class_name PortEvacuationTimer
extends Control

# 导出变量 - 可在编辑器中配置
## 是否启用撤离计时器
@export var enabled: bool = true
## 撤离警告开始时间（小时，黄昏阶段开始）
@export var warning_start_hour: int = 18  # 黄昏开始
## 强制撤离截止时间（小时，夜晚开始后）
@export var evacuation_deadline_hour: int = 20  # 夜晚开始
## 撤离警告文本颜色
@export var warning_color: Color = Color(1.0, 0.8, 0.0, 1.0)  # 橙色
## 紧急撤离文本颜色
@export var emergency_color: Color = Color(1.0, 0.2, 0.2, 1.0)  # 红色
## 安全阶段文本颜色
@export var safe_color: Color = Color(0.8, 1.0, 0.8, 1.0)  # 浅绿色

# 节点引用
## 显示时间的Label节点路径
@export var time_label_path: NodePath = "TimeLabel"
## 显示状态描述的Label节点路径
@export var status_label_path: NodePath = "StatusLabel"

# 信号定义
## 撤离警告开始（距离夜晚开始还有X秒）
signal evacuation_warning_started(seconds_until_night: float)
## 紧急撤离阶段开始（夜晚开始，必须立即撤离）
signal emergency_evacuation_started
## 撤离成功（玩家抵达港口并撤离）
signal evacuation_success
## 撤离失败（玩家未能在夜晚开始前抵达港口）
signal evacuation_failed
## 撤离倒计时更新（剩余秒数）
signal evacuation_countdown_updated(seconds_remaining: float)

# 内部变量
var _time_manager: TimeManager = null
var _time_label: Label = null
var _status_label: Label = null
var _current_phase: TimeManager.DayPhase = TimeManager.DayPhase.DAY
var _is_warning_active: bool = false
var _is_emergency_active: bool = false
var _seconds_until_night: float = 0.0
var _player_in_port_area: bool = false
var _port_area_node: Area2D = null

func _ready() -> void:
	# 获取节点引用
	if time_label_path:
		_time_label = get_node(time_label_path)
	else:
		_time_label = get_node_or_null("TimeLabel")
	
	if status_label_path:
		_status_label = get_node(status_label_path)
	else:
		_status_label = get_node_or_null("StatusLabel")
	
	# 获取TimeManager
	_time_manager = _find_time_manager()
	if not _time_manager:
		push_warning("PortEvacuationTimer: 无法找到TimeManager，撤离计时器将无法工作")
		return
	
	# 连接信号
	_time_manager.day_phase_changed.connect(_on_day_phase_changed)
	_time_manager.time_updated.connect(_on_time_updated)
	
	# 初始化当前阶段
	_current_phase = _time_manager.get_current_phase()
	_update_evacuation_state()

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

# 设置港口区域节点（Area2D），用于检测玩家进入
func set_port_area(area_node: Area2D) -> void:
	if _port_area_node:
		# 断开旧信号
		_port_area_node.body_entered.disconnect(_on_port_area_body_entered)
		_port_area_node.body_exited.disconnect(_on_port_area_body_exited)
	
	_port_area_node = area_node
	
	if _port_area_node:
		_port_area_node.body_entered.connect(_on_port_area_body_entered)
		_port_area_node.body_exited.connect(_on_port_area_body_exited)

# 计算距离夜晚开始（20:00）的剩余秒数
func _calculate_seconds_until_night() -> float:
	var current_time = _time_manager.get_game_time()
	var current_seconds = current_time.hour * 3600 + current_time.minute * 60 + current_time.second
	
	var night_start_seconds = evacuation_deadline_hour * 3600
	
	if current_seconds < night_start_seconds:
		return night_start_seconds - current_seconds
	else:
		# 已经过了夜晚开始时间，计算到次日夜晚开始的剩余时间
		return (night_start_seconds + 24 * 3600) - current_seconds

# 更新撤离状态
func _update_evacuation_state() -> void:
	if not enabled or not _time_manager:
		return
	
	var was_warning_active = _is_warning_active
	var was_emergency_active = _is_emergency_active
	
	# 检查当前阶段
	var current_hour = _time_manager.get_game_time().hour
	var is_warning_time = current_hour >= warning_start_hour and current_hour < evacuation_deadline_hour
	var is_emergency_time = current_hour >= evacuation_deadline_hour or current_hour < 4  # 夜晚阶段
	
	_is_warning_active = is_warning_time
	_is_emergency_active = is_emergency_time
	
	# 计算距离夜晚开始的秒数
	_seconds_until_night = _calculate_seconds_until_night()
	
	# 触发信号
	if _is_warning_active and not was_warning_active:
		evacuation_warning_started.emit(_seconds_until_night)
	
	if _is_emergency_active and not was_emergency_active:
		emergency_evacuation_started.emit()
	
	# 更新显示
	_update_display()

# 更新显示内容
func _update_display() -> void:
	if not _time_label or not _status_label:
		return
	
	var time_text: String = ""
	var status_text: String = ""
	var text_color: Color = safe_color
	
	if _is_emergency_active:
		# 紧急撤离阶段
		time_text = _format_emergency_time(_seconds_until_night)
		status_text = "夜晚已降临！立即前往港口撤离！"
		text_color = emergency_color
	elif _is_warning_active:
		# 警告阶段
		time_text = _format_countdown_time(_seconds_until_night)
		status_text = "黄昏已至，距离夜晚还有："
		text_color = warning_color
	else:
		# 安全阶段
		var hours_until_warning = warning_start_hour - _time_manager.get_game_time().hour
		if hours_until_warning < 0:
			hours_until_warning += 24
		
		var minutes_until_warning = hours_until_warning * 60
		time_text = _format_hours_minutes(minutes_until_warning)
		status_text = "安全时段，距离黄昏还有："
		text_color = safe_color
	
	_time_label.text = time_text
	_status_label.text = status_text
	_time_label.modulate = text_color
	_status_label.modulate = text_color
	
	# 发送倒计时更新信号
	if _is_warning_active or _is_emergency_active:
		evacuation_countdown_updated.emit(_seconds_until_night)

# 格式化倒计时时间（HH:MM:SS）
func _format_countdown_time(seconds: float) -> String:
	var total_seconds = int(seconds)
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	var secs = total_seconds % 60
	
	return "%02d:%02d:%02d" % [hours, minutes, secs]

# 格式化紧急时间（显示已过夜晚时间）
func _format_emergency_time(seconds: float) -> String:
	var night_passed = 24 * 3600 - seconds  # 从20:00开始已经过去的秒数
	var hours = night_passed / 3600
	var minutes = (night_passed % 3600) / 60
	var secs = night_passed % 60
	
	return "+%02d:%02d:%02d" % [hours, minutes, secs]

# 格式化小时和分钟（用于安全阶段）
func _format_hours_minutes(minutes: int) -> String:
	var hours = minutes / 60
	var mins = minutes % 60
	
	return "%02d:%02d" % [hours, mins]

# 处理时间更新
func _on_time_updated(hour: int, minute: int, second: float) -> void:
	_update_evacuation_state()

# 处理阶段变化
func _on_day_phase_changed(new_phase: TimeManager.DayPhase, previous_phase: TimeManager.DayPhase) -> void:
	_current_phase = new_phase
	_update_evacuation_state()

# 玩家进入港口区域
func _on_port_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_port_area = true
		_check_evacuation_ready()

# 玩家离开港口区域
func _on_port_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_port_area = false

# 检查是否可以触发撤离
func _check_evacuation_ready() -> void:
	if _player_in_port_area:
		# 玩家在港口区域，可以触发撤离
		# 这里可以显示交互提示（按E键撤离等）
		pass

# 触发撤离（通常由玩家交互调用）
func trigger_evacuation() -> void:
	if not _player_in_port_area:
		push_warning("PortEvacuationTimer: 玩家不在港口区域，无法撤离")
		return
	
	# 撤离成功
	evacuation_success.emit()
	
	# 这里可以触发游戏逻辑：返回主岛、保存资源等
	print("撤离成功！返回主岛。")
	
	# 重置状态
	_player_in_port_area = false

# 手动设置警告开始时间和撤离截止时间
func set_warning_times(warning_hour: int, deadline_hour: int) -> void:
	warning_start_hour = warning_hour
	evacuation_deadline_hour = deadline_hour
	_update_evacuation_state()

# 启用/禁用计时器
func set_enabled(value: bool) -> void:
	if enabled == value:
		return
	
	enabled = value
	
	if not enabled:
		# 禁用时重置状态
		_is_warning_active = false
		_is_emergency_active = false
		if _time_label:
			_time_label.text = ""
		if _status_label:
			_status_label.text = ""
	else:
		# 重新启用时更新
		_update_evacuation_state()

# 获取当前是否处于警告阶段
func is_warning_active() -> bool:
	return _is_warning_active

# 获取当前是否处于紧急阶段
func is_emergency_active() -> bool:
	return _is_emergency_active

# 获取距离夜晚开始的剩余秒数
func get_seconds_until_night() -> float:
	return _seconds_until_night