# Attach this script to your CharacterBody2D
extends CharacterBody2D

const SPEED = 200.0
const FRICTION = 0.1	
var facing_direction: int = 1

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- TRANSITION STATE VARIABLES ---
var can_transition: bool = false
var is_in_transition: bool = false
var transition_data: Dictionary = {}

# --- Dialogue trigger ---
var start_position: Vector2
var dialogue_trigger_distance: float = 300  # 25 pixels forward
var dialogue_shown := false  # ensure it only triggers once

# --- UPDATED NODE REFERENCE ---
@onready var animated_sprite: AnimatedSprite2D = $Sprite2D # The node is still named "Sprite2D" in the tree
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# --- READY ---
func _ready():
	# Record the starting position when the scene begins
	start_position = global_position
	
	for zone in get_tree().get_nodes_in_group("TransitionZones"):
		zone.player_entered_zone.connect(on_player_entered_transition_zone)
		zone.player_exited_zone.connect(on_player_exited_transition_zone)

# --- TRANSITION ZONES ---
func on_player_entered_transition_zone(data: Dictionary):
	can_transition = true
	transition_data = data

func on_player_exited_transition_zone():
	can_transition = false
	transition_data = {}

# --- PHYSICS ---
func _physics_process(delta):
	if is_in_transition:
		return

	# Dialogue trigger check
	if not dialogue_shown and global_position.x >= start_position.x + dialogue_trigger_distance:
		_show_balloon_dialogue()
		dialogue_shown = true
		return  # stop movement this frame while dialogue shows

	# Transition check
	if can_transition and Input.is_action_just_pressed(transition_data.action):
		start_transition()
		return

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# --- ANIMATION + MOVEMENT ---
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		velocity.x = direction * SPEED
		
		if animated_sprite.animation != "move":
			animated_sprite.play("move")
			
		if direction > 0:
			facing_direction = 1
		else:
			facing_direction = -1
	else:
		velocity.x = lerp(velocity.x, 0.0, FRICTION)
		
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

	# Flip sprite
	if facing_direction > 0:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false

	move_and_slide()

# --- TRANSITION ---
func start_transition():
	is_in_transition = true
	can_transition = false
	
	var tween = create_tween()
	var exit_direction = transition_data.exit_direction
	var exit_distance = 800.0
	
	animated_sprite.play("move")
	
	if exit_direction > 0:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false

	tween.tween_property(self, "global_position", global_position + Vector2(exit_distance * exit_direction, 0), 2.0).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(teleport_player)

func teleport_player():
	self.global_position = transition_data.target_position
	is_in_transition = false
	velocity.x = 0
	
# --- Dialogue Balloon Function ---
func _show_balloon_dialogue():
	var balloon = load("res://dialogue/balloon.tscn").instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(load("res://dialogue/mainstart.dialogue"), "start")
	# balloon.start(load("res://dialogue/caleb_mango.dialogue"), "start")
