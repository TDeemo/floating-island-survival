## 昼夜循环控制器
## 管理环境光渐变、天空颜色变化和阶段过渡动画
class_name DayNightCycle
extends Node2D

# 依赖：需要场景中存在CanvasModulate节点（用于全局色调调整）
# 可选：WorldEnvironment（用于后处理效果）

# 导出变量 - 可在编辑器中配置
## 是否启用昼夜循环效果
@export var enabled: bool = true
## 关联的CanvasModulate节点路径
@export var canvas_modulate_path: NodePath = "CanvasModulate"
## 是否启用平滑渐变（默认为true）
@export var smooth_transition: bool = true
## 渐变持续时间（秒）
@export var transition_duration: float = 30.0

# 各阶段颜色定义（RGBA，CanvasModulate的颜色）
## 黎明颜色（暖黄色）
@export var dawn_color: Color = Color(1.0, 0.9, 0.7, 1.0)
## 白天颜色（正常白色）
@export var day_color: Color = Color(1.0, 1.0, 1.0, 1.0)
## 黄昏颜色（橙红色）
@export var dusk_color: Color = Color(1.0, 0.7, 0.5, 1.0)
## 夜晚颜色（深蓝色）
@export var night_color: Color = Color(0.3, 0.3, 0.5, 1.0)

# 各阶段亮度系数（叠加到颜色上）
@export var dawn_brightness: float = 0.8
@export var day_brightness: float = 1.0
@export var dusk_brightness: float = 0.6
@export var night_brightness: float = 0.3

# 内部变量
var _canvas_modulate: CanvasModulate = null
var _time_manager: TimeManager = null
var _current_target_color: Color = Color.WHITE
var _current_target_brightness: float = 1.0
var _transition_timer: float = 0.0
var _is_in_transition: bool = false
var _transition_from_color: Color = Color.WHITE
var _transition_from_brightness: float = 1.0

# 缓存各阶段的颜色+亮度组合
var _phase_colors: Array[Color] = []
var _phase_brightnesses: Array[float] = []

func _ready() -> void:
	# 初始化颜色数组
	_phase_colors = [dawn_color, day_color, dusk_color, night_color]
	_phase_brightnesses = [dawn_brightness, day_brightness, dusk_brightness, night_brightness]
	
	# 获取CanvasModulate节点
	if canvas_modulate_path:
		_canvas_modulate = get_node(canvas_modulate_path)
		if not _canvas_modulate:
			push_warning("DayNightCycle: 无法找到CanvasModulate节点，路径：%s" % canvas_modulate_path)
	else:
		# 尝试查找场景中已有的CanvasModulate
		_canvas_modulate = get_node_or_null("CanvasModulate")
		if not _canvas_modulate:
			# 创建新的CanvasModulate
			_canvas_modulate = CanvasModulate.new()
			add_child(_canvas_modulate)
			_canvas_modulate.name = "CanvasModulate"
	
	# 获取TimeManager（假设作为全局单例或通过组查找）
	_time_manager = _find_time_manager()
	if not _time_manager:
		push_warning("DayNightCycle: 无法找到TimeManager，昼夜颜色变化将无法工作")
		return
	
	# 连接信号
	_time_manager.day_phase_changed.connect(_on_day_phase_changed)
	
	# 初始化当前颜色
	_update_color_for_phase(_time_manager.get_current_phase())
	_apply_color()

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

# 根据阶段获取目标颜色和亮度
func _get_phase_color_and_brightness(phase: TimeManager.DayPhase) -> Dictionary:
	var phase_index = phase
	if phase_index >= 0 and phase_index < _phase_colors.size():
		return {
			"color": _phase_colors[phase_index],
			"brightness": _phase_brightnesses[phase_index]
		}
	else:
		# 默认返回白天
		return {
			"color": day_color,
			"brightness": day_brightness
		}

# 更新颜色为目标阶段
func _update_color_for_phase(phase: TimeManager.DayPhase) -> void:
	var phase_data = _get_phase_color_and_brightness(phase)
	
	if smooth_transition:
		# 开始平滑过渡
		_transition_from_color = _canvas_modulate.color if _canvas_modulate else Color.WHITE
		_transition_from_brightness = _current_target_brightness
		_current_target_color = phase_data.color
		_current_target_brightness = phase_data.brightness
		_transition_timer = 0.0
		_is_in_transition = true
	else:
		# 立即切换
		_current_target_color = phase_data.color
		_current_target_brightness = phase_data.brightness
		_is_in_transition = false
		_apply_color()

# 应用当前计算的颜色到CanvasModulate
func _apply_color() -> void:
	if not _canvas_modulate:
		return
	
	var final_color = _current_target_color
	if _is_in_transition:
		# 插值计算
		var t = _transition_timer / transition_duration
		t = clamp(t, 0.0, 1.0)
		final_color = _transition_from_color.lerp(_current_target_color, t)
		var brightness = lerp(_transition_from_brightness, _current_target_brightness, t)
		final_color = final_color * brightness
	
	_canvas_modulate.color = final_color

# 处理昼夜阶段变化
func _on_day_phase_changed(new_phase: TimeManager.DayPhase, previous_phase: TimeManager.DayPhase) -> void:
	if not enabled:
		return
	
	_update_color_for_phase(new_phase)

func _process(delta: float) -> void:
	if not enabled or not _canvas_modulate:
		return
	
	if _is_in_transition:
		_transition_timer += delta
		_apply_color()
		
		if _transition_timer >= transition_duration:
			_is_in_transition = false
			_apply_color()
	else:
		# 如果没有过渡，确保颜色是最新的（防止阶段变化未触发）
		_apply_color()
	
	# 可选：根据时间微调颜色（例如，黎明到白天之间逐渐变亮）
	# 这里可以基于TimeManager的相位进度进行更精细的插值
	# 但为了简化，我们仅在阶段变化时切换颜色

# 手动设置颜色（用于调试或特殊事件）
func set_color(color: Color, brightness: float = 1.0, smooth: bool = false) -> void:
	if smooth and smooth_transition:
		_transition_from_color = _canvas_modulate.color if _canvas_modulate else Color.WHITE
		_transition_from_brightness = _current_target_brightness
		_current_target_color = color
		_current_target_brightness = brightness
		_transition_timer = 0.0
		_is_in_transition = true
	else:
		_current_target_color = color
		_current_target_brightness = brightness
		_is_in_transition = false
		_apply_color()

# 获取当前颜色
func get_current_color() -> Color:
	return _canvas_modulate.color if _canvas_modulate else Color.WHITE

# 启用/禁用昼夜效果
func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		# 重置为白天颜色
		_current_target_color = day_color
		_current_target_brightness = day_brightness
		_is_in_transition = false
		_apply_color()