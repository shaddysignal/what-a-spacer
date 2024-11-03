extends Node

const log_level = "Trace"

func _ready() -> void:
    Log.global_level_update(log_level)

func queue_free_children(node: Node) -> void:
    for child in node.get_children():
        child.queue_free()

func await_sec(sec: float):
    await get_tree().create_timer(sec).timeout