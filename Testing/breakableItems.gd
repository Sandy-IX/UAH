extends Node2D

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var area_2d: Area2D = $Area2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D

var cameraShakeNoise: FastNoiseLite
var camera_2d: Camera2D

var hp = 2

func _ready():
	camera_2d = get_tree().get_first_node_in_group("PlayerCamera") if get_tree().get_nodes_in_group("PlayerCamera").size() > 0 else get_node_or_null("../Player/Camera2D")
	cameraShakeNoise = FastNoiseLite.new()

func take_damage(amount):
	if hp <= 0:
		return
		
	hp -= amount
	
	var tween = get_tree().create_tween()
	tween.tween_method(set_shader_blink_intensity, 1.0, 0.0, 0.25)
	
	var camera_tween = get_tree().create_tween()
	camera_tween.tween_method(start_camera_shake, 10.0, 0.0, 0.25)
	
	gpu_particles_2d.restart()
	gpu_particles_2d.emitting = true
	
	if hp <= 0:
		destroy()

func destroy():
	GlobalSignalManager.breakable_destroyed.emit(self)
	
	area_2d.set_deferred("monitoring", false)
	area_2d.set_deferred("monitorable", false)
	
	sprite.play("Destroy")
	await sprite.animation_finished
	queue_free()

func set_shader_blink_intensity(new_value: float):
	if sprite.material:
		sprite.material.set_shader_parameter("blink_intensity", new_value)

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerSword"):
		take_damage(1)

func start_camera_shake(intensity: float):
	if is_instance_valid(camera_2d):
		var time_ms = Time.get_ticks_msec()
		camera_2d.offset.x = cameraShakeNoise.get_noise_2d(time_ms, 0.0) * intensity
		camera_2d.offset.y = cameraShakeNoise.get_noise_2d(0.0, time_ms) * intensity
