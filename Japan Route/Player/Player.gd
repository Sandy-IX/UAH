extends CharacterBody2D
class_name Player

#region Stats
enum STATES {idle, walk, normal_attack, parry, jump, fall, dash, kanji_sequence, hurt, death}
@export var hp: int = 5
var max_hp: int = 5
var attack_damage: float = 1.0
<<<<<<< Updated upstream
@export var knock_back_strength: float = 67.0 * 12.0 
=======
@export var knock_back_strength: float = 67
var amount = 1
>>>>>>> Stashed changes
#endregion

#region Onready Variables
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_right: Area2D = $Sword/SwordRight
@onready var sword_right_collider: CollisionShape2D = $Sword/SwordRight/SwordRightCollider
@onready var sword_left: Area2D = $Sword/SwordLeft
@onready var sword_left_collider: CollisionShape2D = $Sword/SwordLeft/SwordLeftCollider
@onready var kanji_sytem_overlay: CanvasLayer = $"../KanjiSytemOverlay"
<<<<<<< Updated upstream
@onready var main_collider = sword_right_collider
@onready var not_main_collider = sword_left_collider
=======
@onready var player_damage_area: Area2D = $Player_Damage_Area
@onready var basic_stance: Node2D = $Sword/BasicStance
>>>>>>> Stashed changes
#endregion

#region Constants (Calibrated for 1080p)
const SPEED = 650.0
const JUMP_VELOCITY = -1800.0
const DECELERATION = 67.0 * 200.0
const jump_gravity = 4000.0
const fall_gravity_multiplier = 1.5 
const max_coyote_time = 0.15
const max_input_buffer = 0.15
const jump_cut_off = 2.5
const DASH_SPEED = 2000.0   
const DASH_DURATION = 0.25
const dash_cooldown = 3.0 
var knockback_duration = 250.0
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
<<<<<<< Updated upstream
=======

@onready var main_collider = sword_right_collider
@onready var not_main_collider = sword_left_collider
@onready var current_stance = basic_stance
>>>>>>> Stashed changes
#endregion

func _ready() -> void:
	if kanji_sytem_overlay:
		kanji_sytem_overlay.kanji_state_changed.connect(_on_kanji_toggled)
	sword_right_collider.disabled = true
	sword_left_collider.disabled = true
	print("Initial HP: ", hp)

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
			
	if just_collided:
		knockback_timer -= delta
		if knockback_timer <= 0.0:
			velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
			if velocity.x == 0:
				knockback_timer = 0.0
				
	if not just_collided:
		knockback_timer -= delta
		if knockback_timer <= 0.0:
			velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
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
			# Slow the player down to a halt during hitstun flinch
			velocity.x = move_toward(velocity.x, 0, delta * DECELERATION)
			if not is_on_floor():
				velocity.y += jump_gravity * delta
	else:
		die()

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if current_state == STATES.hurt or current_state == STATES.death:
		return
		
	if event.is_action_pressed("Attack") and current_state != STATES.dash and current_state != STATES.normal_attack:
		start_attack()
	if event.is_action_pressed("storm_kanji_toggle"):
		if kanji_sytem_overlay:
			kanji_sytem_overlay.visible = !kanji_sytem_overlay.visible
	if event.is_action_pressed("test"):
		take_damage(1)

#region states
func handle_direction(direction):
	if (current_state == STATES.normal_attack and direction == 0) or current_state == STATES.hurt:
		return
		
	if direction != 0:
		old_direction = direction
		if direction > 0:
			sprite.flip_h = false
			not_main_collider = sword_left_collider
			main_collider = sword_right_collider
		elif direction < 0:
			sprite.flip_h = true
			main_collider = sword_left_collider
			not_main_collider = sword_right_collider
		not_main_collider.disabled = true

func handle_idle(delta: float):
	sprite.play("idle")
	velocity.x = move_toward(velocity.x, 0, delta * DECELERATION)

func handle_fall(delta: float, direction: float):
	sprite.play("fall")
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, delta * DECELERATION)
	
func handle_walk(delta: float, direction: float):
	sprite.play("walk")
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, delta * DECELERATION)
	
func handle_jump(direction: float):
	sprite.play("jump")
	if direction != 0:
		velocity.x = direction * SPEED
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
	pass

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
			velocity.x = old_direction * knockback_duration * 3
		else:
<<<<<<< Updated upstream
			velocity.x = -old_direction * knock_back_strength * .67
			
=======
			if abs(velocity.x) < 50:
				velocity.x = -old_direction * (knock_back_strength / 0.67)
>>>>>>> Stashed changes
	if not is_on_floor():
		velocity.y += fall_gravity_multiplier * jump_gravity * delta
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
		
func take_damage(Amount: int):
	if current_state == STATES.death:
		return
		
	hp -= Amount
	print("HP Remaining: ", hp)
	
	if hp <= 0:
		die()
	else:
		current_state = STATES.hurt
		sprite.play("hurt")

func die():
	set_physics_process(false)
	sprite.play("death")
	await sprite.animation_finished
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		tree.reload_current_scene()
#endregion

#region kanji system
func _on_kanji_toggled(is_active: bool) -> void:
	if is_active:
		Engine.time_scale = 0.25
		current_state = STATES.kanji_sequence # Explicitly set this
	else:
		Engine.time_scale = 1.0

		current_state = STATES.idle
<<<<<<< Updated upstream
=======
		_on_kanji_success_stance_change()

func _on_kanji_success_stance_change() -> void:
	print("Stance Changed")
>>>>>>> Stashed changes
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
	if  current_state != STATES.hurt and current_state != STATES.death:
		if area:
			print("detected")
		
			take_damage(amount)
#endregion
