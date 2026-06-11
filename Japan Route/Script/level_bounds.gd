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
		
	var camera: Camera2D = null
	while not camera:
		await get_tree().process_frame
		camera = get_viewport().get_camera_2d()
	
	# Wait one more frame for the camera to successfully position itself 
	# over the player before locking down the borders.
	await get_tree().process_frame

	# Prevent a 0-width limit from snapping the camera to the corner
	if width > 0 and height > 0:
		camera.limit_left = int(global_position.x)
		camera.limit_top = int(global_position.y)
		camera.limit_right = int(global_position.x) + width
		camera.limit_bottom = int(global_position.y) + height
func _draw():
	if Engine.is_editor_hint():
		var r: Rect2 = Rect2(Vector2.ZERO, Vector2(width, height))
		draw_rect(r, Color.AQUA, false, 3)
