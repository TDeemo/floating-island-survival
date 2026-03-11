## 武器工厂
## 负责武器制作、掉落生成和武器实例化
class_name WeaponFactory
extends Node2D

# 武器配方结构
class WeaponRecipe:
	var weapon_id: String
	var weapon_name: String
	var weapon_type: WeaponBase.WeaponType
	var base_damage: float
	var attack_speed: float
	var attack_range: float
	var durability: float
	var required_resources: Dictionary  # 资源类型 -> 数量
	var weapon_scene_path: String  # 预制体路径
	
	func _init(id: String, name: String, type: WeaponBase.WeaponType, damage: float, 
			  speed: float, range: float, durability_val: float, resources: Dictionary, 
			  scene_path: String) -> void:
		weapon_id = id
		weapon_name = name
		weapon_type = type
		base_damage = damage
		attack_speed = speed
		attack_range = range
		durability = durability_val
		required_resources = resources
		weapon_scene_path = scene_path

# 导出变量
## 调试模式
@export var debug_mode: bool = false

# 配方数据库
var _recipes: Dictionary = {}
# 武器掉落表
var _drop_tables: Dictionary = {}
# 武器品质概率
var _rarity_probabilities: Dictionary = {
	"common": 0.7,
	"uncommon": 0.2,
	"rare": 0.08,
	"epic": 0.02
}

func _ready() -> void:
	# 初始化默认配方
	_initialize_default_recipes()
	
	# 初始化掉落表
	_initialize_drop_tables()

func _initialize_default_recipes() -> void:
	# 定义基础武器配方（使用ResourceType枚举）
	var wood_sword_recipe = WeaponRecipe.new(
		"wood_sword",
		"木剑",
		WeaponBase.WeaponType.MELEE,
		8.0,    # 伤害
		1.2,    # 攻击速度
		50.0,   # 范围
		50.0,   # 耐久度
		{ResourceNode.ResourceType.WOOD: 5},  # 需要5木材
		"res://scenes/weapons/wood_sword.tscn"
	)
	
	var stone_axe_recipe = WeaponRecipe.new(
		"stone_axe",
		"石斧",
		WeaponBase.WeaponType.MELEE,
		12.0,   # 伤害
		1.0,    # 攻击速度
		60.0,   # 范围
		80.0,   # 耐久度
		{
			ResourceNode.ResourceType.WOOD: 3,
			ResourceNode.ResourceType.ORE: 5
		},
		"res://scenes/weapons/stone_axe.tscn"
	)
	
	var iron_sword_recipe = WeaponRecipe.new(
		"iron_sword",
		"铁剑",
		WeaponBase.WeaponType.MELEE,
		18.0,   # 伤害
		1.0,    # 攻击速度
		55.0,   # 范围
		120.0,  # 耐久度
		{
			ResourceNode.ResourceType.WOOD: 2,
			ResourceNode.ResourceType.ORE: 8
		},
		"res://scenes/weapons/iron_sword.tscn"
	)
	
	var short_bow_recipe = WeaponRecipe.new(
		"short_bow",
		"短弓",
		WeaponBase.WeaponType.RANGED,
		10.0,   # 伤害
		0.8,    # 攻击速度
		300.0,  # 范围
		70.0,   # 耐久度
		{
			ResourceNode.ResourceType.WOOD: 8,
			ResourceNode.ResourceType.HERB: 2
		},
		"res://scenes/weapons/short_bow.tscn"
	)
	
	var fire_staff_recipe = WeaponRecipe.new(
		"fire_staff",
		"火焰法杖",
		WeaponBase.WeaponType.MAGIC,
		25.0,   # 伤害
		0.4,    # 攻击速度
		200.0,  # 范围
		100.0,  # 耐久度
		{
			ResourceNode.ResourceType.WOOD: 10,
			ResourceNode.ResourceType.ORE: 5,
			ResourceNode.ResourceType.HERB: 3
		},
		"res://scenes/weapons/fire_staff.tscn"
	)
	
	# 添加到配方数据库
	_recipes[wood_sword_recipe.weapon_id] = wood_sword_recipe
	_recipes[stone_axe_recipe.weapon_id] = stone_axe_recipe
	_recipes[iron_sword_recipe.weapon_id] = iron_sword_recipe
	_recipes[short_bow_recipe.weapon_id] = short_bow_recipe
	_recipes[fire_staff_recipe.weapon_id] = fire_staff_recipe
	
	if debug_mode:
		print("武器配方初始化完成，共 %d 个配方" % _recipes.size())

func _initialize_drop_tables() -> void:
	# 怪物掉落表（怪物类型 -> [武器ID数组]）
	_drop_tables["enemy_melee"] = ["wood_sword", "stone_axe"]
	_drop_tables["enemy_ranged"] = ["short_bow"]
	_drop_tables["enemy_magic"] = ["fire_staff"]
	_drop_tables["boss"] = ["iron_sword", "fire_staff"]
	
	# 宝箱掉落表（宝箱等级 -> [武器ID数组]）
	_drop_tables["chest_common"] = ["wood_sword"]
	_drop_tables["chest_uncommon"] = ["stone_axe", "short_bow"]
	_drop_tables["chest_rare"] = ["iron_sword"]
	_drop_tables["chest_epic"] = ["fire_staff"]
	
	if debug_mode:
		print("掉落表初始化完成")

## 检查是否拥有足够资源制作武器
## @param recipe_id: 配方ID
## @param inventory: 库存管理器引用
## @return: 是否拥有足够资源
func can_craft_weapon(recipe_id: String, inventory: Node) -> bool:
	if not recipe_id in _recipes:
		print("错误：配方ID不存在 - %s" % recipe_id)
		return false
	
	var recipe = _recipes[recipe_id]
	
	# 检查库存管理器是否有take_resource方法（与InventoryManager兼容）
	if not inventory.has_method("take_resource"):
		print("错误：库存管理器没有take_resource方法")
		return false
	
	# 检查每种资源是否足够
	for resource_type in recipe.required_resources:
		var required_amount = recipe.required_resources[resource_type]
		
		# 调用库存管理器检查资源数量
		# 假设inventory.has_resource(type, amount)或类似方法
		# 这里简化处理，实际需要根据InventoryManager的实现调整
		if not _check_resource_availability(inventory, resource_type, required_amount):
			return false
	
	return true

## 制作武器
## @param recipe_id: 配方ID
## @param inventory: 库存管理器引用
## @param weapon_manager: 武器管理器引用（用于添加制作好的武器）
## @return: 制作的武器实例，失败返回null
func craft_weapon(recipe_id: String, inventory: Node, weapon_manager: Node) -> WeaponBase:
	if not can_craft_weapon(recipe_id, inventory):
		print("无法制作武器：资源不足或配方无效")
		return null
	
	var recipe = _recipes[recipe_id]
	
	# 从库存中消耗资源
	for resource_type in recipe.required_resources:
		var amount = recipe.required_resources[resource_type]
		_consume_resource(inventory, resource_type, amount)
	
	# 加载并实例化武器预制体
	var weapon_instance = load(recipe.weapon_scene_path).instantiate()
	if not weapon_instance is WeaponBase:
		print("错误：加载的武器预制体不是WeaponBase类型")
		return null
	
	# 配置武器属性
	weapon_instance.weapon_type = recipe.weapon_type
	weapon_instance.base_damage = recipe.base_damage
	weapon_instance.attack_speed = recipe.attack_speed
	weapon_instance.attack_range = recipe.attack_range
	weapon_instance.max_durability = recipe.durability
	weapon_instance.current_durability = recipe.durability
	weapon_instance.weapon_name = recipe.weapon_name
	
	# 添加到武器管理器
	if weapon_manager and weapon_manager.has_method("add_weapon"):
		weapon_manager.add_weapon(weapon_instance)
	
	if debug_mode:
		print("武器制作成功：%s" % recipe.weapon_name)
	
	return weapon_instance

## 生成随机武器掉落
## @param drop_table_key: 掉落表键值
## @param weapon_manager: 武器管理器引用
## @return: 掉落的武器实例，失败返回null
func generate_random_weapon_drop(drop_table_key: String, weapon_manager: Node) -> WeaponBase:
	if not drop_table_key in _drop_tables:
		print("错误：掉落表键值不存在 - %s" % drop_table_key)
		return null
	
	var weapon_ids = _drop_tables[drop_table_key]
	if weapon_ids.size() == 0:
		print("错误：掉落表为空")
		return null
	
	# 随机选择武器ID
	var random_index = randi() % weapon_ids.size()
	var selected_recipe_id = weapon_ids[random_index]
	
	if not selected_recipe_id in _recipes:
		print("错误：选择的武器配方不存在 - %s" % selected_recipe_id)
		return null
	
	var recipe = _recipes[selected_recipe_id]
	
	# 加载并实例化武器预制体
	var weapon_instance = load(recipe.weapon_scene_path).instantiate()
	if not weapon_instance is WeaponBase:
		print("错误：加载的武器预制体不是WeaponBase类型")
		return null
	
	# 配置武器属性
	weapon_instance.weapon_type = recipe.weapon_type
	weapon_instance.base_damage = recipe.base_damage
	weapon_instance.attack_speed = recipe.attack_speed
	weapon_instance.attack_range = recipe.attack_range
	weapon_instance.max_durability = recipe.durability
	weapon_instance.current_durability = recipe.durability
	weapon_instance.weapon_name = recipe.weapon_name
	
	# 应用随机品质修正
	_apply_random_rarity(weapon_instance)
	
	# 添加到武器管理器
	if weapon_manager and weapon_manager.has_method("add_weapon"):
		weapon_manager.add_weapon(weapon_instance)
	
	if debug_mode:
		print("武器掉落生成：%s（品质：%s）" % [weapon_instance.weapon_name, weapon_instance.get("rarity", "common")])
	
	return weapon_instance

## 应用随机品质
func _apply_random_rarity(weapon: WeaponBase) -> void:
	var rand_val = randf()
	var cumulative = 0.0
	
	for rarity in _rarity_probabilities:
		cumulative += _rarity_probabilities[rarity]
		if rand_val <= cumulative:
			# 设置武器品质
			weapon.set("rarity", rarity)
			
			# 根据品质调整属性
			match rarity:
				"uncommon":
					weapon.base_damage *= 1.1
					weapon.max_durability *= 1.2
					weapon.current_durability = weapon.max_durability
				"rare":
					weapon.base_damage *= 1.25
					weapon.attack_speed *= 1.1
					weapon.max_durability *= 1.5
					weapon.current_durability = weapon.max_durability
				"epic":
					weapon.base_damage *= 1.5
					weapon.attack_speed *= 1.2
					weapon.attack_range *= 1.3
					weapon.max_durability *= 2.0
					weapon.current_durability = weapon.max_durability
			break

## 检查资源可用性（简化版本）
func _check_resource_availability(inventory: Node, resource_type: int, required_amount: int) -> bool:
	# 这里需要根据实际的InventoryManager实现来编写
	# 暂时返回true以继续开发
	if debug_mode:
		print("检查资源：类型=%d，需要数量=%d" % [resource_type, required_amount])
	return true

## 消耗资源（简化版本）
func _consume_resource(inventory: Node, resource_type: int, amount: int) -> void:
	if debug_mode:
		print("消耗资源：类型=%d，数量=%d" % [resource_type, amount])
	# 实际实现需要调用inventory.take_resource(resource_type, amount)

## 获取所有可用配方
func get_available_recipes() -> Array:
	var recipes = []
	for recipe_id in _recipes:
		var recipe = _recipes[recipe_id]
		recipes.append({
			"id": recipe.weapon_id,
			"name": recipe.weapon_name,
			"type": recipe.weapon_type,
			"damage": recipe.base_damage,
			"required_resources": recipe.required_resources
		})
	
	return recipes

## 根据配方ID获取配方详情
func get_recipe_details(recipe_id: String) -> Dictionary:
	if not recipe_id in _recipes:
		return {}
	
	var recipe = _recipes[recipe_id]
	return {
		"id": recipe.weapon_id,
		"name": recipe.weapon_name,
		"type": recipe.weapon_type,
		"damage": recipe.base_damage,
		"attack_speed": recipe.attack_speed,
		"attack_range": recipe.attack_range,
		"durability": recipe.durability,
		"required_resources": recipe.required_resources,
		"scene_path": recipe.weapon_scene_path
	}