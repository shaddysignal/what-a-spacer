extends Node2D

@onready var character_spawner = $PlayerSpawner

@onready var log_ref = Log.create("Trace", get_path())

func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_peer_disconnect)

	character_spawner.spawned.connect(func(node: Node): log_ref.trace("SPAWNED: event fired for %s" % node.get_path()))
	character_spawner.despawned.connect(func(node: Node): log_ref.trace("DESPAWNED: event fired for %s" % node.get_path()))

	if multiplayer.is_server():
		_init_player.rpc_id(1)
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
		_deinit_player.rpc_id(1, p.get_path())

@rpc("any_peer", "call_local", "reliable")
func _deinit_player(player_path: NodePath):
	get_node(player_path).queue_free()

@rpc("any_peer", "call_local", "reliable")
func _init_player():
	var pods = get_tree().get_nodes_in_group("life_support")
	pods.sort()
	
	var owner_id = multiplayer.get_remote_sender_id()
	log_ref.trace("Before await: %s" % owner_id)
	var spawn_point = await _find_pod(pods)
	log_ref.trace("After await: %s" % owner_id)

	var ch = character_spawner.spawn([owner_id, spawn_point])
	log_ref.trace("Player spawn with authority %s" % ch.get_multiplayer_authority())

func _find_pod(pods: Array) -> Vector2:
	var pod_index = randi_range(0, pods.size() - 1)

	var pod = pods[pod_index]
	var spawn_area = pod.get_node("PodArea")
	var spawn_point = pod.get_node("Marker").global_position
	if (spawn_area.has_overlapping_bodies()):
		log_ref.trace("Found pod %s and it has bodies in it. Awaiting..." % pod_index)
		await Global.await_sec(0.2)
		return await _find_pod(pods)
	else:
		log_ref.trace("Found pod %s and its empty" % pod_index)
		return spawn_point
