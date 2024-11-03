extends MultiplayerSpawner

const character_scene = preload("res://scenes/character_body.tscn")

@onready var log_ref = Log.create("Trace", get_path())

func _ready() -> void:
	spawn_function = _spawn_player

func _spawn_player(data: Array) -> Player:
	var owner_id = data[0]
	var position = data[1]

	log_ref.trace("Init player with %s id" % owner_id)

	var unpacked = character_scene.instantiate()
	unpacked.set_multiplayer_authority(owner_id)
	unpacked.global_position = position

	return unpacked

func _enter_tree() -> void:
	Log.global_info("Trace", "ENTER_TREE: spawner enter tree")

func _exit_tree() -> void:
	Log.global_info("Trace", "EXIT_TREE: spawner exit tree")
