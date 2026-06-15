extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SceneManager.new_scene_ready.connect(on_scene_transition)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func on_scene_transition(_t,_o ) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	pass
