extends Node

const PACKET_READ_LIMIT: int = 32

signal lobby_ready
signal lobby_leave

@onready var log_ref = Log.create("Trace", get_path())

var peer: MultiplayerPeer

var lobby_data
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 10
var lobby_vote_kick: bool = false

func _init_peer() -> void:
	peer = SteamMultiplayerPeer.new()

	# GodotSteam peer
	peer.lobby_created.connect(_on_lobby_created) # after create request
	peer.lobby_data_update.connect(_on_lobby_data_update) # presumably metadata update
	# TODO: signal not fired ever?
	peer.lobby_joined.connect(func(_this_lobby_id: int, _permissions: int, _locked: bool, _response: int): log_ref.trace("lobby_joined: signal from peer"))
	# TODO: signal not fired ever?
	peer.lobby_chat_update.connect(func(_lobby_id: int, _changed_id: int, _making_change_id: int, _chat_state: int): log_ref.trace("lobby_chat_update: signal from peer")) # some changes to members happen
	# end

# TODO: sometimes network init seems to slow, so fast connect may brake stuff
func _ready() -> void:
	multiplayer.peer_connected.connect(func(id: int): log_ref.trace("PEER_CONNECTED: peer connected %s" % [id]))
	multiplayer.peer_disconnected.connect(func(id: int): log_ref.trace("PEER_DISCONNECTED: peer disconnected %s" % [id]))
	multiplayer.connected_to_server.connect(func(): log_ref.trace("CONNECTED_TO_SERVER: peer connected to server"))
	multiplayer.connection_failed.connect(func(): log_ref.trace("CONNECTION_FAILED: peer not able connected to server"))
	multiplayer.server_disconnected.connect(func(): log_ref.trace("SERVER_DISCONNECTED: peer disconnected from server"))

	Steam.lobby_invite.connect(_on_lobby_invite) # event when in game
	Steam.persona_state_change.connect(_on_persona_change) # some changes to a player
	Steam.join_requested.connect(_on_lobby_join_requested) # request to join from outside

	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_joined.connect(_on_lobby_joined)

	lobby_leave.connect(_on_lobby_leave)

	# Check for command line arguments
	check_command_line()

func _on_lobby_created(connect_success: int, this_lobby_id: int) -> void:
	if connect_success == 1:
		lobby_id = this_lobby_id
		log_ref.info("Created a lobby: %s" % lobby_id)
		
		Steam.setLobbyJoinable(lobby_id, true)

		var name_set = Steam.setLobbyData(lobby_id, "name", "Testing Lobby") # TODO: name?
		var mode_set = Steam.setLobbyData(lobby_id, "mode", "GodotStream Spacers Game Test")
		# Steam.setLobbyData(lobby_id, "pswd", "whatever") # TODO: check pass on join?

		if !name_set || !mode_set:
			log_ref.warn("Name or mode set failed (%s, %s)" % [name_set, mode_set])

		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		log_ref.trace("Allowing Steam to be relay backup: %s" % set_relay)
	else:
		# TODO: show error, return to menu
		pass

func _on_lobby_data_update(success: int, this_lobby_id: int, who_changed_id: int):
	if success == 1:
		log_ref.debug("Lobby data updated (%s)" % who_changed_id)
	else:
		log_ref.debug("Lobby data change unsuccessful")
	
	log_ref.trace("Lobby state:")
	log_ref.trace("Name: %s" % Steam.getLobbyData(this_lobby_id, "name"))
	log_ref.trace("Mode: %s" % Steam.getLobbyData(this_lobby_id, "mode"))


func _on_persona_change(this_steam_id: int, _flag: int) -> void:
	if lobby_id > 0:
		log_ref.trace("A user (%s) had information change, updating the lobby list" % this_steam_id)

		populate_lobby_members()

func _on_lobby_chat_update(_this_lobby_id: int, change_id: int, _making_change_id: int, chat_state: int) -> void:
	var changer_name: String = Steam.getFriendPersonaName(change_id)

	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		log_ref.info("LOBBY_CHAT_UPDATE: %s has joined the lobby." % changer_name)
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		log_ref.info("LOBBY_CHAT_UPDATE: %s has left the lobby." % changer_name)
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		log_ref.info("LOBBY_CHAT_UPDATE: %s has been kicked from the lobby." % changer_name)
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		log_ref.info("LOBBY_CHAT_UPDATE: %s has been banned from the lobby." % changer_name)

	# Else there was some unknown change
	else:
		log_ref.info("LOBBY_CHAT_UPDATE: %s did... something." % changer_name)

	populate_lobby_members()

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		populate_lobby_members()

		lobby_ready.emit() # signal when to move from waiting to main ???
	else:
		var fail_reason: String

		match response:
			Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: fail_reason = "This lobby no longer exists."
			Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: fail_reason = "You don't have permission to join this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: fail_reason = "The lobby is now full."
			Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: fail_reason = "Uh... something unexpected happened!"
			Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: fail_reason = "You are banned from this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: fail_reason = "You cannot join due to having a limited account."
			Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: fail_reason = "This lobby is locked or disabled."
			Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: fail_reason = "This lobby is community locked."
			Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: fail_reason = "A user in the lobby has blocked you from joining."
			Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: fail_reason = "A user you have blocked is in the lobby."

		log_ref.error("Failed to join this chat room: %s" % fail_reason)

		# TODO: show error and retry lobby list request
		#_on_lobby_list_request()

func _on_lobby_invite(_inviter_id: int, _that_lobby_id: int, _game_id: int) -> void:
	# popup about joining? then to waiting scene?
	pass

func _on_lobby_leave():
	leave_lobby()

func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
	var owner_name: String = Steam.getFriendPersonaName(friend_id)

	log_ref.info("Joining %s's lobby..." % owner_name)

	join_lobby_request(this_lobby_id)

### UTILS
func populate_lobby_members() -> void:
	log_ref.trace("repopulating lobby members for lobby %s" % lobby_id)
	lobby_members.clear()
	var num_of_members: int = Steam.getNumLobbyMembers(lobby_id)

	for this_member in range(0, num_of_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)

		lobby_members.append({"steam_id": member_steam_id, "steam_name": member_steam_name})

func create_lobby(type: Steam.LobbyType, max_members: int):
	log_ref.trace("Attempting to create lobby (%s, %s)" % [type, max_members])

	_init_peer()
	peer.create_lobby(type, max_members)

func join_lobby_request(this_lobby_id: int) -> void:
	log_ref.trace("Attempting to join lobby %s" % this_lobby_id)
	lobby_members.clear()

	_init_peer()
	peer.connect_lobby(this_lobby_id)

func tree_multiplayer_peer_setup():
	get_tree().root.multiplayer.multiplayer_peer = peer

func leave_lobby() -> void:
	if lobby_id != 0:
		log_ref.trace("Attempting to leave current lobby %s" % lobby_id)

		# TODO: clean peer packets?
		peer.close()
		Steam.leaveLobby(lobby_id)
		get_tree().root.multiplayer.multiplayer_peer = null

		lobby_id = 0

		for this_member in lobby_members:
			# Make sure this isn't your Steam ID
			if this_member['steam_id'] != SteamState.steam_id:
				Steam.closeP2PSessionWithUser(this_member['steam_id'])

		lobby_members.clear()

func check_command_line() -> void:
	var these_arguments: Array = OS.get_cmdline_args()

	# There are arguments to process
	if these_arguments.size() > 0:
		# A Steam connection argument exists
		if these_arguments[0] == "+connect_lobby":
			# Lobby invite exists so try to connect to it
			if int(these_arguments[1]) > 0:
				# At this point, you'll probably want to change scenes
				# Something like a loading into lobby screen
				log_ref.info("Command line lobby ID: %s" % these_arguments[1])
				join_lobby_request(int(these_arguments[1]))
