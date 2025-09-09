extends Area2D

# We will set these values in the Godot Editor for each transition zone.
@export var target_position: Vector2 = Vector2.ZERO # Where the player will teleport.
@export var required_action: String = "ui_accept" # The input action to trigger the transition (e.g., "ui_up").

# This signal will be sent to the player when they enter the zone.
signal player_entered_zone(transition_data: Dictionary)
# This signal is sent when the player leaves.
signal player_exited_zone


func _on_body_entered(body: Node2D) -> void:
	# First, check if the body that entered is the player.
	# The "Player" group should be added to Caleb.tscn.
	if body.is_in_group("Player"):
		var transition_data = {
			"target_position": target_position,
			"action": required_action,
			# We also need to know which way the animation should go.
			"exit_direction": 1 if body.global_position.x < global_position.x else -1 # 1 for right, -1 for left
		}
		# Emit the signal with all the necessary info.
		player_entered_zone.emit(transition_data)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_exited_zone.emit()
