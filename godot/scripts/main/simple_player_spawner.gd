extends Node
class_name PlayerSpawner

const player_scene = preload("res://scenes/character_body.tscn")
const player_group = "players"

var spawner_mutex = Mutex.new()

@onready var log_ref = Log.create("Trace", get_path())

@export var spawn_root: NodePath
var connected_peers = []

func _ready() -> void:
	register_spawner.rpc_id(1)

	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_unregister_spawner)

@rpc("any_peer", "call_local", "reliable")
func register_spawner():
	spawner_mutex.lock()

	var caller_id = multiplayer.get_remote_sender_id()

	for peer_id in connected_peers:
		spawn.rpc_id(caller_id, [peer_id])

	spawn.rpc([caller_id])
	connected_peers.append(caller_id)

	spawner_mutex.unlock()

func _unregister_spawner(peer_id: int):
	spawner_mutex.lock()

	connected_peers.erase(peer_id)
	
	var players = get_tree().get_nodes_in_group(player_group)
	var to_delete = players.filter(func(p: Node): return p.get_multiplayer_authority() == peer_id)

	for n in to_delete:
		despawn.rpc(n.get_path())
	
	spawner_mutex.unlock()

@rpc("any_peer", "call_local", "reliable")
func spawn(data: Array) -> Node:
	var player_node = await _create_player(data)
	get_node(spawn_root).add_child.call_deferred(player_node, true)

	log_ref.trace("Player spawn with authority %s" % player_node.get_multiplayer_authority())

	return player_node

@rpc("any_peer", "call_local", "reliable")
func despawn(node_path: NodePath):
	var node_to_despawn = get_node(node_path)
	node_to_despawn.queue_free()

func _create_player(data: Array) -> Player:
	var owner_id = data[0]

	log_ref.trace("Init player with %s id" % owner_id)

	var unpacked: Player = player_scene.instantiate()
	unpacked.set_multiplayer_authority(owner_id)

	var pods = get_tree().get_nodes_in_group("life_support")
	pods.sort()

	var spawn_point = await _find_pod(pods)

	unpacked.global_position = spawn_point

	return unpacked

func _find_pod(pods: Array) -> Vector2:
	var pod_index = randi_range(0, pods.size() - 1)

	var pod = pods[pod_index]
	var spawn_area = pod.get_node("PodArea")
	var spawn_point = pod.get_node("Marker").global_position
	if (spawn_area.has_overlapping_bodies()):
		log_ref.trace("Found pod %s (%s) and it has bodies in it. Awaiting..." % [pod.name, pod_index])
		await get_tree().create_timer(1).timeout
		return await _find_pod(pods)
	else:
		log_ref.trace("Found pod %s (%s) and its empty" % [pod.name, pod_index])
		return spawn_point
