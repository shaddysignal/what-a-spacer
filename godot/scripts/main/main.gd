extends Node2D

@onready var character_spawner = $Characters/PlayerSpawner

@onready var log_ref = Log.create("Trace", get_path())

func _ready() -> void:
	if multiplayer.is_server():
		_init_player()
		multiplayer.peer_disconnected.connect(_on_peer_disconnect)
	else:
		multiplayer.server_disconnected.connect(_on_server_disconnect) # Never called?
		multiplayer.peer_disconnected.connect(func(id: int): if id == 1: _on_server_disconnect())

		_init_player.rpc_id(1)

func _on_server_disconnect():
	SteamNetwork.leave_lobby()
	SceneAuthority.with_path("res://scenes/main_menu.tscn")

func _on_peer_disconnect(id: int):
	var players = get_tree().get_nodes_in_group("players")
	var to_delete = players.filter(func(p: Node): return p.get_multiplayer_authority() == id)
	for p in to_delete:
		p.queue_free()

@rpc("any_peer", "call_remote", "reliable")
func _init_player():
	var ch = character_spawner.spawn([multiplayer.get_remote_sender_id()])
	log_ref.trace("Player spawn with authority %s" % ch.get_multiplayer_authority())
