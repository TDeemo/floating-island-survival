## 攻击系统
## 处理武器攻击的碰撞检测、伤害计算和特效触发
class_name AttackSystem
extends Node2D

# 碰撞层掩码常量
const LAYER_PLAYER: int = 1 << 0
const LAYER_ENEMY: int = 1 << 1
const LAYER_RESOURCE: int = 1 << 2
const LAYER_TERRAIN: int = 1 << 3

# 伤害类型枚举
enum DamageType {
	PHYSICAL,  # 物理伤害
	FIRE,      # 火焰伤害
	ICE,       # 冰霜伤害
	POISON,    # 毒素伤害
	MAGIC      # 魔法伤害
}

# 导出变量
## 调试模式：显示攻击区域和命中信息
@export var debug_mode: bool = false

# 引用
var _world: Node2D = null

func _ready() -> void:
	# 尝试获取世界节点引用
	_world = get_tree().root.get_node_or_null("World")
	if not _world:
		_world = get_tree().current_scene

## 执行攻击
## @param weapon: 使用的武器实例
## @param attacker: 攻击者节点（通常是玩家）
func execute_attack(weapon: WeaponBase, attacker: Node2D) -> void:
	if not weapon or not attacker:
		print("错误：武器或攻击者无效")
		return
	
	# 根据武器类型执行不同的攻击逻辑
	match weapon.weapon_type:
		WeaponBase.WeaponType.MELEE:
			_execute_melee_attack(weapon, attacker)
		WeaponBase.WeaponType.RANGED:
			_execute_ranged_attack(weapon, attacker)
		WeaponBase.WeaponType.MAGIC:
			_execute_magic_attack(weapon, attacker)

## 执行近战攻击
func _execute_melee_attack(weapon: WeaponBase, attacker: Node2D) -> void:
	# 创建近战攻击区域
	var attack_area := Area2D.new()
	attack_area.name = "MeleeAttackArea"
	attack_area.collision_layer = LAYER_ENEMY | LAYER_RESOURCE
	attack_area.collision_mask = LAYER_ENEMY | LAYER_RESOURCE
	
	# 创建碰撞形状（圆形）
	var shape := CircleShape2D.new()
	shape.radius = weapon.attack_range
	
	var collision_shape := CollisionShape2D.new()
	collision_shape.shape = shape
	attack_area.add_child(collision_shape)
	
	# 设置攻击区域位置（在攻击者前方）
	var attack_position = attacker.position + attacker.transform.x * weapon.attack_range * 0.5
	attack_area.position = attack_position
	
	# 添加到场景
	_world.add_child(attack_area)
	
	# 连接信号检测碰撞
	attack_area.body_entered.connect(_on_melee_hit.bind(weapon, attacker))
	
	# 设置短暂存在后移除
	_remove_after_delay(attack_area, 0.2)
	
	if debug_mode:
		print("近战攻击执行：位置=%s，范围=%.1f" % [attack_position, weapon.attack_range])

## 执行远程攻击
func _execute_ranged_attack(weapon: WeaponBase, attacker: Node2D) -> void:
	# 创建远程弹道（箭矢/子弹）
	var projectile := Sprite2D.new()
	projectile.name = "Projectile"
	projectile.texture = load("res://assets/sprites/Square.png")  # 临时纹理
	projectile.scale = Vector2(0.3, 0.3)
	
	# 创建Area2D用于碰撞检测
	var projectile_area := Area2D.new()
	projectile_area.name = "ProjectileArea"
	projectile_area.collision_layer = LAYER_ENEMY | LAYER_RESOURCE
	projectile_area.collision_mask = LAYER_ENEMY | LAYER_RESOURCE | LAYER_TERRAIN
	
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	
	var collision_shape := CollisionShape2D.new()
	collision_shape.shape = shape
	projectile_area.add_child(collision_shape)
	projectile_area.add_child(projectile)
	
	# 设置初始位置和方向
	projectile_area.position = attacker.position
	var direction = attacker.get_global_mouse_position() - attacker.global_position
	if direction.length() > 0:
		direction = direction.normalized()
	else:
		direction = Vector2.RIGHT  # 默认方向
	
	# 添加到场景
	_world.add_child(projectile_area)
	
	# 设置移动速度
	var speed: float = 500.0  # 像素/秒
	var max_distance: float = 800.0  # 最大射程
	
	# 使用Tween实现移动
	var tween := create_tween()
	tween.tween_method(
		_update_projectile_position.bind(projectile_area, direction, speed, weapon, attacker),
		0.0, max_distance / speed, max_distance / speed
	)
	tween.tween_callback(_remove_node.bind(projectile_area))
	
	if debug_mode:
		print("远程攻击执行：方向=%s，速度=%.1f" % [direction, speed])

## 更新弹道位置的方法
func _update_projectile_position(time: float, projectile: Node2D, direction: Vector2, speed: float, weapon: WeaponBase, attacker: Node2D) -> void:
	var new_position = projectile.position + direction * speed * get_process_delta_time()
	projectile.position = new_position

## 执行魔法攻击
func _execute_magic_attack(weapon: WeaponBase, attacker: Node2D) -> void:
	# 创建魔法效果区域
	var magic_area := Area2D.new()
	magic_area.name = "MagicAttackArea"
	magic_area.collision_layer = LAYER_ENEMY
	magic_area.collision_mask = LAYER_ENEMY
	
	# 创建碰撞形状（较大的圆形）
	var shape := CircleShape2D.new()
	shape.radius = weapon.attack_range * 1.5  # 魔法范围更大
	
	var collision_shape := CollisionShape2D.new()
	collision_shape.shape = shape
	magic_area.add_child(collision_shape)
	
	# 设置位置（目标位置或鼠标位置）
	var target_position = attacker.get_global_mouse_position()
	magic_area.position = target_position
	
	# 添加到场景
	_world.add_child(magic_area)
	
	# 连接信号检测碰撞
	magic_area.body_entered.connect(_on_magic_hit.bind(weapon, attacker))
	
	# 设置存在时间
	_remove_after_delay(magic_area, 1.0)
	
	if debug_mode:
		print("魔法攻击执行：目标位置=%s，范围=%.1f" % [target_position, weapon.attack_range])

## 近战命中处理
func _on_melee_hit(body: Node2D, weapon: WeaponBase, attacker: Node2D) -> void:
	_apply_damage(body, weapon, attacker, DamageType.PHYSICAL)

## 魔法命中处理
func _on_magic_hit(body: Node2D, weapon: WeaponBase, attacker: Node2D) -> void:
	# 魔法攻击默认为魔法伤害类型
	_apply_damage(body, weapon, attacker, DamageType.MAGIC)

## 应用伤害
func _apply_damage(target: Node2D, weapon: WeaponBase, attacker: Node2D, damage_type: DamageType) -> void:
	if not target or not weapon:
		return
	
	# 计算基础伤害
	var damage = weapon.base_damage
	
	# 根据伤害类型应用修正（这里简化处理）
	match damage_type:
		DamageType.FIRE:
			damage *= 1.2  # 火焰伤害增加20%
		DamageType.ICE:
			damage *= 0.9  # 冰霜伤害减少10%（但有减速效果）
		DamageType.POISON:
			damage *= 0.8  # 毒素伤害减少20%（但有持续伤害）
	
	# 应用伤害
	if target.has_method("take_damage"):
		target.take_damage(damage, attacker, damage_type)
		if debug_mode:
			print("伤害应用：目标=%s，伤害=%.1f，类型=%s" % [target.name, damage, damage_type])
	else:
		if debug_mode:
			print("目标无法接收伤害：%s" % target.name)

## 延迟移除节点
func _remove_after_delay(node: Node, delay: float) -> void:
	if not node:
		return
	
	var timer := Timer.new()
	node.add_child(timer)
	timer.wait_time = delay
	timer.one_shot = true
	timer.timeout.connect(_remove_node.bind(node))
	timer.start()

## 移除节点
func _remove_node(node: Node) -> void:
	if node and is_instance_valid(node):
		node.queue_free()