extends Node

func _ready() -> void:
    pass

func queue_free_children(node: Node) -> void:
    for child in node.get_children():
        child.queue_free()

func await_sec(sec: float):
    await get_tree().create_timer(sec).timeout