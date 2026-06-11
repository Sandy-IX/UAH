extends CanvasLayer

@onready var pen: Line2D = $Pen
@onready var strokes_parent = $Strokes 

var _pressed: bool = false
var current_line: Line2D = null
var strokes_hit: Array = []
@export var kanji_strokes = 8
signal kanji_state_changed(is_active: bool)

func _ready() -> void:
	visible = false 
	for child in strokes_parent.get_children():
		if child is Area2D:
			child.mouse_entered.connect(_on_stroke_entered.bind(child))

func _unhandled_input(event: InputEvent) -> void:

	if not visible: 
		reset_kanji()
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_pressed = event.pressed
			if _pressed:
				current_line = Line2D.new()
				current_line.default_color = Color.BLACK
				current_line.width = 80
				pen.add_child(current_line)
				current_line.add_point(event.position)
			else:
				current_line = null
				
	elif event is InputEventMouseMotion and _pressed and current_line:
		current_line.add_point(event.position)
	

func _on_stroke_entered(area: Area2D) -> void:
	if visible and _pressed and not strokes_hit.has(area):
		strokes_hit.append(area)
		area.modulate = Color.GREEN
		if strokes_hit.size() >= kanji_strokes:
			_on_kanji_success()

func _on_kanji_success():
	visible = false
	kanji_state_changed.emit(false) 
	reset_kanji()
	print("Kanji Complete!")
func reset_kanji():
	strokes_hit.clear()
	for child in strokes_parent.get_children():
		if child is Area2D:
			child.modulate = Color.WHITE
	for line in pen.get_children():
		line.queue_free()
