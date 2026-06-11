extends Node2D
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D


var cameraShakeNoise: FastNoiseLite
var camera_2d: Camera2D


var hp = 2
func _ready():
	camera_2d = get_node("../Player/Camera2D")
	cameraShakeNoise = FastNoiseLite.new()
	pass
func take_damage(amount):
	var tween = get_tree().create_tween()
	tween.tween_method(set_shader_blink_intensity,1.0,0.0,0.25)
	var camera_tween = get_tree().create_tween()
	camera_tween.tween_method(start_camera_shake,10.0,1.0,0.25)
	
	gpu_particles_2d.restart()
	gpu_particles_2d.emitting = true
	if hp > 0:
		hp -= amount
	else:
		destroy()
	pass
func destroy():
	var total_frames = sprite.sprite_frames.get_frame_count(sprite.animation)
	sprite.play("Destroy")
	if sprite.frame >= total_frames - 2:
		call_deferred("monitoring", false)
	
	await sprite.animation_finished
	queue_free()
func set_shader_blink_intensity(new_value:float):
	sprite.material.set_shader_parameter("blink_intensity",new_value)
	pass
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerSword") :
		take_damage(1)
		pass

func start_camera_shake(intensity: float):
	var camera_offset = cameraShakeNoise.get_noise_1d(Time.get_ticks_msec()) * intensity
	camera_2d.offset.x = camera_offset
	camera_2d.offset.y = camera_offset
