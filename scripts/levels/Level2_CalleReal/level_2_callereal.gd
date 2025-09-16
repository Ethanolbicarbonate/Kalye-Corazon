extends Node2D

# Drag your caleb.tscn file from the FileSystem into this slot in the Inspector.
@export var player_scene: PackedScene
# Drag your cat.tscn file from the FileSystem into this slot in the Inspector.
@export var cat_scene: PackedScene

@onready var bgm = $BGMPlayer
# How long the fade should take (in seconds)
var fade_time := 2.0  

var player_instance: CharacterBody2D = null
var cat_instance: CharacterBody2D = null

func _ready():
    print("DEBUG: Entered Level 2 (Calle Real)!")

    # --- PLAYER INSTANTIATION AND POSITIONING ---
    # (This section is assumed to be correct and unchanged from our Increment 3 discussion)
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
        # !!! IMPORTANT: Ensure this default position is set correctly for Level 2 !!!
        player_instance.global_position = Vector2(1394, 683) 
        player_instance.set_input_enabled(true)


    # --- CAT SPAWNING LOGIC (UPDATED) ---
    if GameState.cat_is_following_globally:
        print("DEBUG: Cat is following. Spawning cat in Level 2.")
        cat_instance = cat_scene.instantiate()
        
        # Add cat to the same CanvasLayer as the player.
        if get_node_or_null("0"):
            get_node("0").add_child(cat_instance)
        else:
            add_child(cat_instance)

        # --- NEW: Calculate Cat's Initial Spawn Position ---
        # The cat will spawn at its 'FOLLOW_DISTANCE' in front of the player's
        # starting position, based on the player's initial facing_direction.
        # We need the FOLLOW_DISTANCE value from the cat's script.
        # Ensure 'player_instance' has a valid 'facing_direction' (usually defaults to 1).
        var cat_spawn_offset = Vector2(player_instance.facing_direction * cat_instance.FOLLOW_DISTANCE, 0)
        cat_instance.global_position = player_instance.global_position + cat_spawn_offset
        
        # Orient the cat correctly based on the player's initial direction.
        if player_instance.facing_direction < 0:
            cat_instance.animated_sprite.flip_h = true
        else:
            cat_instance.animated_sprite.flip_h = false

        # Tell the new cat to start following the player.
        if cat_instance.has_method("start_following"):
            cat_instance.start_following(player_instance)
    else:
        print("DEBUG: Cat is NOT following in Level 2.")
        
    # When the scene starts, fade IN its BGM
    if bgm:
        bgm.volume_db = 0  # Start almost silent
        bgm.play()           # Start playing immediately
        var t = create_tween()
        # Fade volume from -40 dB to 0 dB (full volume) smoothly
        t.tween_property(
            bgm, "volume_db", 0, fade_time
        ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        
# This function is called whenever the player is leaving the scene.
func _exit_tree():
    # When the scene is about to be removed, fade OUT its BGM
    if bgm and bgm.playing:
        var t = create_tween()
        # Fade volume down to -40 dB over fade_time
        t.tween_property(
            bgm, "volume_db", -40, fade_time
        ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

        # Stop music only AFTER fade-out is complete
        t.finished.connect(func():
            bgm.stop())
