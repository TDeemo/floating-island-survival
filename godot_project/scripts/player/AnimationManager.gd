## 动画管理器
## 管理空闲、行走、奔跑等基础动画状态，支持精灵方向切换
class_name AnimationManager
extends Node

## 动画状态枚举
enum AnimationState {
	IDLE,
	WALK,
	RUN,
	ATTACK,
	HURT,
	DEAD
}

## 移动方向枚举
enum MoveDirection {
	UP,
	DOWN,
	LEFT,
	RIGHT,
	UP_LEFT,
	UP_RIGHT,
	DOWN_LEFT,
	DOWN_RIGHT
}

## 精灵节点引用
@export var sprite: Sprite2D
## 动画播放器引用
@export var animation_player: AnimationPlayer
## 空闲动画速度阈值（像素/秒）
@export var idle_threshold: float = 10.0
## 行走动画速度阈值（像素/秒）
@export var walk_threshold: float = 150.0
## 奔跑动画速度阈值（像素/秒）
@export var run_threshold: float = 350.0

## 当前动画状态
var current_state: AnimationState = AnimationState.IDLE
## 前一个动画状态
var previous_state: AnimationState = AnimationState.IDLE
## 当前移动方向
var current_direction: MoveDirection = MoveDirection.DOWN
## 是否启用方向动画
var enable_direction_animations: bool = true

func _ready() -> void:
	# 如果没有指定精灵，尝试从父节点获取
	if not sprite:
		sprite = get_parent() as Sprite2D
	
	# 如果没有指定动画播放器，尝试从父节点获取
	if not animation_player:
		animation_player = get_parent().get_node_or_null("AnimationPlayer")

## 更新动画状态
## @param input_vector: 输入方向向量
## @param is_moving: 是否正在移动
## @param velocity: 当前速度向量
func update_animation(input_vector: Vector2, is_moving: bool, velocity: Vector2) -> void:
	# 更新移动方向
	_update_direction(input_vector)
	
	# 根据速度和输入确定动画状态
	var new_state := _determine_animation_state(is_moving, velocity.length())
	
	# 如果状态变化，播放动画
	if new_state != current_state:
		previous_state = current_state
		current_state = new_state
		_play_animation()

## 更新移动方向
func _update_direction(input_vector: Vector2) -> void:
	if input_vector == Vector2.ZERO:
		return
	
	# 计算角度（0-360度，0为右方向）
	var angle := rad_to_deg(input_vector.angle())
	if angle < 0:
		angle += 360
	
	# 将角度映射到八个方向
	if angle >= 337.5 or angle < 22.5:
		current_direction = MoveDirection.RIGHT
	elif angle >= 22.5 and angle < 67.5:
		current_direction = MoveDirection.DOWN_RIGHT
	elif angle >= 67.5 and angle < 112.5:
		current_direction = MoveDirection.DOWN
	elif angle >= 112.5 and angle < 157.5:
		current_direction = MoveDirection.DOWN_LEFT
	elif angle >= 157.5 and angle < 202.5:
		current_direction = MoveDirection.LEFT
	elif angle >= 202.5 and angle < 247.5:
		current_direction = MoveDirection.UP_LEFT
	elif angle >= 247.5 and angle < 292.5:
		current_direction = MoveDirection.UP
	elif angle >= 292.5 and angle < 337.5:
		current_direction = MoveDirection.UP_RIGHT

## 根据速度和移动状态确定动画状态
func _determine_animation_state(is_moving: bool, speed: float) -> AnimationState:
	if not is_moving or speed < idle_threshold:
		return AnimationState.IDLE
	elif speed < walk_threshold:
		return AnimationState.WALK
	elif speed < run_threshold:
		return AnimationState.RUN
	else:
		return AnimationState.RUN

## 播放当前状态的动画
func _play_animation() -> void:
	if not animation_player:
		return
	
	var animation_name := _get_animation_name()
	
	# 检查动画是否存在
	if animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
	else:
		push_warning("AnimationManager: Animation '%s' not found." % animation_name)

## 根据状态和方向生成动画名称
func _get_animation_name() -> String:
	var base_name := ""
	
	# 基础状态名称
	match current_state:
		AnimationState.IDLE:
			base_name = "idle"
		AnimationState.WALK:
			base_name = "walk"
		AnimationState.RUN:
			base_name = "run"
		AnimationState.ATTACK:
			base_name = "attack"
		AnimationState.HURT:
			base_name = "hurt"
		AnimationState.DEAD:
			base_name = "dead"
		_:
			base_name = "idle"
	
	# 如果启用方向动画，添加方向后缀
	if enable_direction_animations:
		var direction_suffix := ""
		
		match current_direction:
			MoveDirection.UP:
				direction_suffix = "_up"
			MoveDirection.DOWN:
				direction_suffix = "_down"
			MoveDirection.LEFT:
				direction_suffix = "_left"
			MoveDirection.RIGHT:
				direction_suffix = "_right"
			MoveDirection.UP_LEFT:
				direction_suffix = "_up_left"
			MoveDirection.UP_RIGHT:
				direction_suffix = "_up_right"
			MoveDirection.DOWN_LEFT:
				direction_suffix = "_down_left"
			MoveDirection.DOWN_RIGHT:
				direction_suffix = "_down_right"
			_:
				direction_suffix = "_down"
		
		return base_name + direction_suffix
	
	return base_name

## 设置精灵翻转（水平翻转）
func set_sprite_flip_h(flip: bool) -> void:
	if sprite:
		sprite.flip_h = flip

## 设置精灵翻转（垂直翻转）
func set_sprite_flip_v(flip: bool) -> void:
	if sprite:
		sprite.flip_v = flip

## 获取当前动画状态
func get_current_state() -> AnimationState:
	return current_state

## 获取当前移动方向
func get_current_direction() -> MoveDirection:
	return current_direction

## 获取动画名称（用于调试）
func get_current_animation_name() -> String:
	return _get_animation_name()

## 设置方向动画启用状态
func set_direction_animations_enabled(enabled: bool) -> void:
	enable_direction_animations = enabled