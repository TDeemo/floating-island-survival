# Workbench.gd - 工作台建筑
# 用于制作武器、工具和基础物品

extends BuildingBase
class_name Workbench

# 配方结构
class Recipe:
	var recipe_id: String
	var recipe_name: String
	var required_resources: Dictionary  # 资源类型:数量
	var output_item_id: String
	var output_count: int = 1
	var craft_time: float = 3.0
	var unlock_level: int = 1
	
	func _init(id: String, name: String, resources: Dictionary, output: String, count: int = 1, time: float = 3.0, level: int = 1):
		recipe_id = id
		recipe_name = name
		required_resources = resources
		output_item_id = output
		output_count = count
		craft_time = time
		unlock_level = level

# 可用配方列表
var available_recipes: Array[Recipe] = []

# 当前制作队列
var crafting_queue: Array = []
var current_crafting: Recipe = null
var crafting_progress: float = 0.0
var crafting_timer: Timer

# 信号
signal recipe_unlocked(recipe: Recipe)
signal crafting_started(recipe: Recipe)
signal crafting_progress_updated(recipe: Recipe, progress: float)
signal crafting_completed(recipe: Recipe, item_id: String, count: int)
signal crafting_cancelled(recipe: Recipe)

func _ready():
	# 调用父类的_ready
	super._ready()
	
	# 设置工作台特定属性
	building_name = "工作台"
	building_type = BuildingManager.BuildingType.WORKBENCH
	description = "用于制作工具、武器和基础物品"
	resource_cost = {"wood": 20, "stone": 10}
	build_time = 8.0
	
	# 初始化配方
	_init_recipes()
	
	# 创建制作计时器
	crafting_timer = Timer.new()
	crafting_timer.wait_time = 0.1
	crafting_timer.timeout.connect(_update_crafting_progress)
	add_child(crafting_timer)

func _setup_building():
	"""初始化工作台配置"""
	# 设置工作台特有的视觉元素
	if sprite:
		sprite.texture = load("res://assets/sprites/workbench.png")

func _init_recipes():
	"""初始化基础配方"""
	# 基础工具配方
	var wood_axe = Recipe.new(
		"wood_axe",
		"木斧",
		{"wood": 5, "stone": 2},
		"wood_axe",
		1,
		5.0,
		1
	)
	available_recipes.append(wood_axe)
	
	var wood_pickaxe = Recipe.new(
		"wood_pickaxe",
		"木镐",
		{"wood": 5, "stone": 3},
		"wood_pickaxe",
		1,
		5.0,
		1
	)
	available_recipes.append(wood_pickaxe)
	
	# 基础武器配方
	var wood_sword = Recipe.new(
		"wood_sword",
		"木剑",
		{"wood": 8, "stone": 4},
		"wood_sword",
		1,
		6.0,
		1
	)
	available_recipes.append(wood_sword)
	
	var stone_hammer = Recipe.new(
		"stone_hammer",
		"石锤",
		{"wood": 6, "stone": 10},
		"stone_hammer",
		1,
		8.0,
		2
	)
	available_recipes.append(stone_hammer)
	
	# 消耗品配方
	var torch = Recipe.new(
		"torch",
		"火把",
		{"wood": 3, "fiber": 2},
		"torch",
		3,
		3.0,
		1
	)
	available_recipes.append(torch)
	
	print("工作台配方初始化完成，共 %d 个配方" % available_recipes.size())

func _on_interact(player: Node):
	"""玩家与工作台交互"""
	print("打开工作台制作界面")
	
	# 显示制作界面（实际游戏中应调用UI管理器）
	_show_crafting_interface(player)

func _show_crafting_interface(player: Node):
	"""显示制作界面（简化版本）"""
	print("=== 工作台制作界面 ===")
	print("可制作物品：")
	
	for i in range(available_recipes.size()):
		var recipe = available_recipes[i]
		print("%d. %s - 需要: %s" % [
			i + 1,
			recipe.recipe_name,
			_dict_to_string(recipe.required_resources)
		])
	
	print("输入配方编号开始制作（或输入0退出）")
	# 实际游戏中应该通过GUI处理交互

func craft_recipe(recipe_id: String):
	"""开始制作指定配方"""
	var recipe = _find_recipe_by_id(recipe_id)
	if not recipe:
		print("配方不存在: %s" % recipe_id)
		return
	
	# 检查资源是否充足（需要集成InventoryManager）
	if not _has_required_resources(recipe):
		print("资源不足，无法制作 %s" % recipe.recipe_name)
		return
	
	# 添加到制作队列
	crafting_queue.append(recipe)
	print("已添加 %s 到制作队列" % recipe.recipe_name)
	
	# 如果没有正在制作的物品，开始制作
	if current_crafting == null:
		_start_next_crafting()

func _start_next_crafting():
	"""开始制作队列中的下一个物品"""
	if crafting_queue.size() == 0:
		current_crafting = null
		return
	
	current_crafting = crafting_queue.pop_front()
	crafting_progress = 0.0
	
	# 扣除资源（需要集成InventoryManager）
	_consume_resources(current_crafting)
	
	crafting_started.emit(current_crafting)
	print("开始制作: %s，预计时间: %.1f秒" % [current_crafting.recipe_name, current_crafting.craft_time])
	
	# 启动计时器
	crafting_timer.start()

func _update_crafting_progress():
	"""更新制作进度"""
	if current_crafting == null:
		crafting_timer.stop()
		return
	
	crafting_progress += 0.1 / current_crafting.craft_time
	
	# 发送进度更新信号
	crafting_progress_updated.emit(current_crafting, crafting_progress)
	
	# 检查是否完成
	if crafting_progress >= 1.0:
		_complete_crafting()

func _complete_crafting():
	"""完成当前物品的制作"""
	if current_crafting == null:
		return
	
	# 生成物品（需要集成InventoryManager）
	_produce_item(current_crafting.output_item_id, current_crafting.output_count)
	
	print("制作完成: %s ×%d" % [current_crafting.recipe_name, current_crafting.output_count])
	crafting_completed.emit(current_crafting, current_crafting.output_item_id, current_crafting.output_count)
	
	# 开始下一个物品的制作
	_start_next_crafting()

func cancel_current_crafting():
	"""取消当前制作"""
	if current_crafting == null:
		return
	
	print("取消制作: %s" % current_crafting.recipe_name)
	crafting_cancelled.emit(current_crafting)
	
	# 停止计时器
	crafting_timer.stop()
	
	# 返还部分资源（需要集成InventoryManager）
	_refund_resources(current_crafting)
	
	# 开始下一个物品的制作
	_start_next_crafting()

func _find_recipe_by_id(recipe_id: String) -> Recipe:
	"""根据ID查找配方"""
	for recipe in available_recipes:
		if recipe.recipe_id == recipe_id:
			return recipe
	return null

func _has_required_resources(recipe: Recipe) -> bool:
	"""检查是否有足够的资源（简化版本）"""
	# 实际需要与InventoryManager集成
	# 暂时返回true
	return true

func _consume_resources(recipe: Recipe):
	"""消耗资源（简化版本）"""
	print("消耗资源: %s" % _dict_to_string(recipe.required_resources))
	# 实际需要调用InventoryManager.remove_resources()

func _refund_resources(recipe: Recipe):
	"""返还资源（简化版本）"""
	print("返还部分资源: %s" % _dict_to_string(recipe.required_resources))
	# 实际需要调用InventoryManager.add_resources()

func _produce_item(item_id: String, count: int):
	"""生成物品（简化版本）"""
	print("生成物品: %s ×%d" % [item_id, count])
	# 实际需要调用InventoryManager.add_item()

func _dict_to_string(dict: Dictionary) -> String:
	"""将字典转换为可读字符串"""
	var parts = []
	for key in dict:
		parts.append("%s: %d" % [key, dict[key]])
	return ", ".join(parts)

func get_crafting_queue_size() -> int:
	"""获取制作队列大小"""
	return crafting_queue.size()

func get_current_crafting() -> Recipe:
	"""获取当前正在制作的配方"""
	return current_crafting

func get_crafting_progress() -> float:
	"""获取当前制作进度"""
	return crafting_progress

func is_crafting() -> bool:
	"""检查是否正在制作"""
	return current_crafting != null

func unlock_recipe(recipe_id: String):
	"""解锁新配方"""
	var recipe = _find_recipe_by_id(recipe_id)
	if recipe:
		print("解锁配方: %s" % recipe.recipe_name)
		recipe_unlocked.emit(recipe)
	else:
		print("配方不存在: %s" % recipe_id)