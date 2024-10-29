use godot::classes::{CenterContainer, ICenterContainer, Label, ProgressBar, ResourceLoader};
use godot::obj::WithBaseField;
use godot::prelude::{godot_api, Base, Callable, Gd, GodotClass, OnReady, Signal};

#[derive(Default)]
enum State {
    #[default]
    Load,
    Wait,
    Done
}

const MAIN_MENU_SCENE_PATH: &str = "res://scenes/main_menu.tscn";

#[derive(GodotClass)]
#[class(init, base=CenterContainer)]
pub struct LoadingScene {
    target_scene_path: String,
    signal_handle: Option<Signal>,
    message: Option<String>,

    loading_status: i64,
    progress: f64,
    current_state: State,
    signal_reached: bool,

    #[init(node = "WaitingContainer/LoadingBar")]
    progress_bar: OnReady<Gd<ProgressBar>>,
    #[init(node = "WaitingContainer/MessageLabel")]
    label: OnReady<Gd<Label>>,

    base: Base<CenterContainer>
}

#[godot_api]
impl ICenterContainer for LoadingScene {

    // TODO: finish translating this from gdscript
    fn ready(&mut self) {
        if let Some(handle) = &self.signal_handle {
            handle.connect(self.base().callable("on_signal_reached"), 0);
            self.label.set_text(self.message.clone().unwrap().into())
        }

        ResourceLoader::singleton().load_threaded_request(self.target_scene_path.clone().into());
    }

    fn process(&mut self, _delta: f64) {

    }

}

#[godot_api]
impl LoadingScene {

    #[func]
    fn on_signal_reached(&mut self) {
        self.signal_reached = true;
    }

}