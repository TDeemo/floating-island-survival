## 武器基类
## 定义武器的基础属性、类型和攻击接口
class_name WeaponBase
extends Node2D

# 武器类型枚举
enum WeaponType {
	MELEE,   # 近战武器（剑、斧、锤）
	RANGED,  # 远程武器（弓、弩、投石索）
	MAGIC    # 魔法武器（法杖、魔导书）
}

# 导出变量 - 可在编辑器中配置
## 武器类型
@export var weapon_type: WeaponType = WeaponType.MELEE
## 基础伤害值
@export var base_damage: float = 10.0
## 攻击速度（每秒攻击次数）
@export var attack_speed: float = 1.0
## 攻击范围（像素），对近战武器有效
@export var attack_range: float = 50.0
## 最大耐久度
@export var max_durability: float = 100.0
## 当前耐久度
@export var current_durability: float = 100.0
## 武器名称
@export var weapon_name: String = "未命名武器"
## 武器描述
@export_multiline var weapon_description: String = ""

# 攻击冷却计时器
var _attack_cooldown: float = 0.0
# 是否正在攻击
var _is_attacking: bool = false
# 武器持有者引用（通常是玩家角色）
var _owner: Node2D = null
# 攻击系统引用
var _attack_system: AttackSystem = null

func _ready() -> void:
	# 初始化攻击冷却为可立即攻击
	_attack_cooldown = 0.0
	_is_attacking = false

func _process(delta: float) -> void:
	# 更新攻击冷却
	if _attack_cooldown > 0:
		_attack_cooldown = max(_attack_cooldown - delta, 0.0)

## 设置武器持有者
func set_owner(owner_node: Node2D) -> void:
	_owner = owner_node

## 设置攻击系统引用
func set_attack_system(attack_system: AttackSystem) -> void:
	_attack_system = attack_system

## 开始攻击（由外部调用，如玩家输入）
func start_attack() -> bool:
	if _attack_cooldown > 0 or _is_attacking:
		return false  # 冷却中或正在攻击
	
	# 检查耐久度
	if current_durability <= 0:
		print("武器耐久度已耗尽")
		return false
	
	_is_attacking = true
	_attack_cooldown = 1.0 / attack_speed  # 设置冷却时间
	
	# 触发实际攻击逻辑
	_perform_attack()
	
	# 消耗耐久度
	current_durability = max(current_durability - 1, 0)
	
	return true

## 停止攻击
func stop_attack() -> void:
	_is_attacking = false

## 执行具体攻击逻辑（由子类重写）
func _perform_attack() -> void:
	if _attack_system:
		_attack_system.execute_attack(self, _owner)
	else:
		print("警告：没有攻击系统引用，无法执行攻击")

## 检查是否可以攻击
func can_attack() -> bool:
	return _attack_cooldown <= 0 and current_durability > 0 and not _is_attacking

## 获取攻击冷却进度（0-1）
func get_cooldown_progress() -> float:
	if attack_speed == 0:
		return 1.0
	return 1.0 - (_attack_cooldown * attack_speed)

## 修复武器（恢复耐久度）
func repair(amount: float) -> void:
	current_durability = min(current_durability + amount, max_durability)

## 检查武器是否已损坏（耐久度 <= 0）
func is_broken() -> bool:
	return current_durability <= 0

## 获取武器信息字符串
func get_weapon_info() -> String:
	var type_str: String
	match weapon_type:
		WeaponType.MELEE:
			type_str = "近战武器"
		WeaponType.RANGED:
			type_str = "远程武器"
		WeaponType.MAGIC:
			type_str = "魔法武器"
	
	return "%s - %s\n伤害: %.1f\n攻击速度: %.2f/秒\n范围: %.1f像素\n耐久度: %.0f/%.0f" % [
		weapon_name, type_str, base_damage, attack_speed, attack_range,
		current_durability, max_durability
	]