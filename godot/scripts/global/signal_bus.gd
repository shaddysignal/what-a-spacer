extends Node

@onready var log_ref = Log.create("Trace", get_path())

signal game_message(tag: String, message: String)
signal game_quit

func _ready() -> void:
	game_message.connect(_on_game_message)
	game_quit.connect(_on_game_quit)

func _on_game_message(tag: String, message: String) -> void:
	log_ref.info("Log event with tag '%s' and message '%s'" % [tag, message])

func _on_game_quit() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST) # exit for desktop
	# get_tree().root.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST) # exit for mobile?