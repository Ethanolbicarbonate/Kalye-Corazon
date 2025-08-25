extends Node2D

@onready var balloon = preload("res://dialogue/balloon.tscn").instantiate()
var dialogue_res = preload("res://dialogue/main.dialogue")

var dialogue_started := false

func _ready():
	add_child(balloon)

func _process(delta: float) -> void:
	if not dialogue_started and is_player_moving():
		dialogue_started = true
		balloon.start(dialogue_res, "start") # replace "start" with actual title
		

func is_player_moving() -> bool:
	# Replace with your actual input movement check
	return Input.is_action_pressed("ui_right") \
		or Input.is_action_pressed("ui_left") \
		or Input.is_action_pressed("ui_up") \
		or Input.is_action_pressed("ui_down")
