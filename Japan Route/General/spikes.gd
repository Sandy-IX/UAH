extends Area2D

@export var amount : int


func _on_body_entered(body: Node2D) -> void:
	body.take_damage(amount)
	print(body.name)
	pass # Replace with function body.
