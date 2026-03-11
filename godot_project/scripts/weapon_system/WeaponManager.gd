## 武器管理器
## 负责玩家武器管理：装备、切换、攻击触发
class_name WeaponManager
extends Node2D

# 导出变量
## 当前装备的武器实例
@export var current_weapon: WeaponBase = null
## 攻击系统引用
@export var attack_system: AttackSystem = null
## 武器槽列表（可在编辑器中预设）
@export var weapon_slots: Array[WeaponBase] = []
## 是否允许攻击
@export var can_attack: bool = true

# 内部变量
var _current_slot_index: int = -1
var _weapons: Dictionary = {}  # 武器ID到武器实例的映射
var _input_enabled: bool = true

func _ready() -> void:
	# 初始化武器系统
	_initialize_weapon_system()

func _process(_delta: float) -> void:
	# 处理攻击输入
	_process_attack_input()

func _initialize_weapon_system() -> void:
	# 如果没有攻击系统，尝试查找或创建
	if not attack_system:
		attack_system = get_parent().get_node_or_null("AttackSystem")
		if not attack_system:
			# 创建新的攻击系统
			attack_system = AttackSystem.new()
			attack_system.name = "AttackSystem"
			get_parent().add_child(attack_system)
	
	# 初始化武器槽
	if weapon_slots.size() > 0:
		for i in range(weapon_slots.size()):
			var weapon = weapon_slots[i]
			if weapon:
				_add_weapon(weapon)
		
		# 装备第一个可用武器
		if _weapons.size() > 0:
			_equip_weapon_by_id(_weapons.keys()[0])

## 处理攻击输入
func _process_attack_input() -> void:
	if not _input_enabled or not can_attack:
		return
	
	# 检测攻击按键（鼠标左键或空格键）
	if Input.is_action_just_pressed("attack"):
		_start_attack()
	elif Input.is_action_just_released("attack"):
		_stop_attack()
	
	# 检测武器切换按键（数字键1-4）
	for i in range(1, 5):
		if Input.is_action_just_pressed("weapon_slot_" + str(i)):
			_switch_to_slot(i - 1)  # 转换为0索引

## 开始攻击
func _start_attack() -> bool:
	if not current_weapon or not can_attack:
		return false
	
	# 设置武器持有者和攻击系统引用
	if current_weapon._owner == null:
		current_weapon.set_owner(get_parent())
	
	if current_weapon._attack_system == null:
		current_weapon.set_attack_system(attack_system)
	
	# 调用武器的攻击方法
	return current_weapon.start_attack()

## 停止攻击
func _stop_attack() -> void:
	if current_weapon:
		current_weapon.stop_attack()

## 添加武器到管理器
func add_weapon(weapon: WeaponBase) -> bool:
	return _add_weapon(weapon)

func _add_weapon(weapon: WeaponBase) -> bool:
	if not weapon:
		return false
	
	# 生成唯一ID
	var weapon_id = "weapon_" + str(_weapons.size())
	
	# 设置武器节点父子关系
	if weapon.get_parent() != self:
		add_child(weapon)
	
	# 存储引用
	_weapons[weapon_id] = weapon
	
	print("武器添加：%s（ID：%s）" % [weapon.weapon_name, weapon_id])
	return true

## 通过ID装备武器
func equip_weapon_by_id(weapon_id: String) -> bool:
	return _equip_weapon_by_id(weapon_id)

func _equip_weapon_by_id(weapon_id: String) -> bool:
	if not weapon_id in _weapons:
		print("错误：武器ID不存在 - %s" % weapon_id)
		return false
	
	var weapon = _weapons[weapon_id]
	
	# 更新当前武器
	current_weapon = weapon
	
	# 更新槽索引（如果在槽中）
	_current_slot_index = -1
	for i in range(weapon_slots.size()):
		if weapon_slots[i] == weapon:
			_current_slot_index = i
			break
	
	print("武器装备：%s" % weapon.weapon_name)
	return true

## 切换到指定槽位
func switch_to_slot(slot_index: int) -> bool:
	return _switch_to_slot(slot_index)

func _switch_to_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= weapon_slots.size():
		print("错误：槽位索引越界 - %d" % slot_index)
		return false
	
	var weapon = weapon_slots[slot_index]
	if not weapon:
		print("错误：槽位 %d 没有武器" % slot_index)
		return false
	
	# 装备该武器
	current_weapon = weapon
	_current_slot_index = slot_index
	
	print("切换到槽位 %d：%s" % [slot_index + 1, weapon.weapon_name])
	return true

## 通过预制体路径创建并添加武器
func create_and_add_weapon(weapon_scene_path: String) -> WeaponBase:
	var weapon_scene = load(weapon_scene_path)
	if not weapon_scene:
		print("错误：无法加载武器场景 - %s" % weapon_scene_path)
		return null
	
	var weapon_instance = weapon_scene.instantiate()
	if not weapon_instance is WeaponBase:
		print("错误：加载的场景不是WeaponBase类型")
		weapon_instance.queue_free()
		return null
	
	_add_weapon(weapon_instance)
	return weapon_instance

## 移除武器
func remove_weapon(weapon_id: String) -> bool:
	if not weapon_id in _weapons:
		return false
	
	var weapon = _weapons[weapon_id]
	
	# 如果要移除的是当前武器，先取消装备
	if current_weapon == weapon:
		current_weapon = null
		_current_slot_index = -1
	
	# 从字典中移除
	_weapons.erase(weapon_id)
	
	# 从场景中移除
	if weapon and is_instance_valid(weapon):
		weapon.queue_free()
	
	print("武器移除：%s" % weapon_id)
	return true

## 获取当前武器信息
func get_current_weapon_info() -> String:
	if not current_weapon:
		return "没有装备武器"
	
	return current_weapon.get_weapon_info()

## 获取所有武器列表
func get_weapon_list() -> Array:
	var weapons = []
	for weapon_id in _weapons:
		weapons.append({
			"id": weapon_id,
			"name": _weapons[weapon_id].weapon_name,
			"type": _weapons[weapon_id].weapon_type,
			"damage": _weapons[weapon_id].base_damage
		})
	
	return weapons

## 启用/禁用攻击输入
func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if not enabled:
		_stop_attack()

## 修复当前武器
func repair_current_weapon(amount: float) -> void:
	if current_weapon:
		current_weapon.repair(amount)
		print("武器修复：恢复 %.0f 点耐久度" % amount)

## 检查当前武器是否已损坏
func is_current_weapon_broken() -> bool:
	if not current_weapon:
		return true
	
	return current_weapon.is_broken()