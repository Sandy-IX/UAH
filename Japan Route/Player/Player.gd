extends CharacterBody2D
class_name Player

#region Stats
enum STATES {idle, walk, normal_attack, parry, jump, fall, dash, kanji_sequence, hurt, death}
var stance: Node2D = basic_stance
@export var knock_back_strength: float = 140
var amount = 2
#endregion

#region Onready Variables
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_right_b: Area2D = $Sword/BasicStance/RightSide/SwordRightB
@onready var sword_right_collider_b: CollisionShape2D = $Sword/BasicStance/RightSide/SwordRightB/SwordRightColliderB
@onready var sword_left_b: Area2D = $Sword/BasicStance/LeftSide/SwordLeftB
@onready var sword_left_collider_b: CollisionShape2D = $Sword/BasicStance/LeftSide/SwordLeftB/SwordLeftColliderB
@onready var kanji_sytem_overlay: CanvasLayer = $"../KanjiSytemOverlay"
@onready var player_damage_area: Area2D = $Player_Damage_Area
@onready var basic_stance: Node2D = $Sword/BasicStance
@onready var storm_stance: Node2D = $"Sword/Storm Stance"
@onready var stats: StatsManager = $PlayerStatManager
@onready var sword_right_s: Area2D = $"Sword/Storm Stance/RightSide/SwordRightS"
@onready var sword_right_collider_s: CollisionShape2D = $"Sword/Storm Stance/RightSide/SwordRightS/SwordRightColliderS"
@onready var sword_left_s: Area2D = $"Sword/Storm Stance/LeftSide/SwordLeftS"
@onready var sword_left_collider_s: CollisionShape2D = $"Sword/Storm Stance/LeftSide/SwordLeftS/SwordLeftColliderS"

#endregion

#region Constants (Calibrated for 1080p)
const JUMP_VELOCITY = -1650.0
const DECELERATION = 18000.0
const kb_decel = 7000.0
const jump_gravity = 3200.0
const fall_gravity_multiplier = 1.35
const max_coyote_time = 0.12
const max_input_buffer = 0.12
const jump_cut_off = 8.0
const DASH_SPEED = 1600.0
const DASH_DURATION = 0.18
const dash_cooldown = 1.25
var knockback_duration = 120.0
#endregion

#region timers
var coyote_timer = 0.0
var input_buffer_timer = 0.0
var dash_timer = 0.0    
var dash_cooldown_timer = 0.0
var knockback_timer = 0.0
#endregion

#region conditions
var current_state = STATES.idle
var old_direction: float = 1.0 
var can_dash = true
var attack_counter = 1
var just_collided = false

@onready var main_collider = sword_right_collider_b
@onready var not_main_collider = sword_left_collider_b
@onready var current_stance = basic_stance
#endregion

func _ready() -> void:
	if get_tree().get_first_node_in_group("Player") != self:
		self.queue_free()
	if kanji_sytem_overlay:
		kanji_sytem_overlay.kanji_state_changed.connect(_on_kanji_toggled)
		
	# Connect our new stats system manager to handle death securely
	stats.no_hp.connect(die)
	stance = basic_stance
	sword_right_collider_b.disabled = true
	sword_left_collider_b.disabled = true
	sword_right_collider_s.disabled = true
	sword_left_collider_s.disabled = true
	
	self.call_deferred("reparent",get_tree().root)

func _physics_process(delta: float) -> void:
	if is_on_floor():
		coyote_timer = max_coyote_time
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("Jump"):
		input_buffer_timer = max_input_buffer
	else:
		input_buffer_timer -= delta

	if Input.is_action_just_released("Jump") and velocity.y < 0:
		velocity.y += jump_gravity * jump_cut_off * delta
	if Input.is_action_pressed("Crouch"):
		set_collision_mask_value(9,false)
	else:
		set_collision_mask_value(9,true)
		
	if kanji_sytem_overlay and kanji_sytem_overlay.visible:
		velocity = Vector2.ZERO
		current_state = STATES.kanji_sequence
		sprite.play("idle") 
		return 

	if current_state == STATES.kanji_sequence:
		current_state = STATES.idle
		
	if not is_on_floor() and current_state != STATES.dash and current_state != STATES.normal_attack and current_state != STATES.hurt:
		if velocity.y < 0:
			velocity.y += jump_gravity * delta
		else:
			velocity.y += (jump_gravity * fall_gravity_multiplier) * delta
			current_state = STATES.fall
	
	if not can_dash:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0.0:
			can_dash = true
			
	if current_state != STATES.dash:
		if just_collided:
			knockback_timer -= delta
			if knockback_timer <= 0.0:
				velocity.x = move_toward(velocity.x, 0, 50000 * delta)
				if velocity.x == 0:
					knockback_timer = 0.0
					
		if not just_collided:
			knockback_timer -= delta
			if knockback_timer <= 0.0:
				velocity.x = move_toward(velocity.x, 0, kb_decel * delta)
				if velocity.x == 0:
					knockback_timer = 0.0
				
	var direction := Input.get_axis("Left", "Right")
	handle_direction(direction)
	
	if Input.is_action_just_pressed("Dash") and current_state != STATES.dash and current_state != STATES.normal_attack and current_state != STATES.hurt and can_dash:
		var dash_dir = direction if direction != 0 else old_direction
		start_dash(dash_dir)

	if current_state == STATES.dash:
		dash_timer -= delta
		if dash_timer <= 0.0:
			current_state = STATES.idle if is_on_floor() else STATES.fall
	elif current_state == STATES.normal_attack or current_state == STATES.hurt:
		pass
	else:
		if is_on_floor():
			if input_buffer_timer > 0.0: 
				current_state = STATES.jump
				velocity.y = JUMP_VELOCITY
				input_buffer_timer = 0.0
				coyote_timer = 0.0
			elif direction != 0:
				current_state = STATES.walk
			else:
				current_state = STATES.idle
		else:
			if input_buffer_timer > 0.0 and coyote_timer > 0.0:
				current_state = STATES.jump
				velocity.y = JUMP_VELOCITY
				input_buffer_timer = 0.0
				coyote_timer = 0.0

	if current_state != STATES.death:
		if current_state == STATES.idle:
			handle_idle(delta) 
		elif current_state == STATES.jump:
			handle_jump(direction)
		elif current_state == STATES.walk:
			handle_walk(delta, direction)
		elif current_state == STATES.fall:
			handle_fall(delta, direction) 
		elif current_state == STATES.dash:
			handle_dash()
		elif current_state == STATES.normal_attack:
			handle_attack(delta)
		elif current_state == STATES.hurt:
			velocity.x = move_toward(velocity.x, 0, delta * DECELERATION)
			if not is_on_floor():
				velocity.y += jump_gravity * delta

	move_and_slide()

func _process(_delta: float) -> void:
	if current_state == STATES.death:
		change_scene()

func _unhandled_input(event: InputEvent) -> void:
	if current_state == STATES.hurt or current_state == STATES.death:
		return
		
	if event.is_action_pressed("Attack") and current_state != STATES.dash and current_state != STATES.normal_attack:
		start_attack()
	if event.is_action_pressed("storm_kanji_toggle"):
		if kanji_sytem_overlay and kanji_sytem_overlay.can_use_kanji:
			kanji_sytem_overlay.visible = !kanji_sytem_overlay.visible

#region states
func handle_direction(direction):
	if (current_state == STATES.normal_attack and direction == 0) or current_state == STATES.hurt:
		return
		
	if direction != 0:
		old_direction = direction
		if direction > 0:
			sprite.flip_h = false
			if stance == basic_stance:
				not_main_collider = sword_left_collider_b
				main_collider = sword_right_collider_b
			elif stance == storm_stance:
				main_collider = sword_right_collider_s
		elif direction < 0:
			sprite.flip_h = true
			if stance == basic_stance:
				main_collider = sword_left_collider_b
				not_main_collider = sword_right_collider_b
			elif stance == storm_stance:
				main_collider = sword_left_collider_s
		not_main_collider.disabled = true

func handle_idle(delta: float):
	sprite.play("idle")
	velocity.x = move_toward(velocity.x, 0, delta * DECELERATION)

func handle_fall(delta: float, direction: float):
	sprite.play("fall")
	if direction != 0:
		velocity.x = direction * stats.speed.get_value()
	else:
		velocity.x = move_toward(velocity.x, 0, delta * DECELERATION)
	
func handle_walk(delta: float, direction: float):
	sprite.play("walk")
	if direction != 0:
		velocity.x = direction * stats.speed.get_value()
	else:
		velocity.x = move_toward(velocity.x, 0, delta * DECELERATION)
	
func handle_jump(direction: float):
	sprite.play("jump")
	if direction != 0:
		velocity.x = direction * stats.speed.get_value()
	else:
		velocity.x = move_toward(velocity.x, 0, get_process_delta_time() * DECELERATION)

func start_dash(dash_dir: float):
	sprite.play("dash")
	current_state = STATES.dash
	dash_timer = DASH_DURATION
	dash_cooldown_timer = dash_cooldown
	velocity.y = 0.0 
	velocity.x = dash_dir * DASH_SPEED
	can_dash = false

func handle_dash():
	sprite.play("dash")

func start_attack():
	current_state = STATES.normal_attack
	main_collider.disabled = false
	just_collided = false 
	
	if attack_counter == 1:
		sprite.play("attack1")
	elif attack_counter == 2:
		sprite.play("attack2")
	elif attack_counter == 3:
		sprite.play("attack3")

func handle_attack(delta: float):
	var total_frames = sprite.sprite_frames.get_frame_count(sprite.animation)
	if sprite.frame >= total_frames - 2:
		main_collider.disabled = true

	if is_on_floor():
		if not just_collided:
			velocity.x = old_direction * knockback_duration
		else:
			if abs(velocity.x) < 50:
				velocity.x = -old_direction * (knock_back_strength / 0.67)
	if not is_on_floor():
		velocity.y +=  jump_gravity * delta
		velocity.x = old_direction * (knockback_duration * 0.75)
		
func take_damage(Amount: int):
	if current_state == STATES.death:
		return
		
	# Let our manager mutate the dynamic HP pool boundaries safely
	stats.take_damage(Amount)
	print("HP Remaining: ", stats.current_hp)
	
	# If health drops to zero, the stats.no_hp signal automatically fires 'die()' 
	if stats.current_hp > 0:
		current_state = STATES.hurt
		sprite.play("hurt")

func die():
	set_physics_process(false)
	sprite.play("death")
	await sprite.animation_finished
	if player_damage_area:
		player_damage_area.set_deferred("monitoring", false)
		player_damage_area.set_deferred("monitorable", false)
	current_state = STATES.death

func change_scene():
	print("reloading scene")
	if get_tree():
		get_tree().change_scene_to_file("res://Japan Route/Scenes/Interaction Scenes/DeathScene.tscn")
		queue_free()
	pass
#endregion

#region kanji system
func _on_kanji_toggled(is_active: bool) -> void:
	if is_active:
		Engine.time_scale = 0.25
		current_state = STATES.kanji_sequence 
	else:
		Engine.time_scale = 1.0
		current_state = STATES.idle
		_on_kanji_success_stance_change()

func _on_kanji_success_stance_change() -> void:
	change_stance()
	print("Stance Changed")
func change_stance():
	if stance != storm_stance:
		stance = storm_stance
		sword_left_collider_b.disabled = true
		sword_right_collider_b.disabled = true
	
	
#endregion

#region signal functions
func _on_animated_sprite_2d_animation_finished() -> void:
	if current_state == STATES.normal_attack:
		main_collider.disabled = true
		attack_counter += 1
		if attack_counter > 3:
			attack_counter = 1
		current_state = STATES.idle if is_on_floor() else STATES.fall
		
	elif current_state == STATES.hurt:
		current_state = STATES.idle if is_on_floor() else STATES.fall

func _on_sword_right_body_entered(body: Node2D) -> void:
	if body.is_in_group("BreakableObjects"):
		just_collided = true
		
func _on_sword_left_body_entered(body: Node2D) -> void:
	if body.is_in_group("BreakableObjects"):
		just_collided = true

func _on_player_damage_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("EnemyDamage") and current_state != STATES.hurt and current_state != STATES.death:
		take_damage(amount)
		print("detected")
#endregion
