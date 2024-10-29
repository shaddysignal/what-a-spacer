extends Node

const waiting_scene_packed = preload("res://scenes/loading_scene.tscn")

func init_packed_scene(packed: PackedScene, values: Dictionary) -> Node:
	var unpacked = packed.instantiate()
	for key in values.keys():
		unpacked[key] = values[key]

	return unpacked

func with_packed(new_scene: PackedScene, params: Dictionary = {}):
	_scene_change(init_packed_scene(new_scene, params))

func with_path(new_scene_path: String, params: Dictionary = {}):
	var waiting_scene = init_packed_scene(
		waiting_scene_packed,
		params.merged({"target_scene_path": new_scene_path})
	)
	
	_scene_change(waiting_scene)

func _scene_change(new_scene_root: Node):
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(new_scene_root)
	get_tree().current_scene = new_scene_root

func scene_preload(new_scene: PackedScene, params: Dictionary = {}) -> Node:
	var new_scene_root = init_packed_scene(new_scene, params)
	get_tree().root.add_child(new_scene_root)

	return new_scene_root
