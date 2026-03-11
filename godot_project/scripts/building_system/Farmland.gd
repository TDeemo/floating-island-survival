# Farmland.gd - 农田建筑
# 用于种植和培育作物

extends BuildingBase
class_name Farmland

# 农田状态
enum FarmlandState {
	EMPTY,        # 空置
	PLOWED,       # 已耕地（可种植）
	PLANTED,      # 已种植（作物生长中）
	WATERED,      # 已浇水（加速生长）
	HARVESTABLE,  # 可收获
	FALLOW        # 休耕中（需要恢复肥力）
}

# 农田配置
@export var soil_quality: float = 1.0  # 土壤质量（影响生长速度）
@export var water_level: float = 0.0   # 水分含量（0.0-1.0）
@export var fertility: float = 1.0     # 肥力（影响产量）
@export var max_fertility: float = 2.0

# 当前状态
var current_farm_state: FarmlandState = FarmlandState.EMPTY
var planted_crop: CropBase = null
var crop_growth_progress: float = 0.0  # 0.0-1.0
var last_update_time: float = 0.0
var growth_multiplier: float = 1.0  # 生长速度乘数

# 视觉节点引用
@onready var soil_sprite: Sprite2D = $SoilSprite
@onready var crop_sprite: Sprite2D = $CropSprite
@onready var water_overlay: Sprite2D = $WaterOverlay
@onready var growth_bar: ProgressBar = $GrowthBar

# 信号
signal farmland_plowed(farmland: Farmland)
signal crop_planted(farmland: Farmland, crop: CropBase)
farmland_watered(farmland: Farmland, amount: float)
crop_growth_updated(farmland: Farmland, crop: CropBase, progress: float)
crop_harvestable(farmland: Farmland, crop: CropBase)
crop_harvested(farmland: Farmland, crop: CropBase, yield_amount: int)

func _ready():
	# 调用父类的_ready
	super._ready()
	
	# 设置农田特定属性
	building_name = "农田"
	building_type = BuildingManager.BuildingType.FARMLAND
	description = "用于种植作物"
	resource_cost = {"wood": 10, "stone": 20}
	build_time = 10.0
	
	# 初始化农田
	_init_farmland()

func _setup_building():
	"""初始化农田配置"""
	# 设置农田特有的视觉元素
	if soil_sprite:
		soil_sprite.texture = load("res://assets/sprites/farmland_soil.png")
	
	if water_overlay:
		water_overlay.visible = false
		water_overlay.modulate = Color(0.3, 0.5, 0.8, 0.3)
	
	if growth_bar:
		growth_bar.visible = false

func _init_farmland():
	"""初始化农田状态"""
	current_farm_state = FarmlandState.EMPTY
	planted_crop = null
	crop_growth_progress = 0.0
	water_level = 0.0
	
	_update_visuals()

func _update_visuals():
	"""更新农田视觉效果"""
	match current_farm_state:
		FarmlandState.EMPTY:
			if soil_sprite:
				soil_sprite.modulate = Color(0.7, 0.6, 0.4, 1.0)
			if crop_sprite:
				crop_sprite.visible = false
			if water_overlay:
				water_overlay.visible = false
		
		FarmlandState.PLOWED:
			if soil_sprite:
				soil_sprite.modulate = Color(0.8, 0.7, 0.5, 1.0)
			if crop_sprite:
				crop_sprite.visible = false
		
		FarmlandState.PLANTED, FarmlandState.WATERED:
			if crop_sprite and planted_crop:
				crop_sprite.visible = true
				# 根据生长阶段设置不同精灵
				var stage_index = planted_crop.get_current_growth_stage_index()
				var stage_sprites = planted_crop.get_growth_sprites()
				if stage_index < stage_sprites.size():
					crop_sprite.texture = stage_sprites[stage_index]
			
			# 显示水分效果
			if water_overlay:
				water_overlay.visible = (current_farm_state == FarmlandState.WATERED)
		
		FarmlandState.HARVESTABLE:
			if crop_sprite and planted_crop:
				crop_sprite.modulate = Color(1.0, 1.0, 0.8, 1.0)
		
		FarmlandState.FALLOW:
			if soil_sprite:
				soil_sprite.modulate = Color(0.6, 0.5, 0.3, 1.0)
	
	# 更新生长进度条
	if growth_bar:
		growth_bar.visible = (planted_crop != null)
		if planted_crop:
			growth_bar.value = crop_growth_progress * 100

func _on_interact(player: Node):
	"""玩家与农田交互"""
	print("农田交互")
	
	# 根据农田状态提供不同的交互选项
	match current_farm_state:
		FarmlandState.EMPTY:
			_show_empty_options(player)
		FarmlandState.PLOWED:
			_show_planting_options(player)
		FarmlandState.PLANTED, FarmlandState.WATERED:
			_show_care_options(player)
		FarmlandState.HARVESTABLE:
			_show_harvest_options(player)
		FarmlandState.FALLOW:
			_show_recovery_options(player)

func _show_empty_options(player: Node):
	"""显示空农田的选项"""
	print("=== 农田选项 ===")
	print("1. 耕地（准备种植）")
	print("2. 施肥（提高肥力）")
	print("3. 退出")
	
	# 实际游戏中应该通过GUI处理交互

func _show_planting_options(player: Node):
	"""显示已耕地的种植选项"""
	print("=== 种植选项 ===")
	print("农田已准备好种植")
	print("请选择要种植的作物：")
	
	# 这里应该获取玩家背包中的种子列表
	# 暂时简化
	print("1. 小麦种子")
	print("2. 药草种子")
	print("3. 浇水")
	print("4. 退出")
	
	# 实际游戏中应该通过GUI处理交互

func _show_care_options(player: Node):
	"""显示已种植作物的护理选项"""
	print("=== 作物护理 ===")
	if planted_crop:
		print("作物: %s" % planted_crop.crop_name)
		print("生长进度: %.1f%%" % (crop_growth_progress * 100))
		print("生长阶段: %s" % planted_crop.get_current_growth_stage_name())
	
	print("1. 浇水（提高生长速度）")
	print("2. 施肥（提高产量）")
	print("3. 检查状态")
	print("4. 退出")

func _show_harvest_options(player: Node):
	"""显示可收获作物的选项"""
	print("=== 收获作物 ===")
	if planted_crop:
		print("作物: %s 已成熟！" % planted_crop.crop_name)
		print("预计产量: %d" % planted_crop.get_yield_amount())
	
	print("1. 收获")
	print("2. 等待（继续生长）")
	print("3. 退出")

func _show_recovery_options(player: Node):
	"""显示休耕农田的恢复选项"""
	print("=== 农田恢复 ===")
	print("农田正在休耕，需要恢复肥力")
	print("当前肥力: %.1f%%" % (fertility * 100))
	
	print("1. 施肥（加速恢复）")
	print("2. 等待自然恢复")
	print("3. 退出")

func plow():
	"""耕地（准备种植）"""
	if current_farm_state != FarmlandState.EMPTY:
		print("农田状态不适合耕地")
		return
	
	current_farm_state = FarmlandState.PLOWED
	_update_visuals()
	
	farmland_plowed.emit(self)
	print("农田已耕地")

func plant_crop(crop: CropBase):
	"""种植作物"""
	if current_farm_state != FarmlandState.PLOWED:
		print("农田未耕地，无法种植")
		return false
	
	if not crop:
		print("无效的作物")
		return false
	
	planted_crop = crop
	current_farm_state = FarmlandState.PLANTED
	crop_growth_progress = 0.0
	last_update_time = Time.get_ticks_msec() / 1000.0
	
	# 计算生长乘数
	growth_multiplier = soil_quality * fertility
	
	_update_visuals()
	
	crop_planted.emit(self, crop)
	print("已种植: %s" % crop.crop_name)
	
	return true

func water(amount: float = 0.3):
	"""浇水"""
	if not planted_crop:
		print("没有作物，无需浇水")
		return
	
	water_level = min(1.0, water_level + amount)
	
	if water_level >= 0.3:
		current_farm_state = FarmlandState.WATERED
		growth_multiplier = soil_quality * fertility * (1.0 + water_level * 0.5)
	
	_update_visuals()
	
	farmland_watered.emit(self, amount)
	print("已浇水，当前水分: %.1f%%" % (water_level * 100))

func _process(delta):
	"""更新作物生长"""
	if not planted_crop or current_farm_state == FarmlandState.HARVESTABLE:
		return
	
	# 计算实际时间间隔
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_passed = current_time - last_update_time
	last_update_time = current_time
	
	# 更新生长进度
	var growth_rate = planted_crop.get_growth_rate() * growth_multiplier
	crop_growth_progress += time_passed * growth_rate / planted_crop.get_total_growth_time()
	
	# 限制在0-1之间
	crop_growth_progress = clamp(crop_growth_progress, 0.0, 1.0)
	
	# 更新作物生长阶段
	if planted_crop:
		planted_crop.update_growth(crop_growth_progress)
	
	# 检查是否可以收获
	if crop_growth_progress >= 1.0:
		current_farm_state = FarmlandState.HARVESTABLE
		crop_harvestable.emit(self, planted_crop)
	
	# 发送生长进度更新
	crop_growth_updated.emit(self, planted_crop, crop_growth_progress)
	
	# 更新视觉
	_update_visuals()

func harvest() -> Dictionary:
	"""收获作物"""
	if current_farm_state != FarmlandState.HARVESTABLE or not planted_crop:
		return {"success": false, "message": "没有可收获的作物"}
	
	# 获取产量
	var yield_amount = planted_crop.get_yield_amount()
	var product_id = planted_crop.get_product_id()
	
	# 发送收获信号
	crop_harvested.emit(self, planted_crop, yield_amount)
	
	# 重置农田状态
	var harvested_crop = planted_crop
	planted_crop = null
	current_farm_state = FarmlandState.FALLOW
	crop_growth_progress = 0.0
	
	# 消耗肥力
	fertility = max(0.3, fertility - 0.2)
	
	_update_visuals()
	
	print("收获完成: %s ×%d" % [harvested_crop.crop_name, yield_amount])
	
	return {
		"success": true,
		"message": "收获成功",
		"crop": harvested_crop,
		"yield_amount": yield_amount,
		"product_id": product_id
	}

func fertilize(amount: float = 0.5):
	"""施肥"""
	fertility = min(max_fertility, fertility + amount)
	print("施肥完成，当前肥力: %.1f%%" % (fertility * 100))

func get_farmland_info() -> Dictionary:
	"""获取农田信息"""
	var info = {
		"state": FarmlandState.keys()[current_farm_state],
		"soil_quality": soil_quality,
		"fertility": fertility,
		"water_level": water_level,
		"growth_progress": crop_growth_progress
	}
	
	if planted_crop:
		info["crop"] = planted_crop.crop_name
		info["growth_stage"] = planted_crop.get_current_growth_stage_name()
	
	return info

func can_plant() -> bool:
	"""检查是否可以种植"""
	return current_farm_state == FarmlandState.PLOWED

func is_harvestable() -> bool:
	"""检查是否可以收获"""
	return current_farm_state == FarmlandState.HARVESTABLE

func recover_fertility(amount: float = 0.1):
	"""恢复肥力（休耕过程）"""
	if current_farm_state != FarmlandState.FALLOW:
		return
	
	fertility = min(1.0, fertility + amount)
	
	# 如果肥力恢复到足够水平，可以重新耕地
	if fertility >= 0.8:
		current_farm_state = FarmlandState.EMPTY
	
	_update_visuals()