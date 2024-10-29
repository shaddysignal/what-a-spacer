extends Button

@onready var log_ref = Log.create("Trace", get_path())

func _on_pressed() -> void:
	if SteamNetwork.lobby_id == 0:
		SteamNetwork.create_lobby(Steam.LOBBY_TYPE_PUBLIC, SteamNetwork.lobby_members_max)

		# TODO: Is it ugly? Move params into another special method?
		SceneAuthority.with_path(
			"res://scenes/main.tscn",
			{
				"signal_handle": SteamNetwork.lobby_ready,
				"message": "Waiting for steam..."
			}
		)
	else:
		log_ref.error("Lobby already exist")
