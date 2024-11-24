use std::os::linux::raw::stat;
use crate::loading_scene::private::SealedState;
use godot::classes::{Control, IControl, Label, ProgressBar, ResourceLoader};
use godot::classes::resource_loader::ThreadLoadStatus;
use godot::obj::WithBaseField;
use godot::prelude::{godot_api, Base, Gd, GodotClass, Node, OnReady, Signal, VariantArray};

mod private {
    use crate::loading_scene::Load;

    pub trait SealedState {
        fn process(&mut self) -> Box<dyn SealedState>;

        fn update(&mut self, next_state: Box<dyn SealedState>);
    }

    impl Default for Box<dyn SealedState> {
        fn default() -> Self {
            Box::new(Load {})
        }
    }
}

const MAIN_MENU_SCENE_PATH: &str = "res://scenes/main_menu.tscn";

struct Load {
    target_scene_path: String,
    target_scene_node: Option<Gd<Node>>,
    progress_bar: Gd<ProgressBar>,
}
impl SealedState for Load {
    fn process(&mut self) -> Box<dyn SealedState> {
        let progress = VariantArray::new();
        let status_ex = ResourceLoader::singleton().load_threaded_get_status_ex(self.target_scene_path.clone().into());
        let status = status_ex.progress(progress).done();

        match status {
            ThreadLoadStatus::IN_PROGRESS => {
                self.progress_bar.set_value(progress.at(0).into() * 100f64);
                Box::new(self)
            }
            ThreadLoadStatus::LOADED => {
                self.progress_bar.set_value(100f64);
                self.target_scene_node = ResourceLoader::singleton().load_threaded_get(self.target_scene_path.clone().into());
                
                Box::new(Wait {})
            }
            ThreadLoadStatus::FAILED => {

            }
        }
    }

    fn update(&mut self, next_state: Box<dyn SealedState>) {
        match next_state {
            Wait => {}
            Done => {}
        }
    }
}
struct Wait {}
impl SealedState for Wait {
    fn process(&mut self) {
        todo!()
    }

    fn update(&mut self, next_state: Box<dyn SealedState>) {
        todo!()
    }
}
struct Done {}
impl SealedState for Done {
    fn process(&mut self) {
        todo!()
    }

    fn update(&mut self, next_state: Box<dyn SealedState>) {
        todo!()
    }
}
struct Fail {}
impl SealedState for Fail {
    fn process(&mut self) -> Box<dyn SealedState> {
        todo!()
    }

    fn update(&mut self, next_state: Box<dyn SealedState>) {
        todo!()
    }
}

#[derive(GodotClass)]
#[class(init, base=Control)]
pub struct LoadingScene {
    target_scene_path: String,
    signal_handle: Option<Signal>,
    message: Option<String>,

    loading_status: i64,
    progress: f64,
    current_state: Box<dyn SealedState>,
    signal_reached: bool,

    #[init(node = "WaitingContainer/LoadingBar")]
    progress_bar: OnReady<Gd<ProgressBar>>,
    #[init(node = "WaitingContainer/MessageLabel")]
    label: OnReady<Gd<Label>>,

    base: Base<Control>
}

#[godot_api]
impl IControl for LoadingScene {

    // TODO: finish translating this from gdscript
    fn ready(&mut self) {
        if let Some(handle) = &self.signal_handle {
            handle.connect(self.base().callable("on_signal_reached"), 0);
            self.label.set_text(self.message.clone().unwrap().into())
        }

        ResourceLoader::singleton().load_threaded_request(self.target_scene_path.clone().into());
    }

    fn process(&mut self, _delta: f64) {
        self.current_state.process()
    }

}

#[godot_api]
impl LoadingScene {

    #[func]
    fn on_signal_reached(&mut self) {
        self.signal_reached = true;
    }

}