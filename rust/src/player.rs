use crate::logging::Level;
use crate::logging::Log;
use godot::classes::{CharacterBody2D, ICharacterBody2D, InputEvent, NavigationAgent2D};
use godot::obj::{OnReady, WithBaseField};
use godot::prelude::{godot_api, Base, Camera2D, Gd, GodotClass, Vector2};
use std::convert::Into;

#[derive(GodotClass)]
#[class(init, base=CharacterBody2D)]
pub struct Player {
    #[export]
    #[init(val = 25f32)]
    speed: f32,
    #[init(node = "NavigationAgent")]
    navigation_agent: OnReady<Gd<NavigationAgent2D>>,
    #[init(node = "Camera2D")]
    camera: OnReady<Gd<Camera2D>>,
    #[init(val = OnReady::manual())]
    log_ref: OnReady<Gd<Log>>,

    base: Base<CharacterBody2D>
}

#[godot_api]
impl ICharacterBody2D for Player {
    fn physics_process(&mut self, _delta: f64) {
        if self.navigation_agent.is_navigation_finished() {
            return;
        }

        let current_agent_position = self.base().get_global_position();
        let next_path_position = self.navigation_agent.get_next_path_position();
        let new_velocity = self.speed * current_agent_position.direction_to(next_path_position);

        self.base_mut().set_velocity(new_velocity);

        self.base_mut().move_and_slide();
    }
    
    fn enter_tree(&mut self) {
        Log::global_info(Level::Trace, "ENTER_TREE: character entered tree".to_string());
    }

    fn exit_tree(&mut self) {
        Log::global_info(Level::Trace, "EXIT_TREE: character exit tree".to_string());
    }

    fn ready(&mut self) {
        self.log_ref.init(Log::create(Level::Trace, self.base().get_path()));

        self.navigation_agent.set_path_desired_distance(4.0f32);
        self.navigation_agent.set_target_desired_distance(4.0f32);
    }
    
    fn unhandled_input(&mut self, event: Gd<InputEvent>) {
        if event.is_action_pressed("ui_mouse".into()) && self.base().is_multiplayer_authority() {
            let click_position = self.base().get_global_mouse_position();
            self.set_movement_target(click_position);
            // self.base_mut().rpc("set_movement_target".into(), &[click_position.to_variant()]);
        }
    }
}

#[godot_api]
impl Player {

    #[func]
    // #[rpc(any_peer, unreliable_ordered, call_local, channel = 0)]
    fn set_movement_target(&mut self, movement_target: Vector2) {
        self.navigation_agent.set_target_position(movement_target);
    }

    #[func]
    pub fn camera_setup(&mut self) {
        self.camera.set_enabled(true);
        self.camera.make_current();
    }
    
}