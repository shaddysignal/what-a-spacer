extends Node

# Steam variables
var is_on_steam_deck: bool = false
var is_online: bool = false
var is_owned: bool = false
var steam_app_id: int = 480
var steam_id: int = 0
var steam_username: String = ""

@onready var log_ref = Log.create("Trace", get_path())

func _init() -> void:
	pass
	
func _ready() -> void:
	initialize_steam()


func _process(_delta: float) -> void:
	Steam.run_callbacks()


func initialize_steam() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx(true, steam_app_id)
	log_ref.info("Did Steam initialize?: %s" % initialize_response)

	if initialize_response['status'] > 0:
		log_ref.error("Failed to initialize Steam. Shutting down. %s" % initialize_response)
		get_tree().quit()

	# Gather additional data
	is_on_steam_deck = Steam.isSteamRunningOnSteamDeck()
	is_online = Steam.loggedOn()
	is_owned = Steam.isSubscribed()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()

	# Check if account owns the game
	if is_owned == false:
		log_ref.warn("User does not own this game")
