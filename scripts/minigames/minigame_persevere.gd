# minigame_persevere.gd
extends Node2D

# --- Node References ---
# We get references to the containers for easy access to the tiles and zones.
@onready var letter_tiles_container = $LetterTiles
@onready var drop_zones_container = $DropZones
@onready var success_screen = $SuccessScreen

# --- State Variables ---
var correctly_placed_count: int = 0
var total_zones_to_win: int = 0

func _ready():
	# Hide the success screen at the start.
	success_screen.hide()

	# Count how many zones we need to fill to win.
	total_zones_to_win = drop_zones_container.get_child_count()

	# This is crucial: we must connect the 'dropped_on_zone' signal
	# from EVERY letter tile to a function in THIS script.
	for tile in letter_tiles_container.get_children():
		# The function _on_letter_tile_dropped will now be called for any tile.
		tile.dropped_on_zone.connect(_on_letter_tile_dropped)

# This is the main logic function, called whenever any tile is dropped on any zone.
func _on_letter_tile_dropped(letter_tile: Area2D, drop_zone: Area2D):
	# Check 1: Is this drop zone already correctly filled?
	if drop_zone.current_letter != null:
		# The zone is occupied. Tell the tile to slide back.
		letter_tile.slide_back()
		return

	# Check 2: Does the tile's ID match the zone's required ID?
	if letter_tile.letter_id == drop_zone.correct_letter_id:
		# --- CORRECT DROP ---
		# Tell the zone it is now filled with this letter.
		drop_zone.current_letter = letter_tile

		# Snap the tile perfectly into the center of the zone.
		letter_tile.global_position = drop_zone.global_position

		# Make the tile non-draggable anymore.
		letter_tile.input_pickable = false

		# Update the tile's return position to its new locked spot.
		letter_tile.return_position = letter_tile.global_position

		# Increment our win counter.
		correctly_placed_count += 1

		# Check if the player has won.
		check_for_win()
	else:
		# --- INCORRECT DROP ---
		# The tile doesn't belong here. Tell it to slide back.
		letter_tile.slide_back()

func check_for_win():
	if correctly_placed_count == total_zones_to_win:
		# The player has won!
		print("MINIGAME WON!") # For debugging
		success_screen.show()
		# Optional: disable all remaining tiles to prevent interaction behind the UI
		for tile in letter_tiles_container.get_children():
			tile.input_pickable = false

func _on_button_pressed() -> void:
	GameState.persevere_minigame_completed = true
	GameState.player_return_position = Vector2(1230, -180)
	# Now, transition back to the main level.
	# IMPORTANT: Make sure this path is correct for your project!
	get_tree().change_scene_to_file("res://scenes/levels/level1_questonhall.tscn")
