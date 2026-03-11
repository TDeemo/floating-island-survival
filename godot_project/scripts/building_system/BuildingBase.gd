# BuildingBase.gd - 建筑基类
# 所有建筑的通用基类，提供建筑状态管理、交互接口和基础功能

extends Node2D
class_name BuildingBase

# 建筑状态枚举
enum BuildingState {
	PLANNED,      # 规划中（预览状态）
	CONSTRUCTING, # 建造中
	ACTIVE,       # 活跃可用
	UPGRADING,    # 升级中
	DAMAGED,      # 受损
	DESTROYED     # 被摧毁
}

# 建筑数据
@export var building_name: String = "未命名建筑"
@export var building_type: BuildingManager.BuildingType = BuildingManager.BuildingType.WORKBENCH
@export var description: String = "基础建筑"
@export var max_health: int = 100
@export var build_time: float = 5.0  # 建造所需时间（秒）
@export var resource_cost: Dictionary = {"wood": 10, "stone": 5}

# 状态变量
var current_health: int = max_health
var current_state: BuildingState = BuildingState.PLANNED
var build_progress: float = 0.0  # 0.0-1.0
var is_constructed: bool = false
var is_interactable: bool = true

# 节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var highlight_area: Area2D = $HighlightArea

# 信号
signal construction_started(building: BuildingBase)
signal construction_progress(building: BuildingBase, progress: float)
signal construction_completed(building: BuildingBase)
signal building_damaged(building: BuildingBase, damage: int, new_health: int)
signal building_destroyed(building: BuildingBase)
signal building_interacted(building: BuildingBase, player: Node)
signal building_upgraded(building: BuildingBase, old_level: int, new_level: int)

func _ready():
	# 初始化建筑状态
	_setup_building()
	
	# 如果是预览状态，设置为半透明
	if current_state == BuildingState.PLANNED:
		sprite.modulate = Color(1, 1, 1, 0.5)
		collision_shape.set_deferred("disabled", true)
	
	# 连接信号
	if progress_bar:
		progress_bar.visible = false

func _setup_building():
	"""初始化建筑配置"""
	# 子类可以重写此方法来设置特定属性
	pass

func start_construction():
	"""开始建造建筑"""
	if current_state != BuildingState.PLANNED:
		return
	
	current_state = BuildingState.CONSTRUCTING
	construction_started.emit(self)
	
	# 开始建造计时器
	var timer = get_tree().create_timer(build_time)
	timer.timeout.connect(_on_construction_complete)
	
	# 显示进度条
	if progress_bar:
		progress_bar.visible = true
		progress_bar.max_value = build_time
		progress_bar.value = 0
	
	# 模拟建造进度更新（实际游戏中可能由工人系统驱动）
	_update_construction_progress()

func _update_construction_progress():
	"""更新建造进度（简化版本，实际应基于时间或工人效率）"""
	var elapsed = 0.0
	while elapsed < build_time:
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
		build_progress = elapsed / build_time
		
		construction_progress.emit(self, build_progress)
		
		if progress_bar:
			progress_bar.value = elapsed

func _on_construction_complete():
	"""建造完成"""
	current_state = BuildingState.ACTIVE
	is_constructed = true
	sprite.modulate = Color(1, 1, 1, 1)
	
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	
	if progress_bar:
		progress_bar.visible = false
	
	construction_completed.emit(self)
	print("建筑建造完成: %s" % building_name)

func take_damage(damage: int):
	"""建筑受到伤害"""
	if current_state == BuildingState.DESTROYED:
		return
	
	current_health = max(0, current_health - damage)
	building_damaged.emit(self, damage, current_health)
	
	if current_health <= 0:
		destroy()

func heal(amount: int):
	"""修复建筑"""
	if current_state == BuildingState.DESTROYED:
		return
	
	current_health = min(max_health, current_health + amount)
	print("建筑修复: %s, 当前生命值: %d" % [building_name, current_health])

func destroy():
	"""摧毁建筑"""
	current_state = BuildingState.DESTROYED
	is_interactable = false
	
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 0.5, 0.5)
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	building_destroyed.emit(self)
	print("建筑被摧毁: %s" % building_name)

func interact(player: Node):
	"""玩家与建筑交互"""
	if not is_interactable or not is_constructed:
		return
	
	building_interacted.emit(self, player)
	print("玩家与建筑交互: %s" % building_name)
	
	# 子类应该重写此方法来实现具体功能
	_on_interact(player)

func _on_interact(player: Node):
	"""交互的具体实现（由子类重写）"""
	pass

func upgrade():
	"""升级建筑"""
	if current_state != BuildingState.ACTIVE:
		return
	
	current_state = BuildingState.UPGRADING
	print("建筑开始升级: %s" % building_name)
	
	# 这里应该实现升级逻辑
	# 暂时简化：直接完成升级
	_finish_upgrade()

func _finish_upgrade():
	"""完成升级"""
	# 子类应该重写此方法
	current_state = BuildingState.ACTIVE
	print("建筑升级完成: %s" % building_name)

func can_build() -> bool:
	"""检查是否可以建造（资源是否充足）"""
	# 需要与InventoryManager集成
	# 暂时返回true
	return true

func get_resource_cost() -> Dictionary:
	"""获取建筑资源消耗"""
	return resource_cost

func get_build_time() -> float:
	"""获取建造时间"""
	return build_time

func is_fully_constructed() -> bool:
	"""检查建筑是否完全建造"""
	return is_constructed

func get_state() -> BuildingState:
	"""获取当前状态"""
	return current_state

func set_planned_state():
	"""设置为规划状态（预览模式）"""
	current_state = BuildingState.PLANNED
	sprite.modulate = Color(1, 1, 1, 0.5)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

func set_active_state():
	"""设置为活跃状态"""
	current_state = BuildingState.ACTIVE
	is_constructed = true
	sprite.modulate = Color(1, 1, 1, 1)
	if collision_shape:
		collision_shape.set_deferred("disabled", false)