extends Node2D

@onready var ui_layer = $UI
@onready var player_spawner = $PlayerSpawner

@onready var log_ref = Log.create("Trace", get_path())

func _ready() -> void:
	player_spawner.spawned.connect(_on_player_spawned)
	player_spawner.despawned.connect(func(node: Node): log_ref.trace("DESPAWNED: event fired for %s" % node.get_path()))
	
	SteamNetwork.tree_multiplayer_peer_setup()

	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnect)
	else:
		multiplayer.server_disconnected.connect(_on_server_disconnect) # Never called?
		multiplayer.peer_disconnected.connect(func(id: int): if id == 1: _on_server_disconnect())

	get_tree().current_scene.loading_done.connect(_on_scene_ready)

func _on_player_spawned(p: Player):
	if p.is_multiplayer_authority():
		log_ref.trace("setup camera for player %s (%s)" % [p.get_path(), p.get_multiplayer_authority()])
		p.camera_setup()

func _on_scene_ready():
	ui_layer.visible = true

	# TODO maybe alright, seem too much though
	if multiplayer.is_server():
		var ch = await _init_player(1)
		ch.camera_setup()
	else:
		_init_player.rpc_id(1, multiplayer.get_unique_id())

func _on_server_disconnect():
	SteamNetwork.leave_lobby()
	SceneAuthority.with_path("res://scenes/main_menu.tscn")

func _on_peer_disconnect(id: int):
	var players = get_tree().get_nodes_in_group("players")
	var to_delete = players.filter(func(p: Node): return p.get_multiplayer_authority() == id)
	for p in to_delete:
		p.queue_free()

@rpc("any_peer", "call_local", "reliable")
func _init_player(id: int) -> Player:
	var pods = get_tree().get_nodes_in_group("life_support")
	pods.sort()
	
	var owner_id = id
	var spawn_point = await _find_pod(pods)

	var ch = player_spawner.spawn([owner_id, spawn_point])
	log_ref.trace("Player spawn with authority %s" % ch.get_multiplayer_authority())

	return ch

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
