extends Node
class_name InventoryManager

# 资源类型枚举（与ResourceNode保持一致）
enum ResourceType {
	WOOD,
	ORE,
	HERB,
	SEED  # 种子是特殊资源
}

# 背包数据
var inventory: Dictionary = {
	ResourceType.WOOD: 0,
	ResourceType.ORE: 0,
	ResourceType.HERB: 0,
	ResourceType.SEED: 0
}

# 背包容量限制（0表示无限制）
var capacity_limits: Dictionary = {
	ResourceType.WOOD: 0,
	ResourceType.ORE: 0,
	ResourceType.HERB: 0,
	ResourceType.SEED: 0
}

# 信号
signal inventory_updated(resource_type, new_amount, delta)
signal inventory_full(resource_type)
signal seed_dropped(count)

func _ready():
	# 初始化背包（可以加载存档）
	pass

func add_resource(resource_type: ResourceType, amount: int = 1) -> bool:
	"""添加资源到背包，返回是否成功"""
	if amount <= 0:
		return false
	
	# 检查容量限制
	var current: int = inventory.get(resource_type, 0)
	var limit: int = capacity_limits.get(resource_type, 0)
	
	if limit > 0 and current + amount > limit:
		# 超过容量，只能添加部分
		var can_add: int = limit - current
		if can_add > 0:
			inventory[resource_type] = current + can_add
			inventory_updated.emit(resource_type, inventory[resource_type], can_add)
			print("背包容量不足，只能添加 %d 个%s（已满）" % [can_add, _get_resource_name(resource_type)])
			inventory_full.emit(resource_type)
		else:
			print("背包中%s已满，无法添加" % _get_resource_name(resource_type))
			inventory_full.emit(resource_type)
		return false
	
	# 正常添加
	inventory[resource_type] = current + amount
	inventory_updated.emit(resource_type, inventory[resource_type], amount)
	
	# 控制台输出
	print("背包更新：%s +%d = %d" % [
		_get_resource_name(resource_type),
		amount,
		inventory[resource_type]
	])
	
	return true

func remove_resource(resource_type: ResourceType, amount: int = 1) -> bool:
	"""从背包移除资源，返回是否成功"""
	if amount <= 0:
		return false
	
	var current: int = inventory.get(resource_type, 0)
	if current < amount:
		print("背包中%s不足，需要%d但只有%d" % [
			_get_resource_name(resource_type),
			amount,
			current
		])
		return false
	
	inventory[resource_type] = current - amount
	inventory_updated.emit(resource_type, inventory[resource_type], -amount)
	
	print("背包更新：%s -%d = %d" % [
		_get_resource_name(resource_type),
		amount,
		inventory[resource_type]
	])
	
	return true

func get_resource_amount(resource_type: ResourceType) -> int:
	"""获取指定资源的数量"""
	return inventory.get(resource_type, 0)

func has_resource(resource_type: ResourceType, amount: int = 1) -> bool:
	"""检查是否有足够数量的指定资源"""
	return get_resource_amount(resource_type) >= amount

func set_capacity_limit(resource_type: ResourceType, limit: int):
	"""设置资源容量限制（0表示无限制）"""
	if limit < 0:
		limit = 0
	capacity_limits[resource_type] = limit

func get_capacity_limit(resource_type: ResourceType) -> int:
	"""获取资源容量限制"""
	return capacity_limits.get(resource_type, 0)

func get_remaining_capacity(resource_type: ResourceType) -> int:
	"""获取剩余容量"""
	var limit: int = get_capacity_limit(resource_type)
	if limit == 0:
		return INF
	var current: int = get_resource_amount(resource_type)
	return max(0, limit - current)

func get_all_resources() -> Dictionary:
	"""获取所有资源数据（副本）"""
	return inventory.duplicate()

func clear_inventory():
	"""清空背包"""
	for resource_type in inventory.keys():
		inventory[resource_type] = 0
	inventory_updated.emit(-1, 0, 0)  # -1表示所有资源
	print("背包已清空")

func add_seed(count: int = 1) -> bool:
	"""添加种子（特殊方法）"""
	if count <= 0:
		return false
	
	var success: bool = add_resource(ResourceType.SEED, count)
	if success:
		seed_dropped.emit(count)
		print("获得种子！当前种子数量：%d" % get_resource_amount(ResourceType.SEED))
	
	return success

func _get_resource_name(resource_type: ResourceType) -> String:
	"""获取资源类型名称"""
	match resource_type:
		ResourceType.WOOD:
			return "木材"
		ResourceType.ORE:
			return "矿石"
		ResourceType.HERB:
			return "药草"
		ResourceType.SEED:
			return "种子"
		_:
			return "未知"

# 静态方法：获取全局InventoryManager实例
static func get_instance() -> InventoryManager:
	return Engine.get_singleton("InventoryManager") if Engine.has_singleton("InventoryManager") else null

# 为了方便，也提供全局函数
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# 清理时保存数据
		pass