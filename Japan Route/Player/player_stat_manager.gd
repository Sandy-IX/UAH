extends Node
class_name StatsManager

signal hp_changed(current_hp: float, max_hp: float)
signal no_hp()
signal stat_changed(stat_name: String, new_value: float)

@export_category("Base Configurations")
@export var base_max_hp: float = 5.0
@export var base_damage: float = 1.0
@export var base_speed: float = 425.0

# Instantiating our advanced stat structures
var max_hp: stat_data
var attack_damage: stat_data
var speed: stat_data

# Dynamic values (Pools)
var current_hp: float:
	set(value):
		current_hp = clamp(value, 0.0, max_hp.get_value())
		hp_changed.emit(current_hp, max_hp.get_value())
		if current_hp <= 0.0:
			no_hp.emit()

func _init() -> void:
	# Set up stats on engine initiation
	max_hp = stat_data.new()
	max_hp.stat_name = "Max HP"
	max_hp.base_value = base_max_hp
	
	attack_damage = stat_data.new()
	attack_damage.stat_name = "Attack Damage"
	attack_damage.base_value = base_damage
	
	speed = stat_data.new()
	speed.stat_name = "Movement Speed"
	speed.base_value = base_speed

func _ready() -> void:
	current_hp = max_hp.get_value()

func heal(amount: float) -> void:
	current_hp += amount

func take_damage(amount: float) -> void:
	current_hp -= amount

# Helper function to easily apply a temporary buff
func apply_temporary_buff(stat_type: stat_data, amount: float, duration: float, is_percent: bool = false) -> void:
	if is_percent:
		stat_type.add_percent_modifier(amount)
	else:
		stat_type.add_flat_modifier(amount)
		
	stat_changed.emit(stat_type.stat_name, stat_type.get_value())
	
	# Create a localized timer to automatically revert the buff
	await get_tree().create_timer(duration).timeout
	
	if is_percent:
		stat_type.remove_percent_modifier(amount)
	else:
		stat_type.remove_flat_modifier(amount)
		
	stat_changed.emit(stat_type.stat_name, stat_type.get_value())
