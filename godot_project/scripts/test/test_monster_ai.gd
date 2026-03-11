## 怪物AI测试脚本
## 验证怪物AI系统的基本功能
extends Node2D

# 测试怪物场景
@export var test_monster_scenes: Array[PackedScene] = []
# 玩家节点（用于测试目标检测）
@export var player_node: Node2D = null
# 测试区域大小
@export var test_area_size: Vector2 = Vector2(400, 300)

# 测试怪物实例
var test_monsters: Array[MonsterBase] = []
# 测试状态
enum TestState { IDLE, RUNNING, COMPLETE }
var current_test_state: TestState = TestState.IDLE
var test_start_time: float = 0.0
var test_duration: float = 30.0  # 测试持续时间（秒）

# UI元素
var debug_label: Label = null

func _ready() -> void:
	# 创建调试标签
	debug_label = Label.new()
	debug_label.position = Vector2(10, 10)
	debug_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(debug_label)
	
	# 如果没有设置玩家节点，尝试查找
	if not player_node:
		player_node = get_tree().get_first_node_in_group("player")
	
	print("怪物AI测试脚本已加载")
	print("可用测试怪物场景: %d" % test_monster_scenes.size())

func _process(delta: float) -> void:
	# 更新调试信息
	_update_debug_info()
	
	# 测试逻辑
	match current_test_state:
		TestState.IDLE:
			_process_idle(delta)
		TestState.RUNNING:
			_process_running(delta)
		TestState.COMPLETE:
			_process_complete(delta)

func _process_idle(delta: float) -> void:
	# 等待开始测试
	pass

func _process_running(delta: float) -> void:
	# 检查测试时间
	var elapsed = Time.get_ticks_msec() / 1000.0 - test_start_time
	if elapsed >= test_duration:
		_end_test()
		return
	
	# 测试过程中可以添加更多验证逻辑
	_validate_monster_states()

func _process_complete(delta: float) -> void:
	# 测试完成
	pass

func _update_debug_info() -> void:
	var text = "怪物AI测试\n"
	text += "测试状态: %s\n" % TestState.keys()[current_test_state]
	text += "测试怪物数量: %d\n" % test_monsters.size()
	
	# 显示每个怪物的状态
	for i in range(min(test_monsters.size(), 5)):
		var monster = test_monsters[i]
		if is_instance_valid(monster):
			text += "%d. %s: 生命%.0f/%.0f, 状态:%s\n" % [
				i + 1,
				monster.monster_name,
				monster.current_health,
				monster.base_health,
				MonsterBase.MonsterState.keys()[monster.current_state]
			]
	
	if test_monsters.size() > 5:
		text += "... 还有 %d 个怪物\n" % (test_monsters.size() - 5)
	
	debug_label.text = text

func start_test() -> void:
	if current_test_state != TestState.IDLE:
		print("测试已在运行或已完成")
		return
	
	print("开始怪物AI测试")
	current_test_state = TestState.RUNNING
	test_start_time = Time.get_ticks_msec() / 1000.0
	
	# 生成测试怪物
	_spawn_test_monsters()

func _spawn_test_monsters() -> void:
	# 清空现有怪物
	_clear_test_monsters()
	
	# 生成新怪物
	for i in range(test_monster_scenes.size()):
		if i >= 3:  # 最多生成3个
			break
		
		var scene = test_monster_scenes[i]
		if not scene:
			continue
		
		var monster = scene.instantiate() as MonsterBase
		if not monster:
			push_error("无法实例化测试怪物场景 %d" % i)
			continue
		
		# 随机位置
		var x = randf_range(50, test_area_size.x - 50)
		var y = randf_range(50, test_area_size.y - 50)
		monster.position = Vector2(x, y)
		
		add_child(monster)
		test_monsters.append(monster)
		
		# 为怪物设置玩家为目标（如果存在）
		if player_node:
			monster.set_target(player_node)
		
		print("生成测试怪物: %s 在位置 %s" % [monster.monster_name, monster.position])

func _clear_test_monsters() -> void:
	for monster in test_monsters:
		if is_instance_valid(monster):
			monster.queue_free()
	
	test_monsters.clear()

func _validate_monster_states() -> void:
	# 验证怪物状态是否有效
	var valid_count = 0
	
	for monster in test_monsters:
		if not is_instance_valid(monster):
			continue
		
		# 检查生命值是否在合理范围
		if monster.current_health < 0 or monster.current_health > monster.base_health * 1.5:
			push_warning("怪物 %s 生命值异常: %.1f" % [monster.monster_name, monster.current_health])
		
		# 检查状态是否有效
		if monster.current_state < 0 or monster.current_state >= MonsterBase.MonsterState.size():
			push_warning("怪物 %s 状态异常: %d" % [monster.monster_name, monster.current_state])
		
		valid_count += 1
	
	# 如果有怪物死亡，可以从测试中移除
	test_monsters = test_monsters.filter(func(m): return is_instance_valid(m) and m.current_state != MonsterBase.MonsterState.DEAD)

func _end_test() -> void:
	print("怪物AI测试结束")
	current_test_state = TestState.COMPLETE
	
	# 统计结果
	var alive_count = test_monsters.size()
	print("测试结果: %d 个怪物存活" % alive_count)
	
	# 清理怪物
	_clear_test_monsters()

## 手动伤害测试
func test_damage(monster_index: int = 0) -> void:
	if test_monsters.size() <= monster_index:
		print("没有足够的怪物进行伤害测试")
		return
	
	var monster = test_monsters[monster_index]
	if not is_instance_valid(monster):
		print("怪物无效")
		return
	
	# 对怪物造成伤害
	var damage = monster.base_health * 0.3
	monster.take_damage(damage, player_node)
	
	print("对 %s 造成 %.1f 伤害, 剩余生命: %.1f" % [
		monster.monster_name, damage, monster.current_health
	])

## 切换测试怪物目标
func toggle_target(monster_index: int = 0) -> void:
	if test_monsters.size() <= monster_index:
		return
	
	var monster = test_monsters[monster_index]
	if not is_instance_valid(monster):
		return
	
	if monster.target:
		monster.target = null
		print("清除了 %s 的目标" % monster.monster_name)
	elif player_node:
		monster.set_target(player_node)
		print("设置了 %s 的目标为玩家" % monster.monster_name)

# 输入处理
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				start_test()
			KEY_F2:
				test_damage(0)
			KEY_F3:
				toggle_target(0)
			KEY_F4:
				_clear_test_monsters()
				print("清理了所有测试怪物")