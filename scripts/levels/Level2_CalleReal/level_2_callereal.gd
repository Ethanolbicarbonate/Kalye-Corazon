# level2_callereal.gd
extends Node2D

@export var player_scene: PackedScene
@export var cat_scene: PackedScene

@onready var bgm = $BGMPlayer
var fade_time := 2.0  # seconds for fade-in/out

var player_instance: CharacterBody2D = null
var cat_instance: CharacterBody2D = null

@onready var balloon = preload("res://dialogue/balloon.tscn").instantiate()
var dialogue_res = preload("res://dialogue/main.dialogue")

func _ready():
	print("DEBUG: Entered Level 2 (Calle Real)!")
	
	# --- LOAD SCENES IF NOT ASSIGNED IN INSPECTOR ---
	if player_scene == null:
		player_scene = preload("res://scenes/player/caleb.tscn") # TODO: update path
	if cat_scene == null:
		cat_scene = preload("res://scenes/npcs/cat.tscn")       # TODO: update path
	
	# --- PLAYER INSTANTIATION AND POSITIONING ---
	player_instance = player_scene.instantiate()
	if get_node_or_null("0"):
		get_node("0").add_child(player_instance)
	else:
		add_child(player_instance)
	
	# Apply player return position or default to Level 2 start
	if GameState.player_return_position != null:
		player_instance.global_position = GameState.player_return_position
		player_instance.set_input_enabled(true)
		var camera = player_instance.get_node_or_null("Camera2D")
		if camera:
			camera.zoom = Vector2.ONE
			camera.reset_smoothing()
		GameState.player_return_position = null
	else:
		player_instance.global_position = Vector2(1394, 683)
		player_instance.set_input_enabled(true)
	
	# --- CAT SPAWNING LOGIC ---
	if GameState.cat_is_following_globally:
		print("DEBUG: Cat is following. Spawning cat in Level 2.")
		cat_instance = cat_scene.instantiate()
		
		if get_node_or_null("0"):
			get_node("0").add_child(cat_instance)
		else:
			add_child(cat_instance)
		
		var cat_spawn_offset = Vector2(player_instance.facing_direction * cat_instance.FOLLOW_DISTANCE, 0)
		cat_instance.global_position = player_instance.global_position + cat_spawn_offset
		
		if player_instance.facing_direction < 0:
			cat_instance.animated_sprite.flip_h = true
		else:
			cat_instance.animated_sprite.flip_h = false
		
		if cat_instance.has_method("start_following"):
			cat_instance.start_following(player_instance)
	else:
		print("DEBUG: Cat is NOT following in Level 2.")
	
	# --- ADD THE DIALOGUE BALLOON TO THE SCENE TREE ---
	add_child(balloon) # <--- THIS IS THE MISSING LINE!
	DialogueManager.mutated.connect(_on_dialogue_mutated) # Connect this here as well for consistency

	# --- Transition Zones ---
	call_deferred("_setup_transition_connections")
	
	# --- BGM Fade In ---
	if bgm:
		bgm.volume_db = -40  # Start nearly silent
		bgm.play()
		var t = create_tween()
		t.tween_property(bgm, "volume_db", 0, fade_time)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)

# --- Transition Back to Level 1 ---
func _on_level1_transition_triggered(transition_data: Dictionary):
	print("DEBUG: _on_level1_transition_triggered called!")
	GameState.returning_from_level = "level2"
	GameState.player_return_position = Vector2(-1764, 689)
	print("DEBUG: Set player_return_position to: ", GameState.player_return_position)

func _setup_transition_connections():
	print("DEBUG: Setting up transition connections")
	for zone in get_tree().get_nodes_in_group("TransitionZones"):
		print("DEBUG: Found TransitionZone with target_scene_path: ", zone.target_scene_path)
		if zone.target_scene_path == "uid://20l8s8unujh4":
			print("DEBUG: Connecting to Level 1 transition zone")
			zone.player_entered_zone.connect(_on_level1_transition_triggered)
			break

# --- Fade Out BGM on Exit ---
func _exit_tree():
	if bgm and bgm.playing:
		var t = create_tween()
		t.tween_property(bgm, "volume_db", -40, fade_time)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)
		t.finished.connect(func():
			bgm.stop())
			
func start_dialogue_balloon_from_trigger(resource: DialogueResource, title: String):
	balloon.show()
	balloon.start(resource, title)

# You might also want to add an _on_dialogue_mutated function if you handle mutations in Level 2
func _on_dialogue_mutated(data: Dictionary):
	# Handle any specific mutations for Level 2 here
	print("DEBUG: Level 2 Dialogue mutated: ", data)
