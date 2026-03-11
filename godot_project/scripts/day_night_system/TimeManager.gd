## 全局时间管理器
## 负责游戏时间流逝、昼夜阶段判断和事件触发
class_name TimeManager
extends Node

# 昼夜阶段枚举
enum DayPhase {
	DAWN,      # 黎明（04:00-06:00）
	DAY,       # 白天（06:00-18:00）
	DUSK,      # 黄昏（18:00-20:00）
	NIGHT      # 夜晚（20:00-04:00）
}

# 导出变量 - 可在编辑器中配置
## 游戏时间流逝速度：现实1秒 = 游戏内多少秒
@export var time_scale: float = 60.0  # 默认1现实秒=1游戏分钟
## 是否启用时间流逝
@export var time_enabled: bool = true
## 游戏起始时间（小时，0-23）
@export var start_hour: int = 6  # 默认从早晨6点开始
## 游戏起始时间（分钟，0-59）
@export var start_minute: int = 0

# 信号定义
## 游戏时间更新（小时，分钟，秒）
signal time_updated(hour: int, minute: int, second: float)
## 昼夜阶段变化（新阶段，前一阶段）
signal day_phase_changed(new_phase: DayPhase, previous_phase: DayPhase)
## 特定时间事件（例如整点）
signal hour_changed(hour: int)
## 黎明/黄昏/夜晚开始/结束等特殊事件
signal dawn_started
signal day_started
signal dusk_started
signal night_started

# 内部时间变量
var _game_seconds: float = 0.0  # 从0:00开始累计的秒数
var _current_phase: DayPhase = DayPhase.DAY
var _previous_phase: DayPhase = DayPhase.DAY
var _last_hour: int = -1

# 阶段时间定义（小时，24小时制）
const PHASE_DAWN_START: int = 4
const PHASE_DAWN_END: int = 6
const PHASE_DAY_START: int = 6
const PHASE_DAY_END: int = 18
const PHASE_DUSK_START: int = 18
const PHASE_DUSK_END: int = 20
const PHASE_NIGHT_START: int = 20
const PHASE_NIGHT_END: int = 4  # 次日4点

# 计算属性：获取当前游戏时间
func get_game_time() -> Dictionary:
	var total_seconds = int(_game_seconds)
	var hour = (total_seconds / 3600) % 24
	var minute = (total_seconds % 3600) / 60
	var second = _game_seconds - total_seconds
	return {
		"hour": hour,
		"minute": minute,
		"second": second
	}

# 获取当前昼夜阶段
func get_current_phase() -> DayPhase:
	return _current_phase

# 获取阶段名称（用于显示）
func get_phase_name(phase: DayPhase) -> String:
	match phase:
		DayPhase.DAWN: return "黎明"
		DayPhase.DAY: return "白天"
		DayPhase.DUSK: return "黄昏"
		DayPhase.NIGHT: return "夜晚"
		_: return "未知"

# 判断指定时间（小时）属于哪个阶段
func get_phase_for_hour(hour: int) -> DayPhase:
	if hour >= PHASE_DAWN_START and hour < PHASE_DAWN_END:
		return DayPhase.DAWN
	elif hour >= PHASE_DAY_START and hour < PHASE_DAY_END:
		return DayPhase.DAY
	elif hour >= PHASE_DUSK_START and hour < PHASE_DUSK_END:
		return DayPhase.DUSK
	else:
		# 夜晚跨越午夜，需特殊处理
		if hour >= PHASE_NIGHT_START or hour < PHASE_NIGHT_END:
			return DayPhase.NIGHT
		else:
			# 理论上不会到达这里，但为了安全返回夜晚
			return DayPhase.NIGHT

# 设置游戏时间（小时，分钟，秒）
func set_game_time(hour: int, minute: int = 0, second: float = 0.0) -> void:
	_game_seconds = hour * 3600.0 + minute * 60.0 + second
	_update_phase()
	_update_hour_event()

# 获取时间流逝速度（现实1秒=游戏内多少秒）
func get_time_scale() -> float:
	return time_scale

# 设置时间流逝速度
func set_time_scale(scale: float) -> void:
	time_scale = scale

# 暂停时间流逝
func pause_time() -> void:
	time_enabled = false

# 恢复时间流逝
func resume_time() -> void:
	time_enabled = true

# 跳转到指定阶段（例如直接跳到夜晚）
func jump_to_phase(phase: DayPhase) -> void:
	var target_hour: int
	match phase:
		DayPhase.DAWN:
			target_hour = PHASE_DAWN_START
		DayPhase.DAY:
			target_hour = PHASE_DAY_START
		DayPhase.DUSK:
			target_hour = PHASE_DUSK_START
		DayPhase.NIGHT:
			target_hour = PHASE_NIGHT_START
	
	set_game_time(target_hour, 0, 0)

# 获取阶段剩余时间（秒）
func get_phase_remaining_seconds() -> float:
	var current = get_game_time()
	var hour = current.hour
	var total_seconds_current = hour * 3600 + current.minute * 60 + current.second
	
	var next_transition_hour: int
	match _current_phase:
		DayPhase.DAWN:
			next_transition_hour = PHASE_DAWN_END
		DayPhase.DAY:
			next_transition_hour = PHASE_DAY_END
		DayPhase.DUSK:
			next_transition_hour = PHASE_DUSK_END
		DayPhase.NIGHT:
			# 夜晚结束时间是次日4点
			next_transition_hour = PHASE_NIGHT_END
			if hour >= PHASE_NIGHT_START:
				# 当天20点后的夜晚，结束时间是次日4点
				next_transition_hour += 24
	
	var total_seconds_next = next_transition_hour * 3600
	if total_seconds_next < total_seconds_current:
		total_seconds_next += 24 * 3600
	
	return total_seconds_next - total_seconds_current

# 获取阶段进度（0-1）
func get_phase_progress() -> float:
	var remaining = get_phase_remaining_seconds()
	var phase_duration: float
	match _current_phase:
		DayPhase.DAWN:
			phase_duration = (PHASE_DAWN_END - PHASE_DAWN_START) * 3600.0
		DayPhase.DAY:
			phase_duration = (PHASE_DAY_END - PHASE_DAY_START) * 3600.0
		DayPhase.DUSK:
			phase_duration = (PHASE_DUSK_END - PHASE_DUSK_START) * 3600.0
		DayPhase.NIGHT:
			phase_duration = (PHASE_NIGHT_END + 24 - PHASE_NIGHT_START) * 3600.0
	
	return 1.0 - (remaining / phase_duration)

# 内部函数：更新昼夜阶段
func _update_phase() -> void:
	var time = get_game_time()
	var new_phase = get_phase_for_hour(time.hour)
	
	if new_phase != _current_phase:
		_previous_phase = _current_phase
		_current_phase = new_phase
		day_phase_changed.emit(_current_phase, _previous_phase)
		
		# 触发特定阶段开始信号
		match _current_phase:
			DayPhase.DAWN:
				dawn_started.emit()
			DayPhase.DAY:
				day_started.emit()
			DayPhase.DUSK:
				dusk_started.emit()
			DayPhase.NIGHT:
				night_started.emit()

# 内部函数：更新整点事件
func _update_hour_event() -> void:
	var time = get_game_time()
	if time.hour != _last_hour:
		_last_hour = time.hour
		hour_changed.emit(_last_hour)

func _ready() -> void:
	# 初始化游戏时间
	set_game_time(start_hour, start_minute, 0)
	_update_phase()
	_update_hour_event()

func _process(delta: float) -> void:
	if not time_enabled:
		return
	
	# 更新游戏时间
	_game_seconds += delta * time_scale
	
	# 触发时间更新信号
	var time = get_game_time()
	time_updated.emit(time.hour, time.minute, time.second)
	
	# 检查阶段变化
	_update_phase()
	
	# 检查整点事件
	_update_hour_event()