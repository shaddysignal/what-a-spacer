extends MultiplayerSpawner

const character_scene = preload("res://scenes/character_body.tscn")

@onready var log_ref = Log.create("Trace", get_path())

func _ready() -> void:
	spawn_function = _spawn_player

func _spawn_player(data: Array) -> Player:
	var owner_id = data[0]

	log_ref.trace("Init player with %s id" % owner_id)

	var unpacked: Player = character_scene.instantiate()
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
		log_ref.trace("Found pod %s and it has bodies in it. Awaiting..." % pod_index)
		await get_tree().create_timer(1).timeout
		return await _find_pod(pods)
	else:
		log_ref.trace("Found pod %s and its empty" % pod_index)
		return spawn_point
