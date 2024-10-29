extends Node2D

@onready var player_spawner: PlayerSpawner = $Characters/SimplePlayerSpawner

@onready var log_ref = Log.create("Trace", get_path())

func _ready() -> void:
	if !multiplayer.is_server():
		multiplayer.server_disconnected.connect(_on_server_disconnect) # Never called?
		multiplayer.peer_disconnected.connect(func(id: int): if id == 1: _on_server_disconnect())

func _on_server_disconnect():
	SteamNetwork.leave_lobby()
	SceneAuthority.with_path("res://scenes/main_menu.tscn")

