# level_1_questonhall.gd

extends Node2D

# --- Node References ---
# We need references to the player and the cat to coordinate them.
# We will assign these in the Godot Inspector.
@export var player: CharacterBody2D
@export var cat: CharacterBody2D

# --- Dialogue Setup ---
@onready var balloon = preload("res://dialogue/balloon.tscn").instantiate()
var dialogue_res = preload("res://dialogue/main.dialogue")

# --- State Variables ---
# These variables track the progress of the quest/interaction.
var cat_is_following: bool = false


func _ready():
	# Add the dialogue balloon to the scene
	add_child(balloon)
	
	DialogueManager.mutated.connect(_on_dialogue_mutated)
	
	# Check if the minigame has been completed
	if GameState.persevere_minigame_completed:
		
		# 1. Disable the Minigame Trigger (this code already existed)
		$MinigameTrigger.get_child(0).call_deferred("set_disabled", true)
		$MinigameTrigger.call_deferred("set_monitoring", false)
		
		# 2. Disable the Hallway Trigger as requested
		$HallwayTrigger.get_child(0).call_deferred("set_disabled", true)
		$HallwayTrigger.call_deferred("set_monitoring", false)
		
		# 3. Check if a return position has been set by the minigame
		if GameState.player_return_position != null:
			if player:
				player.global_position = GameState.player_return_position
				player.set_input_enabled(true)
				var camera = player.get_node_or_null("Camera2D")
				if camera:
					camera.zoom = Vector2.ONE 
					camera.reset_smoothing()
			
			# 4. Reset the variable so this doesn't happen every time we load.
			GameState.player_return_position = null

# This function is called whenever DialogueManager.mutated.emit() is used.
func _on_dialogue_mutated(data: Dictionary):
	# Check if the mutation is the one we're looking for.
	if data.get("mutation") == "follow_cat":
		print("Player chose to follow the cat!") # For debugging
		
		# Update our state variable.
		cat_is_following = true
	
		if cat and cat.has_method("start_following"):
			cat.start_following(player)
	elif data.get("mutation") == "start_minigame":
		print("WORKAROUND 1: Mutation triggered scene change")
		get_tree().change_scene_to_file("res://scenes/minigames/minigame_persevere.tscn")

func start_cat_dialogue():
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		var tween_in = create_tween()
		tween_in.set_trans(Tween.TRANS_SINE)
		tween_in.tween_property(camera, "zoom", Vector2(1.2, 1.2), 1.0)

	DialogueManager.dialogue_ended.connect(_on_dialogue_ended_for_cat_zoom_out, CONNECT_ONE_SHOT)

	balloon.show()
	balloon.start(dialogue_res, "cat_encounter")

func _on_dialogue_ended_for_cat_zoom_out(_resource: DialogueResource):
	# The logic is now guaranteed to run at the right time.
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		var tween_out = create_tween()
		tween_out.set_trans(Tween.TRANS_SINE)
		tween_out.tween_property(camera, "zoom", Vector2.ONE, 0.5)

func _on_hallway_trigger_body_entered(body):
	if body != player:
		return
	
	balloon.start(dialogue_res, "hallway_thoughts")
	$HallwayTrigger/CollisionShape2D.call_deferred("set_disabled", true)
	
func _on_minigame_trigger_body_entered(body):
	# Check if it's the player
	if body != player:
		return
	player.set_input_enabled(false)

	var camera = player.get_node_or_null("Camera2D")
	if camera:
		# Create a new tween. It will play automatically.
		var tween = create_tween()
		# Use a smooth transition curve.
		tween.set_trans(Tween.TRANS_SINE)
		# Animate the camera's "zoom" property to a new Vector2 value over 1.0 second.
		tween.tween_property(camera, "zoom", Vector2(1.2, 1.2), 1.0)

	# Show the dialogue for the minigame
	balloon.show()
	balloon.start(dialogue_res, "paper_minigame_start")

	# Disable the trigger safely.
	$MinigameTrigger.get_child(0).call_deferred("set_disabled", true)
	$MinigameTrigger.call_deferred("set_monitoring", false)
