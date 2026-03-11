extends Area2D
class_name ResourceNode

# 资源类型枚举
enum ResourceType {
	WOOD,
	ORE,
	HERB
}

# 导出变量
@export var resource_type: ResourceType = ResourceType.WOOD
@export var resource_amount: int = 1
@export var respawn_time: float = 30.0  # 重生时间（秒）
@export var can_be_collected: bool = true

# 资源节点视觉组件
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# 种子掉落概率（仅对药草有效）
const SEED_DROP_CHANCE: float = 0.3

# 信号
signal resource_collected(player, resource_type, amount, dropped_seed)
signal resource_depleted

var _is_active: bool = true
var _respawn_timer: float = 0.0

func _ready():
	# 根据资源类型设置视觉
	_setup_visuals()
	
	# 连接区域进入/退出信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta):
	# 处理重生计时器
	if not _is_active and respawn_time > 0:
		_respawn_timer += delta
		if _respawn_timer >= respawn_time:
			_respawn()

func _setup_visuals():
	# 根据资源类型设置不同的颜色和缩放
	match resource_type:
		ResourceType.WOOD:
			if sprite:
				sprite.modulate = Color("8b4513")  # 棕色
				sprite.scale = Vector2(0.5, 0.5)
		ResourceType.ORE:
			if sprite:
				sprite.modulate = Color("808080")  # 灰色
				sprite.scale = Vector2(0.5, 0.5)
		ResourceType.HERB:
			if sprite:
				sprite.modulate = Color("32cd32")  # 绿色
				sprite.scale = Vector2(0.5, 0.5)

func _on_body_entered(body: Node2D):
	# 当玩家进入采集区域时
	if body.is_in_group("player") and can_be_collected and _is_active:
		# 可以在这里显示交互提示
		pass

func _on_body_exited(body: Node2D):
	# 当玩家离开采集区域时
	if body.is_in_group("player"):
		# 可以在这里隐藏交互提示
		pass

func collect(player: Node) -> Dictionary:
	"""
	采集资源，返回采集结果
	返回: { "resource_type": ResourceType, "amount": int, "dropped_seed": bool }
	"""
	if not can_be_collected or not _is_active:
		return {}
	
	# 确定是否掉落种子（仅对药草有效）
	var dropped_seed: bool = false
	if resource_type == ResourceType.HERB:
		dropped_seed = randf() < SEED_DROP_CHANCE
	
	# 发送采集信号
	resource_collected.emit(player, resource_type, resource_amount, dropped_seed)
	
	# 禁用节点（直到重生）
	_is_active = false
	if sprite:
		sprite.visible = false
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	# 如果不需要重生，则发送耗尽信号
	if respawn_time <= 0:
		resource_depleted.emit()
		queue_free()
	
	# 返回采集结果
	return {
		"resource_type": resource_type,
		"amount": resource_amount,
		"dropped_seed": dropped_seed
	}

func _respawn():
	"""重生资源节点"""
	_is_active = true
	_respawn_timer = 0.0
	if sprite:
		sprite.visible = true
	if collision_shape:
		collision_shape.set_deferred("disabled", false)

func get_resource_type_name() -> String:
	"""获取资源类型名称"""
	match resource_type:
		ResourceType.WOOD:
			return "木材"
		ResourceType.ORE:
			return "矿石"
		ResourceType.HERB:
			return "药草"
		_:
			return "未知"

func is_active() -> bool:
	return _is_active