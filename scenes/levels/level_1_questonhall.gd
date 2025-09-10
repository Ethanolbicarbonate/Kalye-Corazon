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
var cat_can_be_encountered: bool = false
var cat_is_following: bool = false


func _ready():
	# Add the dialogue balloon to the scene
	add_child(balloon)
	
	DialogueManager.mutated.connect(_on_dialogue_mutated)
	
	if GameState.persevere_minigame_completed:
		$MinigameTrigger.get_child(0).call_deferred("set_disabled", true) # Disables the collision shape
		$MinigameTrigger.monitoring = false # Stops the Area2D from checking for bodies


# This function is called when any physics body enters the HallwayTrigger area.
func _on_hallway_trigger_body_entered(body):
	# First, check if the body that entered is the player.
	if body != player:
		return
	
	# Start the first part of the dialogue.
	balloon.start(dialogue_res, "hallway_thoughts")
	
	# Update the state to allow the next part of the interaction to happen.
	cat_can_be_encountered = true
	
	# Disable the trigger's collision shape so it doesn't run again.
	# We use 'call_deferred' to avoid errors during the physics process.
	$HallwayTrigger/CollisionShape2D.call_deferred("set_disabled", true)


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
	# This is called by the cat script when it's time for the second dialogue.
	balloon.show() # Make sure it's visible first
	balloon.start(dialogue_res, "cat_encounter")


func _on_minigame_trigger_body_entered(body):
	# Check if it's the player
	if body != player:
		return

	# Show the dialogue for the minigame
	balloon.show()
	balloon.start(dialogue_res, "paper_minigame_start")

	# Disable the trigger safely.
	$MinigameTrigger.get_child(0).call_deferred("set_disabled", true)
	# FIX #2: Use call_deferred to change monitoring safely.
	$MinigameTrigger.call_deferred("set_monitoring", false)
