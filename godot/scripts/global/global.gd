extends Node

func _ready() -> void:
    pass

func queue_free_children(node: Node) -> void:
    for child in node.get_children():
        child.queue_free()