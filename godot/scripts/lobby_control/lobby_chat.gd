extends VBoxContainer

@onready var chat_container = $ScrollContainer
@onready var chat_box = $ScrollContainer/Chat
@onready var chat_input = $Input/InputEdit

@onready var log_ref = Log.create("Trace", get_path())

var chat_item = preload("res://scenes/chat_item.tscn")

const tag = "[%s]: "

func _ready() -> void:
    SignalBus.game_message.connect(_on_game_message)
    Steam.lobby_message.connect(_on_chat_message)

func _on_input_edit_text_submitted(message_text: String) -> void:
    if message_text.length() > 0:
        var was_sent: bool = Steam.sendLobbyChatMsg(SteamNetwork.lobby_id, message_text)

        if not was_sent:
            log_ref.error("Chat message failed to send")

    chat_input.clear()

func _on_game_message(tag_text: String, message_text: String) -> void:
    var item = chat_item.instantiate()
    var tag_item = item.get_node("Tag") as Label
    var message_item = item.get_node("Message") as Label
    
    tag_item.text = tag % tag_text
    message_item.text = message_text
    
    chat_box.add_child(item)
    await get_tree().process_frame

    chat_container.ensure_control_visible(item)
    

func _on_chat_message(_lobby_id: int, user_id: int, message: String, _chat_type: int) -> void:
    var member_steam_name: String = Steam.getFriendPersonaName(user_id)

    _on_game_message(member_steam_name, message)
