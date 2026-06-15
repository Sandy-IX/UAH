@tool
class_name LevelBounds
extends Node2D

@export_range(0, 1920*500, 32, "suffix:px") var width: int = 0 : 
	set(value):
		width = value
		queue_redraw()

@export_range(0, 1080*500, 32, "suffix:px") var height: int = 0 : 
	set(value):
		height = value
		queue_redraw()

func _ready() -> void:
	z_index = 256
	if Engine.is_editor_hint():
		return
		
	_set_camera_limits.call_deferred()

func _set_camera_limits() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	
	if camera and width > 0 and height > 0:
		var current_scene = get_tree().current_scene
		var target_position = global_position
		
		if current_scene and current_scene != get_parent():
			var spawn_point = current_scene.find_child("SpawnPoint", true, false)
			if spawn_point:
				target_position = spawn_point.global_position - Vector2(width / 2.0, height / 2.0)
			else:
				target_position = Vector2.ZERO

		camera.limit_left = int(target_position.x)
		camera.limit_top = int(target_position.y)
		camera.limit_right = int(target_position.x) + width
		camera.limit_bottom = int(target_position.y) + height
		
		camera.reset_smoothing() 

func _draw():
	if Engine.is_editor_hint():
		var r: Rect2 = Rect2(Vector2.ZERO, Vector2(width, height))
		draw_rect(r, Color.AQUA, false, 3)
