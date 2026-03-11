## 玩家角色控制器
## 处理WASD/方向键输入，实现加速度/减速度物理效果，处理碰撞检测
class_name PlayerController
extends CharacterBody2D

## 移动速度（像素/秒）
@export var speed: float = 300.0
## 加速度（像素/秒²），值越大加速越快
@export var acceleration: float = 1500.0
## 减速度（像素/秒²），值越大减速越快
@export var deceleration: float = 1800.0
## 最大速度（像素/秒），防止速度无限增加
@export var max_speed: float = 500.0

## 当前移动输入向量，用于动画状态机
var move_input: Vector2 = Vector2.ZERO
## 当前实际速度向量
var current_velocity: Vector2 = Vector2.ZERO
## 是否正在移动
var is_moving: bool = false

## 动画管理器引用
@export var animation_manager: AnimationManager

func _ready() -> void:
	# 如果没有指定动画管理器，尝试从子节点获取
	if not animation_manager:
		animation_manager = get_node_or_null("AnimationManager")

func _physics_process(delta: float) -> void:
	# 获取输入向量（-1到1的范围）
	var input_vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	
	move_input = input_vector
	
	# 计算目标速度
	var target_velocity := input_vector * speed
	
	# 应用加速度/减速度
	if input_vector != Vector2.ZERO:
		# 加速朝向目标速度
		current_velocity = current_velocity.move_toward(target_velocity, acceleration * delta)
		is_moving = true
	else:
		# 减速至零
		current_velocity = current_velocity.move_toward(Vector2.ZERO, deceleration * delta)
		is_moving = false
	
	# 限制最大速度
	if current_velocity.length() > max_speed:
		current_velocity = current_velocity.normalized() * max_speed
	
	# 设置角色速度
	velocity = current_velocity
	
	# 移动并处理碰撞
	move_and_slide()
	
	# 更新动画状态
	if animation_manager:
		animation_manager.update_animation(move_input, is_moving, current_velocity)

## 获取当前移动输入方向（用于外部查询）
func get_move_direction() -> Vector2:
	return move_input

## 获取当前速度（用于外部查询）
func get_current_velocity() -> Vector2:
	return current_velocity

## 获取是否正在移动（用于外部查询）
func is_player_moving() -> bool:
	return is_moving

## 设置动画管理器引用
func set_animation_manager(manager: AnimationManager) -> void:
	animation_manager = manager