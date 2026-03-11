## 相机跟随脚本
## 实现平滑跟随玩家，支持边界约束和可配置参数
class_name CameraFollow
extends Camera2D

## 跟随的目标节点
@export var target: Node2D
## 跟随延迟（秒），值越大越平滑，0为即时跟随
@export var follow_smoothness: float = 0.2
## 是否启用边界约束
@export var enable_bounds: bool = true
## 地图边界（左上角坐标）
@export var map_bound_min: Vector2 = Vector2.ZERO
## 地图边界（右下角坐标）
@export var map_bound_max: Vector2 = Vector2(1024, 1024)
## 边缘缓冲（像素），相机保持在距离边界多少像素内
@export var edge_buffer: float = 50.0

## 当前速度，用于平滑跟随
var current_velocity: Vector2 = Vector2.ZERO
## 相机实际边界（考虑视口大小）
var camera_bounds: Rect2

func _ready() -> void:
	# 如果没有指定目标，尝试查找玩家节点
	if not target:
		target = get_parent()
		if not target or not target is Node2D:
			push_warning("CameraFollow: No valid target found. Please assign a target Node2D.")
	
	# 计算相机边界
	_update_camera_bounds()
	
	# 确保相机不超出边界
	if enable_bounds:
		force_update_scroll()
		position = _clamp_position(target.global_position)

func _process(delta: float) -> void:
	if not target:
		return
	
	# 计算目标位置
	var target_position := target.global_position
	
	# 应用边界约束
	if enable_bounds:
		target_position = _clamp_position(target_position)
	
	# 使用平滑阻尼进行跟随
	global_position = global_position.smooth_damp(target_position, follow_smoothness, delta)
	
	# 更新相机边界（如果视口大小变化）
	_update_camera_bounds()

## 更新相机边界（基于视口大小）
func _update_camera_bounds() -> void:
	var viewport_size := get_viewport_rect().size
	var half_size := viewport_size * 0.5 / zoom
	
	camera_bounds = Rect2(
		map_bound_min.x + half_size.x + edge_buffer,
		map_bound_min.y + half_size.y + edge_buffer,
		map_bound_max.x - map_bound_min.x - 2 * half_size.x - 2 * edge_buffer,
		map_bound_max.y - map_bound_min.y - 2 * half_size.y - 2 * edge_buffer
	)
	
	# 确保边界有效
	if camera_bounds.size.x < 0:
		camera_bounds.size.x = 0
	if camera_bounds.size.y < 0:
		camera_bounds.size.y = 0

## 钳制位置到边界内
func _clamp_position(position: Vector2) -> Vector2:
	if not enable_bounds or camera_bounds.size.x <= 0 or camera_bounds.size.y <= 0:
		return position
	
	return Vector2(
		clamp(position.x, camera_bounds.position.x, camera_bounds.position.x + camera_bounds.size.x),
		clamp(position.y, camera_bounds.position.y, camera_bounds.position.y + camera_bounds.size.y)
	)

## 设置地图边界
func set_map_bounds(min_pos: Vector2, max_pos: Vector2) -> void:
	map_bound_min = min_pos
	map_bound_max = max_pos
	_update_camera_bounds()

## 启用/禁用边界约束
func set_bounds_enabled(enabled: bool) -> void:
	enable_bounds = enabled

## 设置跟随目标
func set_target(new_target: Node2D) -> void:
	target = new_target

## 获取当前边界（用于调试）
func get_camera_bounds() -> Rect2:
	return camera_bounds

## 立即跳转到目标位置（无平滑）
func snap_to_target() -> void:
	if target:
		global_position = _clamp_position(target.global_position)