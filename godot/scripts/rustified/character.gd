extends CharacterBody2D

@export var speed = 25
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent

func _ready():
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_mouse"):
		set_movement_target(get_global_mouse_position())

func set_movement_target(movement_target: Vector2):
	navigation_agent.target_position = movement_target

func _physics_process(_delta):
	if navigation_agent.is_navigation_finished():
		return

	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()

	velocity = current_agent_position.direction_to(next_path_position) * speed
	move_and_slide()
