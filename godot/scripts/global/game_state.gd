extends Node

@onready var log_ref = Log.create("Trace", get_path())

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST || what == NOTIFICATION_WM_GO_BACK_REQUEST:
		log_ref.info("Exit notification recieved")
		SteamNetwork.leave_lobby()

		get_tree().quit()

