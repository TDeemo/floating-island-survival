## 动态光源基类
## 提供位置、范围、强度、衰减参数的基础光源组件
class_name LightSource
extends Node2D

# 导出变量 - 可在编辑器中配置
## 光源半径（像素）
@export var radius: float = 200.0
## 光源强度（0.0-1.0）
@export var intensity: float = 1.0
## 光源颜色
@export var color: Color = Color(1.0, 0.9, 0.7, 1.0)
## 是否启用衰减
@export var enable_attenuation: bool = true
## 衰减曲线（0.0-1.0，值越小衰减越陡）
@export var attenuation_curve: float = 0.5
## 是否启用光源（默认开启）
@export var enabled: bool = true:
	set(value):
		enabled = value
		_update_light_visibility()

## 是否启用怪物吸引
@export var attract_monsters: bool = true:
	set(value):
		attract_monsters = value
		_update_monster_attraction()

# 信号定义
## 光源状态变化（开启/关闭）
signal light_toggled(is_enabled: bool)
## 怪物吸引状态变化
signal monster_attraction_changed(is_attracting: bool)
## 光源参数变化（半径、强度等）
signal light_parameters_changed

# 内部组件引用
var _light_node: Light2D = null
var _sprite_node: Sprite2D = null

# 怪物吸引相关
var _attraction_range: float = 0.0
var _attraction_strength: float = 0.0
var _affected_monsters: Array[Node] = []

func _ready() -> void:
	# 确保有Light2D组件
	_setup_light_components()
	# 计算吸引范围（默认与光半径相同）
	_attraction_range = radius
	_attraction_strength = intensity
	# 初始更新
	_update_light_visibility()
	_update_monster_attraction()

## 初始化光源组件
func _setup_light_components() -> void:
	# 检查是否已有Light2D子节点
	_light_node = get_node_or_null("Light2D") as Light2D
	if not _light_node:
		# 创建新的Light2D节点
		_light_node = Light2D.new()
		_light_node.name = "Light2D"
		add_child(_light_node)
	
	# 检查是否已有Sprite2D子节点（可选视觉表现）
	_sprite_node = get_node_or_null("Sprite2D") as Sprite2D
	
	# 应用当前参数到Light2D节点
	_apply_light_parameters()

## 将当前参数应用到实际的Light2D节点
func _apply_light_parameters() -> void:
	if not _light_node:
		return
	
	# 设置Light2D属性
	_light_node.enabled = enabled
	_light_node.color = color
	_light_node.energy = intensity
	
	# 设置阴影和范围（通过缩放或范围参数）
	# 在Godot 4中，Light2D的范围通常通过texture或scale控制
	# 这里我们通过scale来模拟半径变化
	var scale_factor = radius / 100.0  # 假设基础半径为100像素
	_light_node.scale = Vector2(scale_factor, scale_factor)
	
	# 应用衰减（简化实现）
	if enable_attenuation:
		# 设置纹理或使用Shader实现衰减曲线
		_light_node.shadow_enabled = true
	else:
		_light_node.shadow_enabled = false
	
	light_parameters_changed.emit()

## 更新光源可见性
func _update_light_visibility() -> void:
	if _light_node:
		_light_node.enabled = enabled
	light_toggled.emit(enabled)

## 更新怪物吸引状态
func _update_monster_attraction() -> void:
	if attract_monsters:
		# 开始怪物吸引逻辑
		_start_monster_attraction()
	else:
		# 停止怪物吸引
		_stop_monster_attraction()
	
	monster_attraction_changed.emit(attract_monsters)

## 开始吸引怪物
func _start_monster_attraction() -> void:
	# 每帧检查范围内的怪物（通过Area2D或物理查询）
	# 简化实现：通过信号通知LightManager
	pass

## 停止吸引怪物
func _stop_monster_attraction() -> void:
	# 清除所有受影响怪物的吸引状态
	for monster in _affected_monsters:
		if is_instance_valid(monster):
			_clear_monster_attraction(monster)
	_affected_monsters.clear()

## 清除单个怪物的吸引状态
func _clear_monster_attraction(monster: Node) -> void:
	# 实现怪物吸引状态清除逻辑
	# 这里应调用怪物的相关方法
	pass

## 设置光源半径
func set_radius(new_radius: float) -> void:
	if new_radius <= 0:
		push_warning("光源半径必须大于0")
		return
	
	radius = new_radius
	_attraction_range = radius  # 吸引范围同步更新
	_apply_light_parameters()

## 设置光源强度
func set_intensity(new_intensity: float) -> void:
	intensity = clamp(new_intensity, 0.0, 2.0)
	_attraction_strength = intensity
	_apply_light_parameters()

## 设置光源颜色
func set_color(new_color: Color) -> void:
	color = new_color
	_apply_light_parameters()

## 开启光源
func turn_on() -> void:
	enabled = true

## 关闭光源
func turn_off() -> void:
	enabled = false

## 切换光源状态
func toggle() -> void:
	enabled = !enabled

## 获取当前是否吸引怪物
func is_attracting_monsters() -> bool:
	return attract_monsters and enabled

## 获取吸引范围
func get_attraction_range() -> float:
	return _attraction_range if enabled else 0.0

## 获取吸引强度
func get_attraction_strength() -> float:
	return _attraction_strength if enabled else 0.0

## 处理怪物进入吸引范围（应由Area2D触发）
func _on_monster_entered_range(monster: Node) -> void:
	if not enabled or not attract_monsters:
		return
	
	if not _affected_monsters.has(monster):
		_affected_monsters.append(monster)
		_apply_monster_attraction(monster)

## 处理怪物离开吸引范围
func _on_monster_exited_range(monster: Node) -> void:
	if _affected_monsters.has(monster):
		_affected_monsters.erase(monster)
		_clear_monster_attraction(monster)

## 应用怪物吸引效果
func _apply_monster_attraction(monster: Node) -> void:
	# 实现具体的怪物吸引逻辑
	# 例如：设置怪物的目标位置为光源位置
	pass