# StorageChest.gd - 储物箱建筑
# 用于存储资源和物品

extends BuildingBase
class_name StorageChest

# 储物槽位类
class StorageSlot:
	var item_id: String
	var item_count: int
	var max_stack: int
	
	func _init(id: String = "", count: int = 0, stack: int = 99):
		item_id = id
		item_count = count
		max_stack = stack
	
	func is_empty() -> bool:
		return item_id.is_empty() or item_count == 0
	
	func can_add_item(id: String, count: int) -> bool:
		if is_empty():
			return true
		if item_id != id:
			return false
		return item_count + count <= max_stack
	
	func add_item(count: int) -> bool:
		if is_empty():
			return false
		if item_count + count > max_stack:
			return false
		item_count += count
		return true
	
	func remove_item(count: int) -> bool:
		if is_empty():
			return false
		if count > item_count:
			return false
		item_count -= count
		if item_count == 0:
			item_id = ""
		return true
	
	func get_remaining_space() -> int:
		if is_empty():
			return max_stack
		return max_stack - item_count

# 存储系统配置
@export var storage_capacity: int = 20  # 槽位数量
@export var default_max_stack: int = 99  # 默认最大堆叠数

# 存储数据
var storage_slots: Array[StorageSlot] = []
var total_items: int = 0
var total_weight: float = 0.0

# 信号
signal storage_opened(chest: StorageChest)
signal storage_closed(chest: StorageChest)
signal item_added(chest: StorageChest, item_id: String, count: int, slot_index: int)
signal item_removed(chest: StorageChest, item_id: String, count: int, slot_index: int)
signal storage_updated(chest: StorageChest, total_items: int)

func _ready():
	# 调用父类的_ready
	super._ready()
	
	# 设置储物箱特定属性
	building_name = "储物箱"
	building_type = BuildingManager.BuildingType.STORAGE_CHEST
	description = "用于存储资源和物品"
	resource_cost = {"wood": 15, "stone": 5}
	build_time = 6.0
	
	# 初始化存储槽位
	_init_storage_slots()

func _setup_building():
	"""初始化储物箱配置"""
	# 设置储物箱特有的视觉元素
	if sprite:
		sprite.texture = load("res://assets/sprites/storage_chest.png")

func _init_storage_slots():
	"""初始化存储槽位"""
	storage_slots.clear()
	for i in range(storage_capacity):
		storage_slots.append(StorageSlot.new("", 0, default_max_stack))
	print("储物箱初始化完成，共 %d 个存储槽位" % storage_capacity)

func _on_interact(player: Node):
	"""玩家与储物箱交互"""
	print("打开储物箱")
	storage_opened.emit(self)
	
	# 显示存储界面（实际游戏中应调用UI管理器）
	_show_storage_interface(player)

func _show_storage_interface(player: Node):
	"""显示存储界面（简化版本）"""
	print("=== 储物箱存储界面 ===")
	print("当前存储内容：")
	
	var empty_slots = 0
	for i in range(storage_slots.size()):
		var slot = storage_slots[i]
		if slot.is_empty():
			empty_slots += 1
		else:
			print("槽位 %d: %s ×%d" % [i + 1, slot.item_id, slot.item_count])
	
	print("空槽位: %d/%d" % [empty_slots, storage_slots.size()])
	print("输入指令进行操作（如：存入 物品ID 数量，取出 槽位 数量，退出）")
	# 实际游戏中应该通过GUI处理交互

func add_item(item_id: String, count: int) -> Dictionary:
	"""添加物品到储物箱"""
	if count <= 0:
		return {"success": false, "message": "数量必须大于0"}
	
	var remaining = count
	var added_slots = []
	
	# 尝试添加到现有堆叠中
	for i in range(storage_slots.size()):
		if remaining <= 0:
			break
		
		var slot = storage_slots[i]
		if slot.can_add_item(item_id, remaining):
			var add_amount = min(remaining, slot.get_remaining_space())
			if slot.is_empty():
				slot.item_id = item_id
				slot.item_count = add_amount
			else:
				slot.add_item(add_amount)
			
			remaining -= add_amount
			added_slots.append(i)
			item_added.emit(self, item_id, add_amount, i)
	
	# 如果还有剩余，尝试添加到空槽位
	for i in range(storage_slots.size()):
		if remaining <= 0:
			break
		
		var slot = storage_slots[i]
		if slot.is_empty():
			var add_amount = min(remaining, default_max_stack)
			slot.item_id = item_id
			slot.item_count = add_amount
			
			remaining -= add_amount
			added_slots.append(i)
			item_added.emit(self, item_id, add_amount, i)
	
	# 更新统计数据
	total_items += (count - remaining)
	storage_updated.emit(self, total_items)
	
	if remaining > 0:
		return {
			"success": false,
			"message": "储物箱空间不足",
			"added": count - remaining,
			"remaining": remaining,
			"slots": added_slots
		}
	else:
		return {
			"success": true,
			"message": "物品添加成功",
			"added": count,
			"slots": added_slots
		}

func remove_item(slot_index: int, count: int) -> Dictionary:
	"""从指定槽位移除物品"""
	if slot_index < 0 or slot_index >= storage_slots.size():
		return {"success": false, "message": "无效的槽位索引"}
	
	var slot = storage_slots[slot_index]
	if slot.is_empty():
		return {"success": false, "message": "槽位为空"}
	
	if count > slot.item_count:
		return {"success": false, "message": "数量超过槽位中物品数量"}
	
	var item_id = slot.item_id
	slot.remove_item(count)
	
	total_items -= count
	item_removed.emit(self, item_id, count, slot_index)
	storage_updated.emit(self, total_items)
	
	return {
		"success": true,
		"message": "物品移除成功",
		"item_id": item_id,
		"count": count,
		"remaining": slot.item_count
	}

func transfer_item_to_player(slot_index: int, count: int, player_inventory) -> Dictionary:
	"""将物品从储物箱转移到玩家背包"""
	var remove_result = remove_item(slot_index, count)
	if not remove_result.success:
		return remove_result
	
	# 这里需要调用玩家背包的添加方法
	# 暂时简化：假设玩家背包可以接收
	print("物品转移到玩家背包: %s ×%d" % [remove_result.get("item_id", ""), count])
	
	return {
		"success": true,
		"message": "物品转移成功",
		"item_id": remove_result.get("item_id", ""),
		"count": count
	}

func transfer_item_from_player(item_id: String, count: int, player_inventory) -> Dictionary:
	"""将物品从玩家背包转移到储物箱"""
	# 这里需要检查玩家是否有足够物品
	# 暂时简化：假设玩家有足够物品
	
	var add_result = add_item(item_id, count)
	if not add_result.success:
		return add_result
	
	print("物品从玩家背包转移到储物箱: %s ×%d" % [item_id, count])
	
	return {
		"success": true,
		"message": "物品转移成功",
		"item_id": item_id,
		"count": add_result.get("added", 0)
	}

func get_item_count(item_id: String) -> int:
	"""获取指定物品的总数量"""
	var total = 0
	for slot in storage_slots:
		if not slot.is_empty() and slot.item_id == item_id:
			total += slot.item_count
	return total

func has_item(item_id: String, count: int = 1) -> bool:
	"""检查是否有指定数量的物品"""
	return get_item_count(item_id) >= count

func get_empty_slot_count() -> int:
	"""获取空槽位数量"""
	var count = 0
	for slot in storage_slots:
		if slot.is_empty():
			count += 1
	return count

func get_occupied_slot_count() -> int:
	"""获取已使用槽位数量"""
	return storage_slots.size() - get_empty_slot_count()

func get_total_weight() -> float:
	"""获取储物箱总重量（需要物品重量数据）"""
	# 暂时返回0，实际需要根据物品重量计算
	return total_weight

func is_full() -> bool:
	"""检查储物箱是否已满"""
	return get_empty_slot_count() == 0

func get_storage_info() -> Dictionary:
	"""获取储物箱信息"""
	return {
		"capacity": storage_capacity,
		"empty_slots": get_empty_slot_count(),
		"occupied_slots": get_occupied_slot_count(),
		"total_items": total_items,
		"is_full": is_full()
	}

func find_item_slots(item_id: String) -> Array:
	"""查找包含指定物品的所有槽位索引"""
	var slots = []
	for i in range(storage_slots.size()):
		var slot = storage_slots[i]
		if not slot.is_empty() and slot.item_id == item_id:
			slots.append(i)
	return slots

func clear_storage():
	"""清空储物箱"""
	for i in range(storage_slots.size()):
		var slot = storage_slots[i]
		if not slot.is_empty():
			item_removed.emit(self, slot.item_id, slot.item_count, i)
			slot.item_id = ""
			slot.item_count = 0
	
	total_items = 0
	total_weight = 0.0
	storage_updated.emit(self, total_items)
	print("储物箱已清空")

func upgrade_capacity(new_capacity: int):
	"""升级储物箱容量"""
	if new_capacity <= storage_capacity:
		print("新容量必须大于当前容量")
		return
	
	# 添加新的槽位
	for i in range(storage_capacity, new_capacity):
		storage_slots.append(StorageSlot.new("", 0, default_max_stack))
	
	storage_capacity = new_capacity
	print("储物箱容量升级完成，新容量: %d" % storage_capacity)