## 怪物AI组件
## 处理怪物的AI决策、行为树和目标检测
class_name MonsterAI
extends Node

# AI行为类型
enum AIBehavior {
	SIMPLE_PATROL,   # 简单巡逻
	AGGRESSIVE_CHASE, # 主动追击
	DEFENSIVE_GUARD,  # 防御性守卫
	AMBUSH,           # 伏击
	BOSS              # BOSS特殊行为
}

# 导出配置
## AI行为类型
@export var ai_behavior: AIBehavior = AIBehavior.SIMPLE_PATROL
## 检测间隔（秒）
@export var detection_interval: float = 0.5
## 是否启用视线检测（需要光线投射）
@export var use_line_of_sight: bool = true
## 视线检测角度（度）
@export var sight_angle: float = 90.0
## 是否忽略地形障碍
@export var ignore_terrain_obstacles: bool = false

# 引用
var monster: MonsterBase = null
var player_group: String = "player"
var players_in_scene: Array[Node2D] = []

# 检测计时器
var detection_timer: float = 0.0

func _ready() -> void:
	# 获取父节点（应为MonsterBase）
	monster = get_parent() as MonsterBase
	if not monster:
		push_error("MonsterAI必须附加到MonsterBase节点上")
		return
	
	# 初始检测
	detection_timer = detection_interval

func _process(delta: float) -> void:
	if not monster:
		return
	
	# 只在特定状态下进行AI决策
	if monster.current_state in [MonsterBase.MonsterState.DEAD, MonsterBase.MonsterState.ATTACK]:
		return
	
	# 更新检测计时器
	detection_timer -= delta
	if detection_timer <= 0:
		_detect_targets()
		detection_timer = detection_interval
	
	# 根据AI行为类型决策
	_make_decision()

func _detect_targets() -> void:
	# 清空之前的检测结果
	players_in_scene.clear()
	
	# 查找场景中所有玩家
	var all_players = get_tree().get_nodes_in_group(player_group)
	for player in all_players:
		if player is Node2D:
			players_in_scene.append(player)
	
	# 如果没有目标且当前有目标，检查目标是否还在范围内
	if monster.target and not _is_target_valid(monster.target):
		monster.target = null
		if monster.current_state in [MonsterBase.MonsterState.CHASE, MonsterBase.MonsterState.ATTACK]:
			monster._change_state(MonsterBase.MonsterState.RETURNING)
	
	# 如果当前没有目标，尝试选择新目标
	if not monster.target:
		_select_new_target()

func _is_target_valid(target: Node2D) -> bool:
	if not is_instance_valid(target):
		return false
	
	# 检查距离
	var distance = monster.global_position.distance_to(target.global_position)
	if distance > monster.chase_range:
		return false
	
	# 检查视线（如果启用）
	if use_line_of_sight and not ignore_terrain_obstacles:
		return _has_line_of_sight(target)
	
	return true

func _has_line_of_sight(target: Node2D) -> bool:
	# 创建光线投射查询
	var space_state = monster.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		monster.global_position,
		target.global_position
	)
	query.collision_mask = 0b1  # 假设地形在第1层
	query.exclude = [monster]
	
	var result = space_state.intersect_ray(query)
	
	# 如果没有碰撞到地形，则有视线
	return result.is_empty()

func _select_new_target() -> void:
	var best_target: Node2D = null
	var best_distance: float = INF
	
	for player in players_in_scene:
		if not is_instance_valid(player):
			continue
		
		var distance = monster.global_position.distance_to(player.global_position)
		
		# 如果在视野范围内
		if distance <= monster.sight_range:
			# 检查视线（如果启用）
			if use_line_of_sight and not _has_line_of_sight(player):
				continue
			
			# 根据距离选择最近的目标
			if distance < best_distance:
				best_distance = distance
				best_target = player
	
	if best_target:
		monster.set_target(best_target)

func _make_decision() -> void:
	match ai_behavior:
		AIBehavior.SIMPLE_PATROL:
			_simple_patrol_decision()
		AIBehavior.AGGRESSIVE_CHASE:
			_aggressive_chase_decision()
		AIBehavior.DEFENSIVE_GUARD:
			_defensive_guard_decision()
		AIBehavior.AMBUSH:
			_ambush_decision()
		AIBehavior.BOSS:
			_boss_decision()

func _simple_patrol_decision() -> void:
	# 简单巡逻AI：有目标就追，没目标就巡逻
	if monster.target:
		if monster.current_state != MonsterBase.MonsterState.CHASE:
			monster._change_state(MonsterBase.MonsterState.CHASE)
	elif monster.patrol_points.size() > 0:
		if monster.current_state != MonsterBase.MonsterState.PATROL:
			monster._change_state(MonsterBase.MonsterState.PATROL)
	else:
		if monster.current_state != MonsterBase.MonsterState.IDLE:
			monster._change_state(MonsterBase.MonsterState.IDLE)

func _aggressive_chase_decision() -> void:
	# 主动追击AI：总是尝试追击视野内的玩家
	if monster.target:
		if monster.current_state != MonsterBase.MonsterState.CHASE:
			monster._change_state(MonsterBase.MonsterState.CHASE)
	else:
		# 即使没有当前目标，也尝试寻找新目标
		if players_in_scene.size() > 0:
			_select_new_target()
		
		if not monster.target and monster.current_state != MonsterBase.MonsterState.PATROL:
			monster._change_state(MonsterBase.MonsterState.PATROL)

func _defensive_guard_decision() -> void:
	# 防御性守卫AI：只在目标进入攻击范围时才攻击
	if monster.target:
		var distance = monster.global_position.distance_to(monster.target.global_position)
		if distance <= monster.attack_range:
			if monster.current_state != MonsterBase.MonsterState.ATTACK:
				monster._change_state(MonsterBase.MonsterState.ATTACK)
		elif distance <= monster.chase_range:
			if monster.current_state != MonsterBase.MonsterState.CHASE:
				monster._change_state(MonsterBase.MonsterState.CHASE)
		else:
			monster.target = null
			if monster.current_state != MonsterBase.MonsterState.PATROL:
				monster._change_state(MonsterBase.MonsterState.PATROL)
	elif monster.current_state != MonsterBase.MonsterState.PATROL:
		monster._change_state(MonsterBase.MonsterState.PATROL)

func _ambush_decision() -> void:
	# 伏击AI：隐藏直到目标靠近，然后突然攻击
	if monster.target:
		var distance = monster.global_position.distance_to(monster.target.global_position)
		if distance <= monster.attack_range * 0.5:  # 更近才攻击
			if monster.current_state != MonsterBase.MonsterState.ATTACK:
				monster._change_state(MonsterBase.MonsterState.ATTACK)
		elif distance <= monster.sight_range * 0.7:
			if monster.current_state != MonsterBase.MonsterState.CHASE:
				monster._change_state(MonsterBase.MonsterState.CHASE)
	elif monster.current_state != MonsterBase.MonsterState.IDLE:
		# 伏击时保持空闲（隐藏）
		monster._change_state(MonsterBase.MonsterState.IDLE)

func _boss_decision() -> void:
	# BOSS AI：更复杂的行为模式，可能有多阶段
	if not monster.target:
		# BOSS可以主动寻找目标
		_select_new_target()
		return
	
	var distance = monster.global_position.distance_to(monster.target.global_position)
	
	# BOSS多阶段决策（示例）
	if monster.current_health > monster.base_health * 0.5:
		# 第一阶段：远程攻击为主
		if distance > monster.attack_range * 1.5:
			if monster.current_state != MonsterBase.MonsterState.CHASE:
				monster._change_state(MonsterBase.MonsterState.CHASE)
		else:
			if monster.current_state != MonsterBase.MonsterState.ATTACK:
				monster._change_state(MonsterBase.MonsterState.ATTACK)
	else:
		# 第二阶段：濒死时更激进
		if distance > monster.attack_range:
			if monster.current_state != MonsterBase.MonsterState.CHASE:
				monster._change_state(MonsterBase.MonsterState.CHASE)
			# 增加移动速度
			monster.move_speed = monster.move_speed * 1.2
		else:
			if monster.current_state != MonsterBase.MonsterState.ATTACK:
				monster._change_state(MonsterBase.MonsterState.ATTACK)
			# 增加攻击频率
			monster.attack_cooldown_timer = monster.attack_cooldown_timer * 0.8

## 设置AI行为
func set_ai_behavior(behavior: AIBehavior) -> void:
	ai_behavior = behavior
	# 重置决策
	players_in_scene.clear()
	detection_timer = detection_interval

## 获取当前检测到的玩家数量
func get_detected_player_count() -> int:
	return players_in_scene.size()

## 获取最近的玩家距离
func get_nearest_player_distance() -> float:
	var nearest = INF
	for player in players_in_scene:
		if is_instance_valid(player):
			var distance = monster.global_position.distance_to(player.global_position)
			if distance < nearest:
				nearest = distance
	return nearest if nearest != INF else -1.0

## 强制设置目标（忽略检测条件）
func force_set_target(target: Node2D) -> void:
	if target and is_instance_valid(target):
		monster.set_target(target)