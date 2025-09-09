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

# --- REMOVED ---
# The old texture variables are no longer needed.
# @export var idle_texture: Texture2D
# @export var move_texture: Texture2D

# --- UPDATED NODE REFERENCE ---
# We now get the AnimatedSprite2D. It's good practice to rename the variable.
@onready var animated_sprite: AnimatedSprite2D = $Sprite2D # The node is still named "Sprite2D" in the tree
# ---

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# ... (The _ready function and transition functions are the same) ...
func _ready():
	for zone in get_tree().get_nodes_in_group("TransitionZones"):
		zone.player_entered_zone.connect(on_player_entered_transition_zone)
		zone.player_exited_zone.connect(on_player_exited_transition_zone)

func on_player_entered_transition_zone(data: Dictionary):
	can_transition = true
	transition_data = data

func on_player_exited_transition_zone():
	can_transition = false
	transition_data = {}


func _physics_process(delta):
	if is_in_transition:
		return

	if can_transition and Input.is_action_just_pressed(transition_data.action):
		start_transition()
		return

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# --- UPDATED ANIMATION LOGIC ---
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		velocity.x = direction * SPEED
		
		# Only change animation if it's not already playing
		if animated_sprite.animation != "move":
			animated_sprite.play("move")
			
		if direction > 0:
			facing_direction = 1
		else:
			facing_direction = -1
	else:
		velocity.x = lerp(velocity.x, 0.0, FRICTION)
		
		# Only change animation if it's not already playing
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

	# Sprite flipping logic (works the same for AnimatedSprite2D)
	if facing_direction > 0:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false

	move_and_slide()


func start_transition():
	is_in_transition = true
	can_transition = false
	
	var tween = create_tween()
	var exit_direction = transition_data.exit_direction
	var exit_distance = 800.0
	
	# --- UPDATED TRANSITION ---
	# Set animation to "move" for the transition walk-off
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
	
# MANGO DIALOGUE SUPPORT

var in_dialogue: bool = false
var player: CharacterBody2D = null  # make sure this is set when player enters range

func start_caleb_dialogue():
	in_dialogue = true
	velocity = Vector2.ZERO  # NPC stops

	if player:
		player.velocity = Vector2.ZERO          # Stop player movement
		player.set_physics_process(false)       # Freeze controls
		if player.has_node("Sprite2D"):         # Force idle animation
			player.get_node("Sprite2D").play("idle")

	# Load dialogue resource
	var caleb_dialogue: DialogueResource = load("res://dialogue/caleb_mango.dialogue")
	DialogueManager.start(caleb_dialogue)

	# Connect once
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended, CONNECT_ONE_SHOT)


func _on_dialogue_ended():
	in_dialogue = false

	if player:
		player.set_physics_process(true)        # Resume movement
