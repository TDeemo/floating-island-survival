extends Node2D
class_name ResourceCollector

# 导出变量
@export var interaction_range: float = 50.0  # 交互范围（像素）
@export var interaction_key: String = "ui_select"  # 交互按键
@export var auto_collect: bool = false  # 是否自动采集（靠近即采集）

# 组件引用
@onready var player: CharacterBody2D = get_parent()

# 当前附近的资源节点
var _nearby_resources: Array[ResourceNode] = []
var _closest_resource: ResourceNode = null

# 信号
signal resource_detected(resource_node)
signal resource_lost(resource_node)
signal resource_collected(resource_type, amount, dropped_seed)

func _ready():
	# 确保父节点是CharacterBody2D
	if not player is CharacterBody2D:
		push_error("ResourceCollector必须附加到CharacterBody2D节点上")
		return
	
	# 连接输入处理
	set_process_input(true)

func _process(_delta):
	# 更新附近的资源节点
	_update_nearby_resources()
	
	# 自动采集逻辑
	if auto_collect and _closest_resource:
		_collect_resource(_closest_resource)

func _input(event):
	# 处理交互按键
	if event.is_action_pressed(interaction_key) and _closest_resource:
		_collect_resource(_closest_resource)

func _update_nearby_resources():
	# 获取所有资源节点
	var all_resources: Array[ResourceNode] = get_tree().get_nodes_in_group("resource_nodes")
	
	# 清空当前列表
	_nearby_resources.clear()
	_closest_resource = null
	
	var closest_distance: float = INF
	var closest_resource: ResourceNode = null
	
	# 筛选在交互范围内的资源节点
	for resource in all_resources:
		if not resource.is_active():
			continue
		
		var distance: float = player.global_position.distance_to(resource.global_position)
		if distance <= interaction_range:
			_nearby_resources.append(resource)
			
			# 找到最近的可采集资源
			if distance < closest_distance:
				closest_distance = distance
				closest_resource = resource
	
	# 更新最近资源
	_closest_resource = closest_resource
	
	# 可以在这里显示/隐藏交互提示
	# 例如：if _closest_resource: show_interaction_prompt()

func _collect_resource(resource: ResourceNode):
	"""采集指定资源"""
	if not resource or not resource.is_active():
		return
	
	# 调用资源的collect方法
	var result: Dictionary = resource.collect(player)
	if result.is_empty():
		return
	
	# 发送采集信号
	resource_collected.emit(
		result["resource_type"],
		result["amount"],
		result.get("dropped_seed", false)
	)
	
	# 控制台输出（用于验证）
	var resource_name: String = resource.get_resource_type_name()
	var seed_info: String = ""
	if result.get("dropped_seed", false):
		seed_info = "，并获得了种子！"
	
	print("采集了 %d 个%s%s" % [result["amount"], resource_name, seed_info])

func add_resource_to_group(resource: ResourceNode):
	"""将资源节点添加到资源组中（在资源节点创建时调用）"""
	if not resource.is_in_group("resource_nodes"):
		resource.add_to_group("resource_nodes")

func get_nearby_resources() -> Array[ResourceNode]:
	"""获取附近的所有资源节点"""
	return _nearby_resources.duplicate()

func get_closest_resource() -> ResourceNode:
	"""获取最近的资源节点"""
	return _closest_resource

func is_resource_in_range() -> bool:
	"""是否有资源在交互范围内"""
	return _closest_resource != null

func get_interaction_prompt() -> String:
	"""获取交互提示文本"""
	if _closest_resource:
		return "按 %s 采集 %s" % [
			interaction_key,
			_closest_resource.get_resource_type_name()
		]
	return ""