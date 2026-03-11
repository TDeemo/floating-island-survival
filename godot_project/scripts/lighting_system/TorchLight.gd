## 手持火把光源
## 继承自LightSource，提供手持火把的特定行为：燃料消耗、玩家跟随、动画效果
class_name TorchLight
extends LightSource

# 火把特定配置
## 最大燃料时间（游戏内秒数）
@export var max_fuel_time: float = 600.0  # 10分钟游戏时间
## 当前剩余燃料时间
@export var current_fuel_time: float = 600.0:
	set(value):
		current_fuel_time = clamp(value, 0.0, max_fuel_time)
		_update_fuel_indicator()
		if current_fuel_time <= 0:
			_fuel_depleted()

## 燃料消耗速率（游戏内秒/现实秒）
@export var fuel_consumption_rate: float = 1.0  # 1:1时间比例
## 是否自动跟随玩家
@export var follow_player: bool = true
## 跟随偏移量（相对玩家位置）
@export var follow_offset: Vector2 = Vector2(0, -20)

# 引用
var player_node: Node2D = null
var time_manager: TimeManager = null

# 状态
var is_equipped: bool = false
var is_fuel_active: bool = true

# 信号
## 燃料更新（当前燃料，最大燃料）
signal fuel_updated(current: float, max: float)
## 燃料耗尽
signal fuel_depleted
## 火把装备状态变化
signal torch_equipped(is_equipped: bool)

func _ready() -> void:
	super._ready()
	
	# 火把特定初始化
	_setup_torch_properties()
	
	# 尝试获取TimeManager引用
	time_manager = _find_time_manager()
	
	# 初始燃料指示器
	_update_fuel_indicator()

## 设置火把特定属性
func _setup_torch_properties() -> void:
	# 火把默认参数
	radius = 250.0  # 火把光照半径
	intensity = 0.9
	color = Color(1.0, 0.8, 0.5, 1.0)  # 暖黄色
	enable_attenuation = true
	attract_monsters = true
	
	# 应用参数
	_apply_light_parameters()

## 查找场景中的TimeManager
func _find_time_manager() -> TimeManager:
	# 首先在父节点中查找
	var parent = get_parent()
	while parent:
		if parent is TimeManager:
			return parent as TimeManager
		parent = parent.get_parent()
	
	# 在场景树中查找
	var root = get_tree().root
	for node in root.get_children():
		if node is TimeManager:
			return node as TimeManager
	
	return null

func _process(delta: float) -> void:
	super._process(delta)
	
	if not enabled or not is_fuel_active:
		return
	
	# 燃料消耗（基于游戏时间）
	_consume_fuel(delta)
	
	# 跟随玩家
	if follow_player and player_node:
		_update_follow_position()

## 消耗燃料
func _consume_fuel(delta: float) -> void:
	if current_fuel_time <= 0:
		return
	
	# 计算实际消耗的时间（考虑时间比例）
	var time_passed = delta
	if time_manager:
		# 使用TimeManager的时间流逝比例
		time_passed = delta * time_manager.time_scale
	
	var fuel_consumed = time_passed * fuel_consumption_rate
	current_fuel_time -= fuel_consumed

## 更新跟随位置
func _update_follow_position() -> void:
	if not player_node:
		return
	
	global_position = player_node.global_position + follow_offset

## 更新燃料指示器
func _update_fuel_indicator() -> void:
	fuel_updated.emit(current_fuel_time, max_fuel_time)
	
	# 根据燃料量调整光照强度
	var fuel_ratio = current_fuel_time / max_fuel_time
	# 燃料低于20%时开始闪烁
	if fuel_ratio < 0.2:
		_start_low_fuel_effect(fuel_ratio)
	else:
		_stop_low_fuel_effect()

## 燃料耗尽处理
func _fuel_depleted() -> void:
	is_fuel_active = false
	enabled = false
	fuel_depleted.emit()
	
	# 可以在这里触发重新点燃的UI提示
	print("火把燃料耗尽")

## 开始低燃料效果（闪烁）
func _start_low_fuel_effect(fuel_ratio: float) -> void:
	# 实现闪烁效果：通过调整强度或启用/禁用来实现
	# 简化实现：周期性调整强度
	pass

## 停止低燃料效果
func _stop_low_fuel_effect() -> void:
	# 恢复正常光照
	pass

## 装备火把到玩家
func equip_to_player(player: Node2D) -> void:
	player_node = player
	is_equipped = true
	enabled = true
	is_fuel_active = true
	
	# 设置跟随
	follow_player = true
	
	# 更新层级，确保火把在玩家之上
	z_index = player.z_index + 1
	
	torch_equipped.emit(true)

## 卸下火把
func unequip() -> void:
	is_equipped = false
	enabled = false
	follow_player = false
	player_node = null
	
	torch_equipped.emit(false)

## 重新点燃火把
func relight(fuel_amount: float = -1.0) -> void:
	if fuel_amount > 0:
		current_fuel_time = min(fuel_amount, max_fuel_time)
	else:
		# 默认重新加满
		current_fuel_time = max_fuel_time
	
	is_fuel_active = true
	enabled = true
	
	# 触发重新点燃效果
	print("火把重新点燃")

## 添加燃料
func add_fuel(fuel_amount: float) -> void:
	current_fuel_time = clamp(current_fuel_time + fuel_amount, 0.0, max_fuel_time)
	print("添加燃料: %f，当前燃料: %f" % [fuel_amount, current_fuel_time])

## 获取燃料比例
func get_fuel_ratio() -> float:
	return current_fuel_time / max_fuel_time

## 是否燃料充足（高于10%）
func has_sufficient_fuel() -> bool:
	return get_fuel_ratio() > 0.1

## 快速消耗燃料（用于特殊事件）
func consume_fuel_rapidly(amount: float) -> void:
	current_fuel_time = max(current_fuel_time - amount, 0.0)

## 处理玩家输入（可由PlayerController调用）
func handle_input(action: String) -> void:
	match action:
		"toggle_torch":
			toggle()
		"relight_torch":
			if not enabled:
				relight()

## 连接到玩家控制器信号
func connect_to_player_signals(player_controller: Node) -> void:
	# 这里可以连接玩家的相关信号
	# 例如：玩家切换武器、死亡等事件
	pass