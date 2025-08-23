extends CharacterBody2D

const SPEED = 150.0
const FRICTION = 0.1

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var can_climb := false
var climb_position := Vector2.ZERO

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Horizontal movement
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = lerp(velocity.x, 0.0, FRICTION)

	# Check climb action
	if can_climb and Input.is_action_just_pressed("ui_up"):
		position = climb_position
		can_climb = false

	move_and_slide()

# Called by the edge areas
func enable_climb(target_position: Vector2):
	can_climb = true
	climb_position = target_position

func disable_climb():
	can_climb = false


func _on_edge_left_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_edge_left_body_exited(body: Node2D) -> void:
	pass # Replace with function body.


func _on_edge_right_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_edge_right_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
