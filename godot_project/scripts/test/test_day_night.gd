## 昼夜循环系统测试脚本
## 验证核心功能：时间流逝、阶段切换、环境光渐变、怪物强化、撤离计时
extends Node

# 节点引用
@onready var time_manager = get_node("/root/TimeManager") as TimeManager
@onready var day_night_cycle = get_node("/root/DayNightCycle") as DayNightCycle
@onready var monster_boost_system = get_node("/root/MonsterNightBoostSystem") as MonsterNightBoostSystem
@onready var port_timer = get_node("/root/PortEvacuationTimer") as PortEvacuationTimer

# 测试状态
var tests_passed = 0
var tests_total = 0
var test_start_time = 0.0

func _ready() -> void:
	print("=== 昼夜循环系统测试开始 ===")
	
	# 等待一帧确保节点初始化
	await get_tree().process_frame
	
	# 开始测试
	run_all_tests()

func run_all_tests() -> void:
	test_time_manager()
	test_day_night_cycle()
	test_monster_boost_system()
	test_port_evacuation_timer()
	
	print("\n=== 测试总结 ===")
	print("通过测试: %d/%d" % [tests_passed, tests_total])
	
	if tests_passed == tests_total:
		print("✅ 所有测试通过！")
	else:
		print("❌ 部分测试失败！")

# 测试辅助函数
func assert_equal(actual, expected, test_name: String) -> bool:
	tests_total += 1
	if actual == expected:
		print("✅ %s: 通过 (期望: %s, 实际: %s)" % [test_name, str(expected), str(actual)])
		tests_passed += 1
		return true
	else:
		print("❌ %s: 失败 (期望: %s, 实际: %s)" % [test_name, str(expected), str(actual)])
		return false

func assert_true(condition: bool, test_name: String) -> bool:
	return assert_equal(condition, true, test_name)

func assert_false(condition: bool, test_name: String) -> bool:
	return assert_equal(condition, false, test_name)

# 测试1：TimeManager 基础功能
func test_time_manager() -> void:
	print("\n--- 测试1：TimeManager 基础功能 ---")
	
	# 1.1 验证初始时间设置
	var initial_time = time_manager.get_game_time()
	assert_equal(initial_time.hour, time_manager.start_hour, "初始小时设置正确")
	assert_equal(initial_time.minute, time_manager.start_minute, "初始分钟设置正确")
	
	# 1.2 验证手动时间设置
	time_manager.set_game_time(14, 30, 15)
	var set_time = time_manager.get_game_time()
	assert_equal(set_time.hour, 14, "设置小时正确")
	assert_equal(set_time.minute, 30, "设置分钟正确")
	
	# 1.3 验证阶段判断
	var phase1 = time_manager.get_phase_for_hour(5)   # 黎明
	var phase2 = time_manager.get_phase_for_hour(10)  # 白天
	var phase3 = time_manager.get_phase_for_hour(19)  # 黄昏
	var phase4 = time_manager.get_phase_for_hour(22)  # 夜晚
	assert_equal(phase1, TimeManager.DayPhase.DAWN, "小时5属于黎明阶段")
	assert_equal(phase2, TimeManager.DayPhase.DAY, "小时10属于白天阶段")
	assert_equal(phase3, TimeManager.DayPhase.DUSK, "小时19属于黄昏阶段")
	assert_equal(phase4, TimeManager.DayPhase.NIGHT, "小时22属于夜晚阶段")
	
	# 1.4 验证阶段切换信号
	var signal_received = false
	var test_callback = func(new_phase, prev_phase):
		signal_received = true
		print("信号接收：阶段从 %s 切换到 %s" % [
			time_manager.get_phase_name(prev_phase),
			time_manager.get_phase_name(new_phase)
		])
	
	time_manager.day_phase_changed.connect(test_callback)
	
	# 触发阶段变化（从14:30切换到夜晚20:00）
	time_manager.set_game_time(20, 0, 0)
	
	# 等待一帧确保信号处理
	await get_tree().process_frame
	
	# 断开连接避免影响后续测试
	time_manager.day_phase_changed.disconnect(test_callback)
	
	assert_true(signal_received, "阶段变化信号正常触发")

# 测试2：DayNightCycle 环境光变化
func test_day_night_cycle() -> void:
	print("\n--- 测试2：DayNightCycle 环境光变化 ---")
	
	# 2.1 验证节点引用
	assert_true(day_night_cycle != null, "DayNightCycle节点存在")
	assert_true(day_night_cycle.canvas_modulate_path != NodePath(), "CanvasModulate路径已配置")
	
	# 2.2 验证颜色配置
	assert_true(day_night_cycle.dawn_color is Color, "黎明颜色配置正确")
	assert_true(day_night_cycle.day_color is Color, "白天颜色配置正确")
	assert_true(day_night_cycle.dusk_color is Color, "黄昏颜色配置正确")
	assert_true(day_night_cycle.night_color is Color, "夜晚颜色配置正确")
	
	# 2.3 验证颜色切换（通过时间管理器触发）
	print("正在测试环境光切换...")
	
	# 记录当前颜色
	var initial_color = day_night_cycle.get_current_color()
	
	# 切换到夜晚阶段
	time_manager.set_game_time(21, 0, 0)
	await get_tree().process_frame
	
	# 等待过渡完成（如果启用平滑过渡）
	if day_night_cycle.smooth_transition:
		await get_tree().create_timer(day_night_cycle.transition_duration + 0.1).timeout
	
	var night_color = day_night_cycle.get_current_color()
	
	# 验证颜色已变化（不完全相等，因为可能有亮度系数）
	assert_true(initial_color != night_color, "环境光颜色随阶段变化")
	
	# 切换回白天验证恢复
	time_manager.set_game_time(10, 0, 0)
	await get_tree().process_frame
	
	if day_night_cycle.smooth_transition:
		await get_tree().create_timer(day_night_cycle.transition_duration + 0.1).timeout
	
	var day_color = day_night_cycle.get_current_color()
	assert_true(day_color.r > 0.9, "白天颜色亮度较高")

# 测试3：MonsterNightBoostSystem 怪物强化
func test_monster_boost_system() -> void:
	print("\n--- 测试3：MonsterNightBoostSystem 怪物强化 ---")
	
	# 3.1 验证系统启用状态
	assert_true(monster_boost_system.enabled, "怪物强化系统已启用")
	
	# 3.2 创建测试怪物
	var test_monster = Node.new()
	test_monster.name = "TestMonster"
	test_monster.add_to_group(monster_boost_system.monster_group_name)
	
	# 定义基础属性
	var base_attack = 10.0
	var base_speed = 100.0
	var base_chase_range = 50.0
	var base_sight_range = 80.0
	
	# 注册怪物
	monster_boost_system.register_monster(
		test_monster,
		base_attack,
		base_speed,
		base_chase_range,
		base_sight_range
	)
	
	# 3.3 测试夜晚强化激活
	# 切换到夜晚阶段
	time_manager.set_game_time(22, 0, 0)
	await get_tree().process_frame
	
	assert_true(monster_boost_system.is_night_boost_active(), "夜晚阶段强化激活")
	assert_equal(monster_boost_system.get_current_boost_multiplier(), 1.0, "夜晚阶段完全强化")
	
	# 3.4 测试黄昏渐进强化（如果启用）
	if monster_boost_system.progressive_enhancement:
		time_manager.set_game_time(19, 0, 0)
		await get_tree().process_frame
		
		assert_true(monster_boost_system.is_night_boost_active(), "黄昏阶段部分强化激活")
		assert_equal(monster_boost_system.get_current_boost_multiplier(), 
					monster_boost_system.dusk_enhancement_ratio, 
					"黄昏阶段强化倍率正确")
	
	# 3.5 测试白天无强化
	time_manager.set_game_time(12, 0, 0)
	await get_tree().process_frame
	
	assert_false(monster_boost_system.is_night_boost_active(), "白天阶段无强化")
	
	# 清理测试怪物
	monster_boost_system.unregister_monster(test_monster)
	test_monster.queue_free()

# 测试4：PortEvacuationTimer 撤离计时
func test_port_evacuation_timer() -> void:
	print("\n--- 测试4：PortEvacuationTimer 撤离计时 ---")
	
	# 4.1 验证系统启用状态
	assert_true(port_timer.enabled, "撤离计时器已启用")
	
	# 4.2 测试不同阶段的状态
	# 白天（安全阶段）
	time_manager.set_game_time(10, 0, 0)
	await get_tree().process_frame
	assert_false(port_timer.is_warning_active(), "白天无撤离警告")
	assert_false(port_timer.is_emergency_active(), "白天无紧急撤离")
	
	# 黄昏（警告阶段）
	time_manager.set_game_time(18, 30, 0)
	await get_tree().process_frame
	assert_true(port_timer.is_warning_active(), "黄昏撤离警告激活")
	assert_false(port_timer.is_emergency_active(), "黄昏无紧急撤离")
	
	# 计算剩余秒数验证
	var seconds_until_night = port_timer.get_seconds_until_night()
	assert_true(seconds_until_night > 0 and seconds_until_night < 2 * 3600, 
				"黄昏剩余时间计算正确（0-2小时）")
	
	# 夜晚（紧急阶段）
	time_manager.set_game_time(22, 0, 0)
	await get_tree().process_frame
	assert_false(port_timer.is_warning_active(), "夜晚撤离警告结束")
	assert_true(port_timer.is_emergency_active(), "夜晚紧急撤离激活")
	
	# 4.3 测试港口区域检测（模拟）
	print("正在模拟港口区域检测...")
	
	# 创建测试港口区域
	var test_port_area = Area2D.new()
	test_port_area.name = "TestPortArea"
	
	# 设置港口区域
	port_timer.set_port_area(test_port_area)
	
	# 注意：实际玩家进入检测需要真实的物理交互，这里仅验证接口可用性
	assert_true(port_timer.get_port_area() != null, "港口区域设置成功")
	
	# 清理
	test_port_area.queue_free()

func _process(delta: float) -> void:
	# 可选：在测试期间显示当前时间
	pass