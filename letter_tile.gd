# letter_tile.gd
extends Area2D

# We will set this in the editor for each letter (e.g., "PE", "R", "SE").
@export var letter_id: String = ""

# This signal will be sent to the main minigame script when this tile is dropped.
signal dropped_on_zone(letter_tile: Area2D, drop_zone: Area2D)

# --- State Variables ---
var is_dragging: bool = false
var return_position: Vector2 # The position to slide back to if the drop is invalid.

func _ready():
	# Make the Area2D clickable.
	input_pickable = true
	# Store the starting position.
	return_position = global_position


func _input_event(_viewport, event, _shape_idx):
	# This function is called automatically when the area is clicked.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Mouse button was pressed down: start dragging.
			is_dragging = true
			# Set the return position to wherever the tile was when picked up.
			return_position = global_position
		else:
			# Mouse button was released: stop dragging and check for a drop.
			is_dragging = false
			check_for_drop_zone()


func _process(delta):
	# While dragging, make the tile follow the mouse.
	if is_dragging:
		global_position = get_global_mouse_position()


func check_for_drop_zone():
	# Get a list of all areas this tile is overlapping with.
	var overlapping_areas = get_overlapping_areas()

	if not overlapping_areas.is_empty():
		# It's overlapping with at least one zone. Let's use the first one.
		var drop_zone = overlapping_areas[0]
		# Send a signal to the main game, telling it which tile was dropped on which zone.
		dropped_on_zone.emit(self, drop_zone)
	else:
		# Not dropped on any zone, so slide back to the return position.
		slide_back()


func slide_back():
	# We use a Tween to create a smooth sliding animation.
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT) # This makes the slide look nice.
	tween.set_ease(Tween.EASE_OUT)
	# Animate the 'global_position' property from its current value back to the 'return_position'.
	tween.tween_property(self, "global_position", return_position, 0.3)
