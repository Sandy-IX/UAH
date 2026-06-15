extends Control

@onready var quit_button: Button = $VBoxContainer/quit_button

func _ready() -> void:
	quit_button.grab_focus()
	pass


func _on_quit_button_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.


func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Japan Route/Scenes/SeaSide/01.tscn")
	pass # Replace with function body.
