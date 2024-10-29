extends Node2D

@onready var spinner = $Spinner

func _init() -> void:
	visible = false

func _physics_process(delta: float) -> void:
	if visible:
		spinner.rotate(PI / 2 * delta)
