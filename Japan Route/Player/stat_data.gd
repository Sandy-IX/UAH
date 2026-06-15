extends Resource
class_name stat_data


@export var stat_name: String = "Stat"
@export var base_value: float = 0.0

#leveling stat changes
var permanent_modifier: float = 0.0


#temporary stat changes such as potions, etc
var flat_modifer : Array[float] = []
var percent_modifer: Array[float] = []

#calculated value caching
var cached_value : float = 0.0
var is_dirty: bool = true

func get_value()->float:
	if is_dirty:
		cached_value = calculate_final_value()
		is_dirty = false
	return cached_value

func calculate_final_value():
	var total_flat: float = base_value + permanent_modifier
	for f in flat_modifer:
		total_flat += f
	
	var total_percent: float = 1.0
	for p in percent_modifer:
		total_percent += p
	
	return total_flat * total_percent
	
func add_flat_modifier(amount :float)-> void:
	flat_modifer.append(amount)
	is_dirty = true
	
func remove_flat_modifier(amount: float) -> void:
	flat_modifer.erase(amount)
	is_dirty = true

func add_percent_modifier(amount: float) -> void:
	percent_modifer.append(amount)
	is_dirty = true

func remove_percent_modifier(amount: float) -> void:
	percent_modifer.erase(amount)
	is_dirty = true
