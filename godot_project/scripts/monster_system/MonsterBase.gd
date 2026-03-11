## 怪物基类
## 定义怪物的基础属性、类型和状态机
class_name MonsterBase
extends CharacterBody2D

# 怪物类型枚举（与生态环境匹配）
enum MonsterType {
	MELEE,      # 近战型
	RANGED,     # 远程型
	MAGIC,      # 魔法型
	FLYING,     # 飞行型
	BOSS        # BOSS型
}

# 导出变量 - 可在编辑器中配置
## 怪物类型
@export var monster_type: MonsterType = MonsterType.MELEE
## 基础生命值
@export var base_health: float = 50.0
## 当前生命值
@export var current_health: float = 50.0
## 基础攻击力
@export var base_attack: float = 10.0
## 移动速度（像素/秒）
@export var move_speed: float = 100.0
## 攻击范围（像素）
@export var attack_range: float = 50.0
## 追逐范围（像素），超过此范围停止追击
@export var chase_range: float = 300.0
## 视野范围（像素），在此范围内发现玩家
@export var sight_range: float = 200.0
## 怪物名称
@export var monster_name: String = "未命名怪物"
## 怪物描述
@export_multiline var monster_description: String = ""
## 是否在夜晚增强
@export var enhanced_at_night: bool = true
## 夜晚增强倍率（攻击力、移动速度等）
@export var night_enhancement_multiplier: float = 1.5

# 关联的生态环境类型（BiomeManager.BiomeType）
var associated_biome: int = -1  # -1表示未指定

# 状态机状态
enum MonsterState {
	IDLE,       # 空闲/待机
	PATROL,     # 巡逻
	CHASE,      # 追击
	ATTACK,     # 攻击
	DEAD,       # 死亡
	RETURNING   # 返回巡逻点
}

var current_state: MonsterState = MonsterState.IDLE
var previous_state: MonsterState = MonsterState.IDLE

# 目标引用（通常是玩家）
var target: Node2D = null

# 巡逻相关
var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0
var patrol_radius: float = 100.0

# 攻击冷却
var attack_cooldown: float = 0.0
var attack_cooldown_timer: float = 1.0  # 默认1秒攻击间隔

# 掉落物品配置
## 掉落资源类型（"wood", "ore", "herb"等）
@export var drop_resource_type: String = ""
## 掉落数量（基础值）
@export var drop_amount_min: int = 1
@export var drop_amount_max: int = 3
## 掉落武器概率（0-1）
@export var drop_weapon_chance: float = 0.1
## 掉落武器类型（WeaponBase.WeaponType）
@export var drop_weapon_type: int = 0

# 动画组件引用
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# 初始化当前生命值
	current_health = base_health
	# 初始化状态
	current_state = MonsterState.IDLE
	# 如果没有动画组件，则警告
	if not animation_player:
		push_warning("怪物 %s 缺少AnimationPlayer组件" % monster_name)
	if not sprite:
		push_warning("怪物 %s 缺少Sprite2D组件" % monster_name)

func _process(delta: float) -> void:
	# 更新攻击冷却
	if attack_cooldown > 0:
		attack_cooldown = max(attack_cooldown - delta, 0.0)
	
	# 根据状态处理逻辑
	_process_state(delta)

func _process_state(delta: float) -> void:
	match current_state:
		MonsterState.IDLE:
			_process_idle(delta)
		MonsterState.PATROL:
			_process_patrol(delta)
		MonsterState.CHASE:
			_process_chase(delta)
		MonsterState.ATTACK:
			_process_attack(delta)
		MonsterState.DEAD:
			_process_dead(delta)
		MonsterState.RETURNING:
			_process_returning(delta)

func _process_idle(delta: float) -> void:
	# 空闲状态，可随机转为巡逻
	if patrol_points.size() > 0:
		_change_state(MonsterState.PATROL)
	# 检查是否有目标进入视野
	_check_for_target()

func _process_patrol(delta: float) -> void:
	if patrol_points.size() == 0:
		_change_state(MonsterState.IDLE)
		return
	
	# 移动到当前巡逻点
	var target_point = patrol_points[current_patrol_index]
	var direction = (target_point - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
	
	# 到达巡逻点
	if global_position.distance_to(target_point) < 10.0:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		# 随机等待一下
		await get_tree().create_timer(randf_range(1.0, 3.0)).timeout
	
	# 检查是否有目标进入视野
	_check_for_target()

func _process_chase(delta: float) -> void:
	if not target:
		_change_state(MonsterState.RETURNING)
		return
	
	# 追逐目标
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
	
	# 检查是否进入攻击范围
	if global_position.distance_to(target.global_position) <= attack_range:
		_change_state(MonsterState.ATTACK)
	
	# 检查是否超出追逐范围
	if global_position.distance_to(target.global_position) > chase_range:
		_change_state(MonsterState.RETURNING)

func _process_attack(delta: float) -> void:
	if not target:
		_change_state(MonsterState.RETURNING)
		return
	
	# 停止移动
	velocity = Vector2.ZERO
	
	# 检查目标是否仍在攻击范围内
	if global_position.distance_to(target.global_position) > attack_range:
		_change_state(MonsterState.CHASE)
		return
	
	# 执行攻击（如果冷却完成）
	if attack_cooldown <= 0:
		_execute_attack()
		attack_cooldown = attack_cooldown_timer

func _process_dead(delta: float) -> void:
	# 死亡状态，停止所有移动
	velocity = Vector2.ZERO
	# 可以播放死亡动画，然后移除节点
	# 这里由外部管理

func _process_returning(delta: float) -> void:
	# 返回巡逻点
	if patrol_points.size() == 0:
		_change_state(MonsterState.IDLE)
		return
	
	# 返回第一个巡逻点
	var home_point = patrol_points[0]
	var direction = (home_point - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
	
	# 到达后转为空闲
	if global_position.distance_to(home_point) < 10.0:
		_change_state(MonsterState.IDLE)

## 检查是否有目标进入视野
func _check_for_target() -> void:
	# 这里实现实际的目标检测逻辑
	# 暂时留空，由MonsterAI组件实现
	pass

## 执行攻击动作
func _execute_attack() -> void:
	# 播放攻击动画
	if animation_player:
		animation_player.play("attack")
	
	# 实际伤害计算由攻击系统处理
	# 这里可以触发信号
	emit_signal("monster_attacked", self)

## 切换状态
func _change_state(new_state: MonsterState) -> void:
	if current_state == new_state:
		return
	
	previous_state = current_state
	current_state = new_state
	
	# 状态进入处理
	_on_state_entered(new_state, previous_state)

## 状态进入处理
func _on_state_entered(new_state: MonsterState, old_state: MonsterState) -> void:
	match new_state:
		MonsterState.IDLE:
			if animation_player:
				animation_player.play("idle")
		MonsterState.PATROL:
			if animation_player:
				animation_player.play("walk")
		MonsterState.CHASE:
			if animation_player:
				animation_player.play("run")
		MonsterState.ATTACK:
			if animation_player:
				animation_player.play("attack_ready")
		MonsterState.DEAD:
			if animation_player:
				animation_player.play("die")
			# 触发死亡事件
			emit_signal("monster_died", self)
		MonsterState.RETURNING:
			if animation_player:
				animation_player.play("walk")

## 受到伤害
func take_damage(damage: float, source: Node = null) -> void:
	if current_state == MonsterState.DEAD:
		return
	
	current_health = max(current_health - damage, 0)
	
	# 触发受伤动画
	if animation_player:
		animation_player.play("hurt")
	
	# 如果受到玩家伤害，则开始追击
	if source and source.is_in_group("player"):
		target = source
		if current_state != MonsterState.CHASE and current_state != MonsterState.ATTACK:
			_change_state(MonsterState.CHASE)
	
	# 检查死亡
	if current_health <= 0:
		_die()

## 死亡处理
func _die() -> void:
	_change_state(MonsterState.DEAD)
	
	# 触发掉落
	_drop_items()
	
	# 可以在这里安排节点移除
	# await get_tree().create_timer(2.0).timeout
	# queue_free()

## 掉落物品
func _drop_items() -> void:
	if drop_resource_type:
		var amount = randi_range(drop_amount_min, drop_amount_max)
		emit_signal("resource_dropped", drop_resource_type, amount, global_position)
	
	if randf() < drop_weapon_chance:
		emit_signal("weapon_dropped", drop_weapon_type, global_position)

## 设置目标
func set_target(new_target: Node2D) -> void:
	target = new_target
	if target and current_state != MonsterState.CHASE and current_state != MonsterState.ATTACK:
		_change_state(MonsterState.CHASE)

## 设置巡逻点
func set_patrol_points(points: Array[Vector2]) -> void:
	patrol_points = points
	if patrol_points.size() > 0 and current_state == MonsterState.IDLE:
		_change_state(MonsterState.PATROL)

## 应用夜晚增强
func apply_night_enhancement() -> void:
	if enhanced_at_night:
		move_speed *= night_enhancement_multiplier
		base_attack *= night_enhancement_multiplier
		chase_range *= night_enhancement_multiplier

## 移除夜晚增强
func remove_night_enhancement() -> void:
	if enhanced_at_night:
		move_speed /= night_enhancement_multiplier
		base_attack /= night_enhancement_multiplier
		chase_range /= night_enhancement_multiplier

# 信号定义
signal monster_attacked(monster: MonsterBase)
signal monster_died(monster: MonsterBase)
signal resource_dropped(resource_type: String, amount: int, position: Vector2)
signal weapon_dropped(weapon_type: int, position: Vector2)