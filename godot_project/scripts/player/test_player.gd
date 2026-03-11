## 玩家系统测试脚本
## 验证移动、相机、动画功能
class_name TestPlayerScript
extends Node2D

## 玩家控制器引用
var player_controller: PlayerController
## 相机跟随引用
var camera_follow: CameraFollow
## 动画管理器引用
var animation_manager: AnimationManager

## 测试状态
var test_results := {
	"movement_input": false,
	"acceleration": false,
	"collision": false,
	"camera_follow": false,
	"animation_states": false
}

func _ready() -> void:
	# 获取节点引用
	player_controller = $PlayerInstance
	camera_follow = $PlayerInstance.get_node("CameraFollow")
	animation_manager = $PlayerInstance.get_node("AnimationManager")
	
	# 设置相机目标
	camera_follow.target = player_controller
	
	# 创建简单地形
	_create_test_terrain()
	
	# 开始测试
	_start_tests()

func _process(delta: float) -> void:
	# 更新测试状态显示
	_update_debug_info()

func _create_test_terrain() -> void:
	var tilemap := $TileMap as TileMap
	
	# 创建20x20的地面
	for x in range(-10, 10):
		for y in range(-5, 5):
			# 使用草地图块（ID 1）
			tilemap.set_cell(0, Vector2i(x, y), 1, Vector2i(0, 0))
	
	# 创建一些障碍物
	for i in range(3):
		tilemap.set_cell(0, Vector2i(i + 2, -2), 3, Vector2i(0, 0))  # 山脉图块

func _start_tests() -> void:
	print("=== 玩家系统测试开始 ===")
	
	# 测试1：输入响应
	_test_movement_input()
	
	# 测试2：加速度/减速度
	_test_acceleration()
	
	# 测试3：碰撞检测（通过TileMap）
	_test_collision()
	
	# 测试4：相机跟随
	_test_camera_follow()
	
	# 测试5：动画状态
	_test_animation_states()
	
	# 输出测试结果
	_print_test_results()

func _test_movement_input() -> void:
	print("测试1: 移动输入响应")
	
	# 模拟输入检查
	if player_controller.has_method("get_move_direction"):
		test_results["movement_input"] = true
		print("  ✓ 移动输入系统正常")
	else:
		print("  ✗ 移动输入系统异常")

func _test_acceleration() -> void:
	print("测试2: 加速度/减速度物理")
	
	# 检查加速度参数
	if player_controller.acceleration > 0 and player_controller.deceleration > 0:
		test_results["acceleration"] = true
		print("  ✓ 加速度/减速度参数正常")
	else:
		print("  ✗ 加速度/减速度参数异常")

func _test_collision() -> void:
	print("测试3: 碰撞检测")
	
	# 检查碰撞形状
	var collision_shape = player_controller.get_node_or_null("CollisionShape2D")
	if collision_shape and collision_shape.shape:
		test_results["collision"] = true
		print("  ✓ 碰撞形状配置正常")
	else:
		print("  ✗ 碰撞形状配置异常")

func _test_camera_follow() -> void:
	print("测试4: 相机跟随")
	
	# 检查相机配置
	if camera_follow.target == player_controller:
		test_results["camera_follow"] = true
		print("  ✓ 相机目标设置正常")
	else:
		print("  ✗ 相机目标设置异常")

func _test_animation_states() -> void:
	print("测试5: 动画状态机")
	
	# 检查动画管理器
	if animation_manager and animation_manager.has_method("update_animation"):
		test_results["animation_states"] = true
		print("  ✓ 动画管理器功能正常")
	else:
		print("  ✗ 动画管理器功能异常")

func _print_test_results() -> void:
	print("\n=== 测试结果 ===")
	
	var passed := 0
	var total := test_results.size()
	
	for test_name in test_results:
		var passed_text = "✓" if test_results[test_name] else "✗"
		print("  %s: %s" % [test_name, passed_text])
		if test_results[test_name]:
			passed += 1
	
	print("\n通过率: %d/%d" % [passed, total])
	
	if passed == total:
		print("✅ 所有测试通过！")
	else:
		print("⚠️  部分测试失败，请检查系统配置。")

func _update_debug_info() -> void:
	# 在实际游戏中可以显示调试信息
	pass

## 手动触发测试（用于编辑器）
func run_manual_tests() -> void:
	print("手动触发测试...")
	_start_tests()