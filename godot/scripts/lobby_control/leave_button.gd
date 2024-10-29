extends Button

func _on_pressed() -> void:
	SteamNetwork.lobby_leave.emit()
	SceneAuthority.with_path("res://scenes/main_menu.tscn")
