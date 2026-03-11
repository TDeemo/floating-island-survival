## 篝火静态光源
## 继承自LightSource，提供篝火的特定行为：长时间燃烧、建造交互、取暖效果、可添加燃料
class_name CampfireLight
extends LightSource

# 篝火特定配置
## 最大燃料时间（游戏内秒数）
@export var max_fuel_time: float = 3600.0  # 1小时游戏时间
## 当前剩余燃料时间
@export var current_fuel_time: float = 3600.0:
	set(value):
		current_fuel_time = clamp(value, 0.0, max_fuel_time)
		_update_fuel_indicator()
		if current_fuel_time <= 0:
			_fuel_depleted()

## 基础燃料消耗速率（游戏内秒/现实秒）
@export var base_fuel_consumption_rate: float = 1.0
## 是否启用取暖效果
@export var provide_warmth: bool = true
## 取暖范围（像素）
@export var warmth_range: float = 150.0
## 取暖强度（影响寒冷状态恢复速度）
@export var warmth_strength: float = 2.0

# 建造系统交互
## 建造消耗的资源类型和数量
@export var build_cost_resources: Dictionary = {
	"wood": 10,
	"stone": 5
}
## 是否已建造完成
@export var is_built: bool = false
## 建造进度（0.0-1.0）
@export var build_progress: float = 0.0

# 状态
var is_fuel_active: bool = true
var is_providing_warmth: bool = false
var players_in_warmth_range: Array[Node2D] = []

# 信号
## 燃料更新
signal fuel_updated(current: float, max: float)
## 燃料耗尽
signal fuel_depleted
## 建造进度更新
signal build_progress_updated(progress: float)
## 建造完成
signal build_completed
## 玩家进入取暖范围
signal player_entered_warmth(player: Node2D)
## 玩家离开取暖范围
signal player_left_warmth(player: Node2D)
## 可添加燃料状态变化
signal can_add_fuel_changed(can_add: bool)

func _ready() -> void:
	super._ready()
	
	# 篝火特定初始化
	_setup_campfire_properties()
	
	# 初始状态
	if is_built:
		_on_build_completed()
	else:
		enabled = false  # 建造完成前不发光
	
	_update_fuel_indicator()

## 设置篝火特定属性
func _setup_campfire_properties() -> void:
	# 篝火默认参数
	radius = 400.0  # 篝火光照半径更大
	intensity = 1.2  # 强度更高
	color = Color(1.0, 0.7, 0.4, 1.0)  # 更暖的橙色
	enable_attenuation = true
	attract_monsters = true  # 篝火吸引怪物
	
	# 取暖效果默认开启
	provide_warmth = true
	warmth_range = 150.0
	warmth_strength = 2.0
	
	# 应用参数
	_apply_light_parameters()

func _process(delta: float) -> void:
	super._process(delta)
	
	if not is_built or not enabled or not is_fuel_active:
		return
	
	# 燃料消耗
	_consume_fuel(delta)
	
	# 更新取暖效果
	if provide_warmth:
		_update_warmth_effect()

## 消耗燃料
func _consume_fuel(delta: float) -> void:
	if current_fuel_time <= 0:
		return
	
	# 实际消耗（考虑时间流逝比例）
	var time_manager = _find_time_manager()
	var time_passed = delta
	if time_manager:
		time_passed = delta * time_manager.time_scale
	
	var fuel_consumed = time_passed * base_fuel_consumption_rate
	current_fuel_time -= fuel_consumed

## 更新燃料指示器
func _update_fuel_indicator() -> void:
	fuel_updated.emit(current_fuel_time, max_fuel_time)
	
	# 根据燃料量调整光照效果
	var fuel_ratio = current_fuel_time / max_fuel_time
	if fuel_ratio < 0.3:
		_start_low_fuel_effect(fuel_ratio)
	else:
		_stop_low_fuel_effect()

## 燃料耗尽处理
func _fuel_depleted() -> void:
	is_fuel_active = false
	enabled = false
	fuel_depleted.emit()
	
	# 篝火熄灭效果
	print("篝火燃料耗尽")

## 开始低燃料效果
func _start_low_fuel_effect(fuel_ratio: float) -> void:
	# 篝火火焰变小，光照减弱
	intensity = fuel_ratio * 0.8  # 按比例降低强度
	_apply_light_parameters()

## 停止低燃料效果
func _stop_low_fuel_effect() -> void:
	# 恢复正常强度
	intensity = 1.2
	_apply_light_parameters()

## 更新取暖效果
func _update_warmth_effect() -> void:
	# 检测范围内的玩家并应用取暖效果
	# 简化实现：通过Area2D检测
	pass

## 查找TimeManager
func _find_time_manager() -> TimeManager:
	var root = get_tree().root
	for node in root.get_children():
		if node is TimeManager:
			return node as TimeManager
	return null

## 建造交互方法

## 开始建造
func start_build() -> void:
	if is_built:
		push_warning("篝火已建造完成")
		return
	
	print("开始建造篝火")
	build_progress = 0.0
	is_built = false
	enabled = false

## 添加建造资源（由玩家调用）
func add_build_resource(resource_type: String, amount: int) -> bool:
	if is_built:
		push_warning("篝火已建造完成，无法添加建造资源")
		return false
	
	# 检查是否为所需资源
	if not build_cost_resources.has(resource_type):
		push_warning("资源类型无效: %s" % resource_type)
		return false
	
	# 更新建造进度（简化：每种资源独立计算）
	var required = build_cost_resources[resource_type]
	var added = min(amount, required)
	build_progress += float(added) / float(required) / build_cost_resources.size()
	
	build_progress_updated.emit(build_progress)
	
	# 检查是否建造完成
	if build_progress >= 1.0:
		_on_build_completed()
		return true
	
	return false

## 建造完成处理
func _on_build_completed() -> void:
	is_built = true
	build_progress = 1.0
	enabled = true
	is_fuel_active = true
	
	build_completed.emit()
	print("篝火建造完成")

## 添加燃料
func add_fuel(fuel_amount: float) -> void:
	if not is_built:
		push_warning("篝火尚未建造完成，无法添加燃料")
		return
	
	if not is_fuel_active:
		# 重新点燃
		_relight()
	
	current_fuel_time = clamp(current_fuel_time + fuel_amount, 0.0, max_fuel_time)
	print("篝火添加燃料: %f，当前燃料: %f" % [fuel_amount, current_fuel_time])

## 重新点燃
func _relight() -> void:
	is_fuel_active = true
	enabled = true
	print("篝火重新点燃")

## 获取建造状态
func get_build_status() -> Dictionary:
	return {
		"is_built": is_built,
		"build_progress": build_progress,
		"remaining_resources": _calculate_remaining_resources()
	}

## 计算剩余所需资源
func _calculate_remaining_resources() -> Dictionary:
	if is_built:
		return {}
	
	var remaining = {}
	for resource_type in build_cost_resources:
		var required = build_cost_resources[resource_type]
		var added = int(build_progress * required * build_cost_resources.size())
		remaining[resource_type] = max(0, required - added)
	
	return remaining

## 启用/禁用取暖效果
func set_warmth_enabled(enabled: bool) -> void:
	provide_warmth = enabled
	is_providing_warmth = enabled and is_built and is_fuel_active

## 获取取暖范围信息
func get_warmth_info() -> Dictionary:
	return {
		"is_active": is_providing_warmth,
		"range": warmth_range,
		"strength": warmth_strength,
		"players_in_range": players_in_warmth_range.size()
	}

## 处理玩家交互（由玩家控制器调用）
func handle_interaction(player: Node2D, action: String) -> void:
	match action:
		"add_fuel":
			# 检查玩家是否有燃料资源
			# 简化：直接添加固定量
			add_fuel(600.0)  # 添加10分钟燃料
		"build":
			if not is_built:
				# 开始建造流程
				start_build()
		"toggle":
			if is_built:
				toggle()

## 检查是否可交互（用于UI提示）
func can_interact(player: Node2D) -> bool:
	if not is_built:
		return true  # 可建造
	
	if current_fuel_time < max_fuel_time * 0.9:
		return true  # 可添加燃料
	
	return false  # 无需交互

## 获取交互提示文本
func get_interaction_hint() -> String:
	if not is_built:
		return "建造篝火"
	
	if current_fuel_time < max_fuel_time * 0.3:
		return "添加燃料（燃料不足）"
	elif current_fuel_time < max_fuel_time * 0.9:
		return "添加燃料"
	
	return "点燃/熄灭"