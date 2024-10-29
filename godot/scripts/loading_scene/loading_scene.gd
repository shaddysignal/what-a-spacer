extends Panel

enum State {
	LOAD, WAIT, DONE
}

var target_scene_path
var signal_handle = null
var message = null

var target_scene_node

var loading_status: int
var progress: Array[float]
var current_state = State.LOAD
var signal_reached = false

@onready var log_ref = Log.create("Trace", get_path())

@onready var progress_bar: ProgressBar = $Control/WaitingContainer/LoadingBar
@onready var label: Label = $Control/WaitingContainer/MessageLabel

func _ready() -> void:
	if signal_handle:
		signal_handle.connect(_on_signal_reached)
		label.text = message

	ResourceLoader.load_threaded_request(target_scene_path)
	
func _process(_delta: float) -> void:
	# TODO: fucking hate this match shit
	match current_state:
		State.LOAD:
			_on_load_state()
		State.WAIT:
			_on_wait_state()
		State.DONE:
			_on_done_state()

func _on_load_state():
	loading_status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
	
	match loading_status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			progress_bar.value = progress[0] * 100
		ResourceLoader.THREAD_LOAD_LOADED:
			current_state = State.WAIT
			progress_bar.value = 100
		ResourceLoader.THREAD_LOAD_FAILED:
			log_ref.error("Could not load %s" % target_scene_path)
			SceneAuthority.with_path("res://scenes/main_menu.tscn")

func _on_wait_state():
	# TODO: every frame is okay?
	label.visible = true

	if !signal_handle || signal_reached:
		current_state = State.DONE

func _on_done_state():
	SceneAuthority.with_packed(ResourceLoader.load_threaded_get(target_scene_path))

func _on_signal_reached():
	signal_reached = true
