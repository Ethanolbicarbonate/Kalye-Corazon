# level_1_questonhall.gd

extends Node2D

@export var player: CharacterBody2D
@export var cat: CharacterBody2D

@onready var balloon = preload("res://dialogue/balloon.tscn").instantiate()
var dialogue_res = preload("res://dialogue/main.dialogue")

@onready var bgm = $BGMPlayer
# How long the fade should take (in seconds)
var fade_time := 2.0  

var cat_is_following: bool = false
var minigame_completed: bool = false

func _ready():
    add_child(balloon)
    DialogueManager.mutated.connect(_on_dialogue_mutated)
    
    var story_exit = $"0/LevelExitTrigger"
    story_exit.monitoring = false

    if GameState.persevere_minigame_completed:
        $MinigameTrigger.get_child(0).call_deferred("set_disabled", true)
        $MinigameTrigger.call_deferred("set_monitoring", false)
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
            GameState.player_return_position = null
        if not GameState.persevere_minigame_dialogue_shown:
            balloon.show() # Make sure the balloon is visible
            balloon.start(dialogue_res, "paper_minigame_success")
            GameState.persevere_minigame_dialogue_shown = true # Set the flag so it doesn't repeat.
            
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

# This function is called whenever DialogueManager.mutated.emit() is used.
func _on_dialogue_mutated(data: Dictionary):
    if data.get("mutation") == "follow_cat":
        print("Player chose to follow the cat!")
        cat_is_following = true
        GameState.cat_is_following_globally = true
        if cat and cat.has_method("start_following"):
            cat.start_following(player)
    elif data.get("mutation") == "start_minigame":
        get_tree().change_scene_to_file("res://scenes/minigames/minigame_persevere.tscn")
    
    #  Handle Mutations from Exit Choices 
    elif data.get("mutation") == "proceed_to_level2":
        print("DEBUG: Player chose to proceed to Level 2. Initiating animated exit.")
        GameState.level_1_story_exit_completed = true
        
        # 1. Store the target position for Level 2 (for the next level's _ready function)
        GameState.player_return_position = Vector2(1394, 683)
        
        # 2. Tell the player controller which scene to load AFTER its animation.
        player.scene_to_load_after_transition = "res://scenes/levels/level2_callereal.tscn"
        
        # 3. Temporarily set up transition_data for the walk-off animation.
        #    This is not a real TransitionZone, so we're faking the data.
        player.transition_data = {
            "exit_direction": -1 # Player is moving left to exit
        }
        player.is_in_transition = true # Player starts transition state
        
        # 4. Start the player's walk-off animation.
        player.start_transition()
        
    elif data.get("mutation") == "stay_in_level1":
        print("DEBUG: Player chose to stay in Level 1.")
        player.set_input_enabled(true) # Unfreeze the player
        
        # IMPORTANT: Re-enable the LevelExitTrigger immediately, as the dialogue will then hide it.
        $"0/LevelExitTrigger".monitoring = true

func start_cat_dialogue():
    var camera = player.get_node_or_null("Camera2D")
    if camera:
        var tween_in = create_tween()
        tween_in.set_trans(Tween.TRANS_SINE)
        tween_in.tween_property(camera, "zoom", Vector2(1.2, 1.2), 1.0)
    
    # Connect for the cat dialogue ending.
    DialogueManager.dialogue_ended.connect(_on_cat_dialogue_ended, CONNECT_ONE_SHOT)

    balloon.show()
    balloon.start(dialogue_res, "cat_encounter")

func _on_cat_dialogue_ended(_resource: DialogueResource):
    # The logic is now guaranteed to run at the right time.
    # The 'title' argument is still missing from the signal, so we ignore it.
    
    var camera = player.get_node_or_null("Camera2D")
    if camera:
        var tween_out = create_tween()
        tween_out.set_trans(Tween.TRANS_SINE)
        tween_out.tween_property(camera, "zoom", Vector2.ONE, 0.5)
    
    #  Activate the one-time story exit AFTER cat dialogue.
    # We only activate it if the story exit hasn't been completed yet.
    if not GameState.level_1_story_exit_completed:
        $"0/LevelExitTrigger".monitoring = true
        print("DEBUG: LevelExitTrigger is now active.")

func _on_level_exit_trigger_body_entered(body):
    if body != player: return
    
    player.set_input_enabled(false) # Freeze player at the exit
    
    # --- NEW: Choose the correct dialogue WITH choices ---
    var choice_dialogue_title = "follow_cat_exit_choices" if cat_is_following else "resist_urge_exit_choices"
    
    # We no longer connect dialogue_ended here, as choices will use mutations.
    
    balloon.show()
    balloon.start(dialogue_res, choice_dialogue_title)
    print("DEBUG: Exit choice dialogue started: ", choice_dialogue_title)

func _on_hallway_trigger_body_entered(body):
    if body != player:
        return
    
    balloon.start(dialogue_res, "hallway_thoughts")
    $HallwayTrigger/CollisionShape2D.call_deferred("set_disabled", true)
    
func _on_minigame_trigger_body_entered(body):
    if body != player or minigame_completed: # prevent re-triggering if completed 
        return
    player.set_input_enabled(false) # player blocked here 


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
    
    # Call this after minigame ends 
func _on_minigame_completed():
    minigame_completed = true #  Mark minigame done 
    $MinigameTrigger.get_child(0).set_disabled(true) # Remove blocking wall 
    player.set_input_enabled(true) # Restore player movement
