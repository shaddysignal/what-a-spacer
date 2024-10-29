extends Button

func _on_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST) # exit for desktop
	# get_tree().root.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST) # exit for mobile?
