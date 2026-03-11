# FarmManager.gd - 农场系统管理器 (占位符)
# 用于集成测试场景，完整实现将在后续任务中完成

extends Node

class_name FarmManager

# 作物类型枚举
enum CropType {
	WHEAT,      # 小麦
	CORN,       # 玉米
	CARROT,     # 胡萝卜
	HEALING_HERB # 药草 (治疗用)
}

# 生长阶段
enum GrowthStage {
	SEED,       # 种子
	SPROUT,     # 幼苗
	GROWING,    # 生长期
	MATURE,     # 成熟期
	WILTED      # 枯萎
}

# 作物数据类
class CropData:
	var type: CropType
	var name: String
	var growth_time: float  # 总生长时间 (秒)
	var yield_amount: int   # 收获数量
	var seed_cost: int      # 种子消耗数量
	var product_id: String  # 收获物品ID
	
	func _init(_type: CropType, _name: String, _growth_time: float, _yield: int, _seed_cost: int, _product: String):
		type = _type
		name = _name
		growth_time = _growth_time
		yield_amount = _yield
		seed_cost = _seed_cost
		product_id = _product

# 农田实例类
class FarmPlot:
	var plot_id: String
	var position: Vector2
	var crop_type: CropType = CropType.WHEAT
	var growth_stage: GrowthStage = GrowthStage.SEED
	var growth_progress: float = 0.0  # 0.0-1.0
	var is_watered: bool = false
	var planted_time: float = 0.0
	
	func get_growth_percentage() -> float:
		return growth_progress * 100.0
	
	func update_growth(delta: float, watered: bool = false):
		if growth_stage == GrowthStage.MATURE or growth_stage == GrowthStage.WILTED:
			return
		
		var growth_rate = 1.0
		if watered:
			growth_rate = 1.5
		
		growth_progress += (delta / 60.0) * growth_rate  # 假设60秒完成一个阶段
		
		if growth_progress >= 1.0:
			growth_progress = 0.0
			growth_stage += 1
			
			if growth_stage == GrowthStage.MATURE:
				print("Crop matured in plot ", plot_id)

# 可用作物列表
var available_crops: Array[CropData] = []
# 农田地块列表
var farm_plots: Array[FarmPlot] = []

signal crop_planted(plot_id: String, crop_type: CropType)
signal crop_harvested(plot_id: String, crop_type: CropType, yield_amount: int)
signal crop_wilted(plot_id: String, crop_type: CropType)
signal farm_plot_created(plot_id: String, position: Vector2)

func _ready():
	# 初始化作物数据 (占位符)
	_init_crop_data()
	print("FarmManager initialized (placeholder)")

func _init_crop_data():
	# 小麦
	var wheat = CropData.new(
		CropType.WHEAT,
		"小麦",
		300.0,  # 5分钟
		3,      # 收获3个小麦
		1,      # 消耗1个种子
		"wheat"
	)
	
	# 玉米
	var corn = CropData.new(
		CropType.CORN,
		"玉米",
		480.0,  # 8分钟
		2,      # 收获2个玉米
		1,      # 消耗1个种子
		"corn"
	)
	
	# 胡萝卜
	var carrot = CropData.new(
		CropType.CARROT,
		"胡萝卜",
		360.0,  # 6分钟
		4,      # 收获4个胡萝卜
		1,      # 消耗1个种子
		"carrot"
	)
	
	# 药草
	var healing_herb = CropData.new(
		CropType.HEALING_HERB,
		"治疗药草",
		600.0,  # 10分钟
		2,      # 收获2个药草
		1,      # 消耗1个种子
		"healing_herb"
	)
	
	available_crops = [wheat, corn, carrot, healing_herb]

# 创建新的农田地块
func create_farm_plot(position: Vector2) -> FarmPlot:
	var plot = FarmPlot.new()
	plot.plot_id = "farm_plot_%d" % farm_plots.size()
	plot.position = position
	farm_plots.append(plot)
	farm_plot_created.emit(plot.plot_id, position)
	print("Farm plot created: ", plot.plot_id, " at ", position)
	return plot

# 种植作物
func plant_crop(plot_id: String, crop_type: CropType, seed_count: int) -> bool:
	for plot in farm_plots:
		if plot.plot_id == plot_id:
			if plot.growth_stage != GrowthStage.SEED:
				return false
			
			# 检查种子数量
			if seed_count <= 0:
				return false
			
			plot.crop_type = crop_type
			plot.growth_stage = GrowthStage.SPROUT
			plot.planted_time = Time.get_unix_time_from_system()
			plot.growth_progress = 0.0
			
			crop_planted.emit(plot_id, crop_type)
			print("Crop planted: ", crop_type, " in plot ", plot_id)
			return true
	
	return false

# 收获作物
func harvest_crop(plot_id: String) -> Dictionary:
	for plot in farm_plots:
		if plot.plot_id == plot_id:
			if plot.growth_stage != GrowthStage.MATURE:
				return {"success": false, "yield": 0}
			
			for crop in available_crops:
				if crop.type == plot.crop_type:
					plot.growth_stage = GrowthStage.SEED
					plot.growth_progress = 0.0
					
					crop_harvested.emit(plot_id, plot.crop_type, crop.yield_amount)
					print("Crop harvested: ", plot.crop_type, " from plot ", plot_id, ", yield: ", crop.yield_amount)
					
					return {
						"success": true,
						"crop_type": plot.crop_type,
						"yield_amount": crop.yield_amount,
						"product_id": crop.product_id
					}
	
	return {"success": false, "yield": 0}

# 更新农田状态 (每帧调用)
func _process(delta):
	for plot in farm_plots:
		if plot.growth_stage != GrowthStage.SEED and plot.growth_stage != GrowthStage.MATURE:
			plot.update_growth(delta, plot.is_watered)
			
			# 如果成熟后24小时未收获，枯萎
			if plot.growth_stage == GrowthStage.MATURE:
				var time_since_mature = Time.get_unix_time_from_system() - (plot.planted_time + plot.get_growth_time())
				if time_since_mature > 86400:  # 24小时
					plot.growth_stage = GrowthStage.WILTED
					crop_wilted.emit(plot.plot_id, plot.crop_type)