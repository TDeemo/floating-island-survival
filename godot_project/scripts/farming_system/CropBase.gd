# CropBase.gd - 作物基类
# 所有作物的通用基类，提供生长阶段管理和收获功能

extends Node2D
class_name CropBase

# 作物类型枚举（与FarmManager保持一致）
enum CropType {
	WHEAT,          # 小麦
	CORN,           # 玉米
	CARROT,         # 胡萝卜
	HEALING_HERB,   # 治疗药草
	RARE_HERB       # 稀有药草
}

# 生长阶段枚举
enum GrowthStage {
	SEED,           # 种子阶段
	SPROUT,         # 幼苗阶段
	GROWING,        # 生长期
	MATURE,         # 成熟期
	OVERGROWN,      # 过度生长（品质下降）
	WILTED          # 枯萎
}

# 作物配置
@export var crop_name: String = "未命名作物"
@export var crop_type: CropType = CropType.WHEAT
@export var description: String = "基础作物"
@export var total_growth_time: float = 120.0  # 总生长时间（秒）
@export var yield_amount: int = 3            # 收获数量
@export var seed_cost: int = 1               # 种植所需种子数
@export var product_id: String = "wheat"     # 收获物品ID

# 生长阶段配置（进度阈值）
@export var stage_thresholds: Dictionary = {
	GrowthStage.SEED: 0.0,
	GrowthStage.SPROUT: 0.2,
	GrowthStage.GROWING: 0.5,
	GrowthStage.MATURE: 0.8,
	GrowthStage.OVERGROWN: 1.0,
	GrowthStage.WILTED: 1.2  # 超过100%开始枯萎
}

# 生长阶段精灵
@export var growth_sprites: Array[Texture2D] = []

# 当前状态
var current_growth_stage: GrowthStage = GrowthStage.SEED
var growth_progress: float = 0.0  # 0.0-1.0（1.0为完全成熟）
var is_planted: bool = false
var planted_time: float = 0.0
var last_update_time: float = 0.0

# 生长效果乘数
var growth_multiplier: float = 1.0

# 节点引用
@onready var sprite: Sprite2D = $Sprite2D

# 信号
signal crop_planted(crop: CropBase)
signal growth_stage_changed(crop: CropBase, old_stage: GrowthStage, new_stage: GrowthStage)
signal growth_progress_updated(crop: CropBase, progress: float)
signal crop_matured(crop: CropBase)
signal crop_overgrown(crop: CropBase)
signal crop_wilted(crop: CropBase)
signal crop_harvested(crop: CropBase, yield_amount: int)

func _ready():
	# 初始化作物
	_setup_crop()
	
	# 设置初始精灵
	_update_sprite()

func _setup_crop():
	"""初始化作物配置"""
	# 子类可以重写此方法来设置特定属性
	pass

func plant():
	"""种植作物"""
	if is_planted:
		print("作物已经种植")
		return false
	
	is_planted = true
	planted_time = Time.get_ticks_msec() / 1000.0
	last_update_time = planted_time
	
	current_growth_stage = GrowthStage.SEED
	growth_progress = 0.0
	
	crop_planted.emit(self)
	print("作物已种植: %s" % crop_name)
	
	return true

func update_growth(progress: float):
	"""更新生长进度（外部调用）"""
	if not is_planted:
		return
	
	var old_progress = growth_progress
	growth_progress = progress
	
	# 检查生长阶段变化
	var old_stage = current_growth_stage
	var new_stage = _calculate_current_stage(progress)
	
	if new_stage != old_stage:
		current_growth_stage = new_stage
		growth_stage_changed.emit(self, old_stage, new_stage)
		
		# 触发阶段特定事件
		_on_growth_stage_changed(old_stage, new_stage)
	
	# 发送进度更新
	growth_progress_updated.emit(self, progress)
	
	# 更新精灵
	_update_sprite()

func _calculate_current_stage(progress: float) -> GrowthStage:
	"""根据进度计算当前生长阶段"""
	var current_stage = GrowthStage.SEED
	
	# 从后往前检查，找到第一个进度超过阈值的阶段
	for stage in GrowthStage.values():
		if progress >= stage_thresholds[stage]:
			current_stage = stage
		else:
			break
	
	return current_stage

func _on_growth_stage_changed(old_stage: GrowthStage, new_stage: GrowthStage):
	"""生长阶段变化时的处理"""
	print("作物生长阶段变化: %s -> %s" % [
		GrowthStage.keys()[old_stage],
		GrowthStage.keys()[new_stage]
	])
	
	# 触发特定阶段事件
	match new_stage:
		GrowthStage.MATURE:
			crop_matured.emit(self)
			print("作物成熟: %s" % crop_name)
		
		GrowthStage.OVERGROWN:
			crop_overgrown.emit(self)
			print("作物过度生长: %s" % crop_name)
		
		GrowthStage.WILTED:
			crop_wilted.emit(self)
			print("作物枯萎: %s" % crop_name)

func _update_sprite():
	"""更新作物精灵"""
	if not sprite:
		return
	
	# 根据当前生长阶段选择精灵
	var stage_index = current_growth_stage
	if stage_index < growth_sprites.size() and growth_sprites[stage_index]:
		sprite.texture = growth_sprites[stage_index]
	else:
		# 如果没有指定精灵，使用默认颜色
		match current_growth_stage:
			GrowthStage.SEED:
				sprite.modulate = Color(0.6, 0.4, 0.2)
			GrowthStage.SPROUT:
				sprite.modulate = Color(0.3, 0.7, 0.3)
			GrowthStage.GROWING:
				sprite.modulate = Color(0.2, 0.8, 0.2)
			GrowthStage.MATURE:
				sprite.modulate = Color(0.9, 0.9, 0.2)
			GrowthStage.OVERGROWN:
				sprite.modulate = Color(0.5, 0.5, 0.1)
			GrowthStage.WILTED:
				sprite.modulate = Color(0.4, 0.3, 0.2)

func harvest() -> Dictionary:
	"""收获作物"""
	if not is_planted:
		return {
			"success": false,
			"message": "作物未种植",
			"yield_amount": 0
		}
	
	# 只有成熟和过度生长阶段可以收获
	if current_growth_stage < GrowthStage.MATURE:
		return {
			"success": false,
			"message": "作物尚未成熟",
			"yield_amount": 0
		}
	
	if current_growth_stage == GrowthStage.WILTED:
		return {
			"success": false,
			"message": "作物已枯萎，无法收获",
			"yield_amount": 0
		}
	
	# 计算实际产量（过度生长阶段产量减少）
	var actual_yield = yield_amount
	if current_growth_stage == GrowthStage.OVERGROWN:
		actual_yield = max(1, yield_amount / 2)
		print("作物过度生长，产量减少: %d -> %d" % [yield_amount, actual_yield])
	
	# 发送收获信号
	crop_harvested.emit(self, actual_yield)
	
	# 重置作物状态
	is_planted = false
	
	print("作物收获完成: %s ×%d" % [crop_name, actual_yield])
	
	return {
		"success": true,
		"message": "收获成功",
		"crop_name": crop_name,
		"yield_amount": actual_yield,
		"product_id": product_id
	}

func get_current_growth_stage() -> GrowthStage:
	"""获取当前生长阶段"""
	return current_growth_stage

func get_current_growth_stage_name() -> String:
	"""获取当前生长阶段名称"""
	return GrowthStage.keys()[current_growth_stage]

func get_growth_progress() -> float:
	"""获取生长进度"""
	return growth_progress

func get_growth_percentage() -> float:
	"""获取生长百分比"""
	return growth_progress * 100

func is_mature() -> bool:
	"""检查是否成熟"""
	return current_growth_stage == GrowthStage.MATURE

func is_harvestable() -> bool:
	"""检查是否可以收获"""
	return current_growth_stage >= GrowthStage.MATURE and current_growth_stage != GrowthStage.WILTED

func get_yield_amount() -> int:
	"""获取收获数量"""
	return yield_amount

func get_product_id() -> String:
	"""获取收获物品ID"""
	return product_id

func get_growth_rate() -> float:
	"""获取生长速度（子类可重写）"""
	return 1.0 / total_growth_time

func get_total_growth_time() -> float:
	"""获取总生长时间"""
	return total_growth_time

func get_crop_info() -> Dictionary:
	"""获取作物信息"""
	return {
		"name": crop_name,
		"type": CropType.keys()[crop_type],
		"growth_stage": get_current_growth_stage_name(),
		"growth_progress": growth_progress,
		"growth_percentage": get_growth_percentage(),
		"yield_amount": yield_amount,
		"product_id": product_id,
		"is_planted": is_planted,
		"is_harvestable": is_harvestable()
	}

func apply_growth_boost(multiplier: float):
	"""应用生长加速效果"""
	growth_multiplier *= multiplier
	print("作物生长加速: %.1fx" % multiplier)

func apply_frost_damage(damage: float):
	"""受到霜冻伤害"""
	if current_growth_stage < GrowthStage.MATURE:
		growth_progress = max(0, growth_progress - damage)
		print("作物受到霜冻伤害，生长进度减少: %.1f%%" % (damage * 100))

func apply_drought_damage(damage: float):
	"""受到干旱伤害"""
	if current_growth_stage < GrowthStage.MATURE:
		growth_progress = max(0, growth_progress - damage)
		print("作物受到干旱伤害，生长进度减少: %.1f%%" % (damage * 100))