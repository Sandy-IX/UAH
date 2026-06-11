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
		
	# Instead of looping and waiting, grab the active camera directly 
	# after the scene tree finishes organizing itself on frame 1.
	_set_camera_limits.call_deferred()

func _set_camera_limits() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	
	if camera and width > 0 and height > 0:
		camera.limit_left = int(global_position.x)
		camera.limit_top = int(global_position.y)
		camera.limit_right = int(global_position.x) + width
		camera.limit_bottom = int(global_position.y) + height
		
		# Optional: Force the camera to respect the new limits immediately
		camera.reset_smoothing() 

func _draw():
	if Engine.is_editor_hint():
		var r: Rect2 = Rect2(Vector2.ZERO, Vector2(width, height))
		draw_rect(r, Color.AQUA, false, 3)
