extends VBoxContainer

@onready var search_button = $LobbyFilterSearch/Search
@onready var lobby_name_input = $LobbyFilterSearch/LobbyFilter
@onready var lobby_container = $ScrollContainer/LobbiesContainer
@onready var waiting_node = $ScrollContainer/WaitingNode

@onready var log_ref = Log.create("Trace", get_path())

var lobby_item_scene = preload("res://scenes/lobby_item.tscn")

func _ready() -> void:
    Steam.lobby_match_list.connect(_on_lobby_match_find)

func _on_lobby_list_request() -> void:
    log_ref.debug("Requesting lobby list")
    waiting_node.visible = true

    Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
    Steam.addRequestLobbyListStringFilter("mode", "GodotStream Spacers Game Test", Steam.LOBBY_COMPARISON_EQUAL)
    # TODO: password protected?

    Steam.requestLobbyList()

func _on_lobby_match_find(these_lobbies: Array) -> void:
    Global.queue_free_children(lobby_container)

    var lobby_name_partial = lobby_name_input.text
    waiting_node.visible = false

    # TODO: There will be all the lobbies, all possible billion of them. What should be there?
    for this_lobby in these_lobbies:
        var lobby_name = Steam.getLobbyData(this_lobby, "name")

        log_ref.trace("Found lobby info (%s, %s, %s)" % [this_lobby, lobby_name, Steam.getLobbyData(this_lobby, "mode")])

        var lobby_num_members = Steam.getNumLobbyMembers(this_lobby)
        var lobby_max_num_members = Steam.getLobbyMemberLimit(this_lobby)

        var lobby_item = lobby_item_scene.instantiate()
        var lobby_item_name: Label = lobby_item.get_node("Name")
        var lobby_item_availability: Label = lobby_item.get_node("Availability")
        var lobby_item_connect: Button = lobby_item.get_node("Connect")
        
        lobby_item_name.text = "%s (%s)" % [lobby_name, this_lobby]
        lobby_item_availability.text = "%s/%s" % [lobby_num_members, lobby_max_num_members]
        lobby_item_connect.connect("pressed", _on_connect.bind(this_lobby))

        # Add the new lobby to the list
        lobby_container.add_child(lobby_item)

    filter_lobby_list(lobby_name_partial)

func _on_connect(this_lobby: int):
    SteamNetwork.join_lobby_request(this_lobby)
    
    SceneAuthority.with_path(
        "res://scenes/main.tscn",
        {
            "signal_handle": multiplayer.connected_to_server,
            "message": "Waiting for connection..."
        }
    )

func _on_lobby_filter_submitted(_lobby_name: String) -> void:
    _on_lobby_list_request()

func _on_lobby_filter_changed(lobby_filter: String) -> void:
    filter_lobby_list(lobby_filter)

func filter_lobby_list(lobby_name: String):
    for lobby_item in lobby_container.get_children():
        lobby_item.visible = true

        var text: String = lobby_item.get_node("Name").text
        if !text.to_upper().begins_with(lobby_name.to_upper()):
            lobby_item.visible = false
