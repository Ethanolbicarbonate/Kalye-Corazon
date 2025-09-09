extends CharacterBody2D

const SPEED = 300.0
const LEAD_DISTANCE = 96.0   # how far ahead the NPC should stay
const COAST_DISTANCE = 64.0  # how much farther it walks after player stops

@onready var dialogue_resource = preload("res://dialogue/caleb_mango.dialogue")
@onready var dialogue_balloon_scene = preload("res://dialogue/balloon.tscn")

var player: CharacterBody2D = null
var player_in_range = false
var direction: int = 0

# 🔥 Add reference to NPC's sprite
@onready var npc_sprite: AnimatedSprite2D = $Sprite2D  

func _ready() -> void:
	# 🔥 Ensure NPC starts in idle animation before player arrives
	if npc_sprite:
		npc_sprite.play("idle")

func _physics_process(delta: float) -> void:
	if player == null:
		return

	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Copy player's movement direction
	var player_dir := Input.get_axis("ui_left", "ui_right")

	if player_dir != 0:
		direction = player_dir
		velocity.x = direction * SPEED
	else:
		# If player stopped, keep walking until lead+coast is reached
		if direction != 0:
			if direction > 0:
				if global_position.x < player.global_position.x + LEAD_DISTANCE + COAST_DISTANCE:
					velocity.x = direction * SPEED
				else:
					velocity.x = 0
					direction = 0
			elif direction < 0:
				if global_position.x > player.global_position.x - LEAD_DISTANCE - COAST_DISTANCE:
					velocity.x = direction * SPEED
				else:
					velocity.x = 0
					direction = 0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	# Handle interaction
	if player_in_range and Input.is_action_just_pressed("interact"):
		start_dialogue()

func start_dialogue() -> void:
	var balloon = dialogue_balloon_scene.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(dialogue_resource)

# Detect player in NPC's range
func _on_area_2d_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player = body
		player_in_range = true
		start_dialogue2()

func _on_area_2d_body_exited(body: Node) -> void:
	if body == player:
		player_in_range = false
		player = null

var in_dialogue: bool = false

func start_dialogue2() -> void:
	in_dialogue = true
	velocity = Vector2.ZERO
	if npc_sprite:
		npc_sprite.play("idle")  # NPC stays idle during dialogue

	if player:
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)  # freeze player controls
		if player.has_node("Sprite2D"):
			player.get_node("Sprite2D").play("idle")  # Player idle

	# Show balloon dialogue
	var balloon = dialogue_balloon_scene.instantiate()
	get_tree().current_scene.add_child(balloon)

	# Call start() with both arguments (dialogue resource + title string)
	balloon.start(dialogue_resource, "start")

	# Resume when dialogue ends
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended, CONNECT_ONE_SHOT)

func _on_dialogue_ended():
	in_dialogue = false

	if player:
		player.set_physics_process(true)        # Resume movement

	# NPC stays idle until player moves again
	velocity = Vector2.ZERO
	if npc_sprite:
		npc_sprite.play("idle")

	# 🔥 Disable NPC's physics collision so player can walk past
	if $CollisionShape2D:
		$CollisionShape2D.disabled = true
