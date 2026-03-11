# Campfire.gd - 篝火建筑
# 提供光照、温暖和烹饪功能

extends BuildingBase
class_name Campfire

# 篝火状态
enum CampfireState {
	UNLIT,      # 未点燃
	LIT,        # 点燃中
	DYING,      # 即将熄灭
	EXTINGUISHED # 已熄灭
}

# 烹饪配方类
class CookingRecipe:
	var recipe_id: String
	var recipe_name: String
	var required_ingredients: Dictionary  # 物品ID:数量
	var cooking_time: float
	var output_item_id: String
	var output_count: int = 1
	var unlocked: bool = true
	
	func _init(id: String, name: String, ingredients: Dictionary, time: float, output: String, count: int = 1):
		recipe_id = id
		recipe_name = name
		required_ingredients = ingredients
		cooking_time = time
		output_item_id = output
		output_count = count

# 篝火配置
@export var fuel_capacity: float = 100.0  # 燃料容量
@export var initial_fuel: float = 50.0    # 初始燃料
@export var burn_rate: float = 1.0        # 每秒消耗燃料
@export var light_radius: float = 300.0   # 光照半径
@export var warmth_radius: float = 200.0  # 温暖半径

# 当前状态
var current_fuel: float = initial_fuel
var current_state: CampfireState = CampfireState.UNLIT
var current_temperature: float = 0.0  # 温度（0.0-1.0）
var burn_timer: Timer
var light_source: LightSource = null

# 烹饪系统
var cooking_recipes: Array[CookingRecipe] = []
var current_cooking: CookingRecipe = null
var cooking_progress: float = 0.0
var cooking_timer: Timer

# 节点引用
@onready var flame_sprite: AnimatedSprite2D = $FlameSprite
@onready var smoke_particles: GPUParticles2D = $SmokeParticles
@onready var heat_area: Area2D = $HeatArea
@onready var light_node: Light2D = $Light2D

# 信号
signal campfire_lit(campfire: Campfire)
signal campfire_dying(campfire: Campfire)
signal campfire_extinguished(campfire: Campfire)
signal fuel_added(campfire: Campfire, amount: float, new_fuel: float)
signal fuel_low(campfire: Campfire, remaining_fuel: float)
signal cooking_started(campfire: Campfire, recipe: CookingRecipe)
signal cooking_progress_updated(campfire: Campfire, recipe: CookingRecipe, progress: float)
signal cooking_completed(campfire: Campfire, recipe: CookingRecipe, item_id: String, count: int)

func _ready():
	# 调用父类的_ready
	super._ready()
	
	# 设置篝火特定属性
	building_name = "篝火"
	building_type = BuildingManager.BuildingType.CAMPFIRE
	description = "提供光照、温暖和烹饪功能"
	resource_cost = {"wood": 15, "stone": 30}
	build_time = 12.0
	
	# 初始化篝火
	_init_campfire()
	
	# 初始化烹饪配方
	_init_recipes()

func _setup_building():
	"""初始化篝火配置"""
	# 设置篝火特有的视觉元素
	if flame_sprite:
		flame_sprite.visible = false
	
	if smoke_particles:
		smoke_particles.emitting = false
	
	if light_node:
		light_node.enabled = false
		light_node.texture_scale = light_radius / 100.0

func _init_campfire():
	"""初始化篝火状态"""
	current_fuel = initial_fuel
	current_state = CampfireState.UNLIT
	current_temperature = 0.0
	
	# 创建燃烧计时器
	burn_timer = Timer.new()
	burn_timer.wait_time = 1.0
	burn_timer.timeout.connect(_update_burn_state)
	add_child(burn_timer)
	
	# 创建烹饪计时器
	cooking_timer = Timer.new()
	cooking_timer.wait_time = 0.1
	cooking_timer.timeout.connect(_update_cooking_progress)
	add_child(cooking_timer)
	
	_update_visuals()

func _init_recipes():
	"""初始化烹饪配方"""
	# 基础食物配方
	var cooked_meat = CookingRecipe.new(
		"cooked_meat",
		"烤肉",
		{"raw_meat": 1},
		10.0,
		"cooked_meat",
		1
	)
	cooking_recipes.append(cooked_meat)
	
	var vegetable_soup = CookingRecipe.new(
		"vegetable_soup",
		"蔬菜汤",
		{"carrot": 2, "potato": 1, "water": 1},
		15.0,
		"vegetable_soup",
		1
	)
	cooking_recipes.append(vegetable_soup)
	
	var herbal_tea = CookingRecipe.new(
		"herbal_tea",
		"草药茶",
		{"healing_herb": 2, "water": 1},
		8.0,
		"herbal_tea",
		1
	)
	cooking_recipes.append(herbal_tea)
	
	print("篝火烹饪配方初始化完成，共 %d 个配方" % cooking_recipes.size())

func _update_visuals():
	"""更新篝火视觉效果"""
	match current_state:
		CampfireState.UNLIT:
			if flame_sprite:
				flame_sprite.visible = false
			if smoke_particles:
				smoke_particles.emitting = false
			if light_node:
				light_node.enabled = false
		
		CampfireState.LIT:
			if flame_sprite:
				flame_sprite.visible = true
				flame_sprite.play("burning")
			if smoke_particles:
				smoke_particles.emitting = true
			if light_node:
				light_node.enabled = true
				# 根据温度调整光照强度
				light_node.energy = current_temperature * 0.8 + 0.2
		
		CampfireState.DYING:
			if flame_sprite:
				flame_sprite.play("dying")
			if smoke_particles:
				smoke_particles.emitting = true
			if light_node:
				light_node.energy = current_temperature * 0.4 + 0.1
		
		CampfireState.EXTINGUISHED:
			if flame_sprite:
				flame_sprite.visible = false
			if smoke_particles:
				smoke_particles.emitting = false
			if light_node:
				light_node.enabled = false

func _on_interact(player: Node):
	"""玩家与篝火交互"""
	print("篝火交互")
	
	# 根据篝火状态提供不同的交互选项
	match current_state:
		CampfireState.UNLIT:
			_show_unlit_options(player)
		CampfireState.LIT, CampfireState.DYING:
			_show_lit_options(player)
		CampfireState.EXTINGUISHED:
			_show_extinguished_options(player)

func _show_unlit_options(player: Node):
	"""显示未点燃篝火的选项"""
	print("=== 篝火选项 ===")
	print("篝火未点燃")
	print("燃料: %.1f/%.1f" % [current_fuel, fuel_capacity])
	
	print("1. 点燃篝火")
	print("2. 添加燃料")
	print("3. 检查状态")
	print("4. 退出")

func _show_lit_options(player: Node):
	"""显示点燃中篝火的选项"""
	print("=== 篝火选项 ===")
	print("篝火燃烧中")
	print("燃料: %.1f/%.1f" % [current_fuel, fuel_capacity])
	print("温度: %.0f%%" % (current_temperature * 100))
	
	print("1. 烹饪食物")
	print("2. 添加燃料")
	print("3. 取暖")
	print("4. 熄灭篝火")
	print("5. 检查状态")
	print("6. 退出")

func _show_extinguished_options(player: Node):
	"""显示已熄灭篝火的选项"""
	print("=== 篝火选项 ===")
	print("篝火已熄灭")
	
	print("1. 重新点燃")
	print("2. 清理灰烬")
	print("3. 检查状态")
	print("4. 退出")

func light():
	"""点燃篝火"""
	if current_state != CampfireState.UNLIT:
		print("篝火状态不适合点燃")
		return
	
	if current_fuel <= 0:
		print("没有燃料，无法点燃")
		return
	
	current_state = CampfireState.LIT
	current_temperature = 0.5
	
	# 启动燃烧计时器
	burn_timer.start()
	
	# 创建光源（需要与光照系统集成）
	_create_light_source()
	
	_update_visuals()
	
	campfire_lit.emit(self)
	print("篝火已点燃")

func _create_light_source():
	"""创建光源节点"""
	# 这里应该创建一个LightSource实例并与光照管理器注册
	# 暂时简化
	print("创建篝火光源，半径: %.1f" % light_radius)

func add_fuel(amount: float):
	"""添加燃料"""
	if amount <= 0:
		print("燃料数量必须大于0")
		return
	
	var old_fuel = current_fuel
	current_fuel = min(fuel_capacity, current_fuel + amount)
	
	var added = current_fuel - old_fuel
	fuel_added.emit(self, added, current_fuel)
	
	print("添加燃料: %.1f，当前燃料: %.1f/%.1f" % [added, current_fuel, fuel_capacity])
	
	# 如果篝火熄灭且添加了燃料，可以重新点燃
	if current_state == CampfireState.EXTINGUISHED and current_fuel > 0:
		print("篝火有燃料，可以重新点燃")

func _update_burn_state():
	"""更新燃烧状态"""
	if current_state != CampfireState.LIT and current_state != CampfireState.DYING:
		return
	
	# 消耗燃料
	current_fuel = max(0, current_fuel - burn_rate)
	
	# 更新温度（根据燃料量）
	current_temperature = current_fuel / fuel_capacity * 0.8 + 0.2
	
	# 检查燃料状态
	if current_fuel <= 10.0:
		fuel_low.emit(self, current_fuel)
	
	if current_fuel <= 0:
		extinguish()
	elif current_fuel <= 20.0:
		# 燃料不足，进入即将熄灭状态
		if current_state != CampfireState.DYING:
			current_state = CampfireState.DYING
			campfire_dying.emit(self)
	
	_update_visuals()

func extinguish():
	"""熄灭篝火"""
	if current_state == CampfireState.UNLIT or current_state == CampfireState.EXTINGUISHED:
		return
	
	current_state = CampfireState.EXTINGUISHED
	current_temperature = 0.0
	
	# 停止计时器
	burn_timer.stop()
	
	# 移除光源
	_remove_light_source()
	
	_update_visuals()
	
	campfire_extinguished.emit(self)
	print("篝火已熄灭")

func _remove_light_source():
	"""移除光源节点"""
	print("移除篝火光源")

func cook_recipe(recipe_id: String):
	"""开始烹饪指定配方"""
	if current_state != CampfireState.LIT:
		print("篝火未点燃，无法烹饪")
		return false
	
	var recipe = _find_recipe_by_id(recipe_id)
	if not recipe:
		print("配方不存在: %s" % recipe_id)
		return false
	
	# 检查材料是否充足（需要集成InventoryManager）
	if not _has_required_ingredients(recipe):
		print("材料不足，无法烹饪 %s" % recipe.recipe_name)
		return false
	
	# 设置当前烹饪
	current_cooking = recipe
	cooking_progress = 0.0
	
	# 消耗材料
	_consume_ingredients(recipe)
	
	# 启动烹饪计时器
	cooking_timer.start()
	
	cooking_started.emit(self, recipe)
	print("开始烹饪: %s，预计时间: %.1f秒" % [recipe.recipe_name, recipe.cooking_time])
	
	return true

func _update_cooking_progress():
	"""更新烹饪进度"""
	if current_cooking == null:
		cooking_timer.stop()
		return
	
	# 计算进度增量（考虑温度影响）
	var progress_rate = 0.1 / current_cooking.cooking_time
	progress_rate *= current_temperature  # 温度越高烹饪越快
	
	cooking_progress += progress_rate
	cooking_progress_updated.emit(self, current_cooking, cooking_progress)
	
	# 检查是否完成
	if cooking_progress >= 1.0:
		_complete_cooking()

func _complete_cooking():
	"""完成烹饪"""
	if current_cooking == null:
		return
	
	# 生成食物
	_produce_food(current_cooking.output_item_id, current_cooking.output_count)
	
	print("烹饪完成: %s ×%d" % [current_cooking.recipe_name, current_cooking.output_count])
	cooking_completed.emit(self, current_cooking, current_cooking.output_item_id, current_cooking.output_count)
	
	# 重置烹饪状态
	current_cooking = null
	cooking_progress = 0.0
	cooking_timer.stop()

func _find_recipe_by_id(recipe_id: String) -> CookingRecipe:
	"""根据ID查找配方"""
	for recipe in cooking_recipes:
		if recipe.recipe_id == recipe_id:
			return recipe
	return null

func _has_required_ingredients(recipe: CookingRecipe) -> bool:
	"""检查是否有足够的材料（简化版本）"""
	# 实际需要与InventoryManager集成
	# 暂时返回true
	return true

func _consume_ingredients(recipe: CookingRecipe):
	"""消耗材料（简化版本）"""
	print("消耗材料: %s" % _dict_to_string(recipe.required_ingredients))
	# 实际需要调用InventoryManager.remove_items()

func _produce_food(item_id: String, count: int):
	"""生成食物（简化版本）"""
	print("生成食物: %s ×%d" % [item_id, count])
	# 实际需要调用InventoryManager.add_item()

func _dict_to_string(dict: Dictionary) -> String:
	"""将字典转换为可读字符串"""
	var parts = []
	for key in dict:
		parts.append("%s: %d" % [key, dict[key]])
	return ", ".join(parts)

func get_fuel_percentage() -> float:
	"""获取燃料百分比"""
	return current_fuel / fuel_capacity

func is_lit() -> bool:
	"""检查是否点燃"""
	return current_state == CampfireState.LIT

func get_temperature() -> float:
	"""获取当前温度"""
	return current_temperature

func get_campfire_info() -> Dictionary:
	"""获取篝火信息"""
	return {
		"state": CampfireState.keys()[current_state],
		"fuel": current_fuel,
		"fuel_capacity": fuel_capacity,
		"temperature": current_temperature,
		"is_cooking": current_cooking != null,
		"cooking_progress": cooking_progress
	}

func unlock_recipe(recipe_id: String):
	"""解锁新烹饪配方"""
	var recipe = _find_recipe_by_id(recipe_id)
	if recipe:
		recipe.unlocked = true
		print("解锁烹饪配方: %s" % recipe.recipe_name)
	else:
		print("配方不存在: %s" % recipe_id)