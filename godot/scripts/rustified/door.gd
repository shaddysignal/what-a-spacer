extends Node2D

var opening = false
@onready var door_position: PathFollow2D = $DoorPath/DoorPosition
@export var speed = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var progress = door_position.progress_ratio
	if opening && progress <= 1:
		door_position.progress_ratio = min(progress + speed * delta, 1)
	elif !opening && progress >= 0:
		door_position.progress_ratio = max(progress - speed * delta, 0)

func area_entered(_o):
	opening = true
	
func area_empty(_o):
	opening = false
