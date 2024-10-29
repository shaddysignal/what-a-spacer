use godot::classes::{CharacterBody2D, ICharacterBody2D, InputEvent, MultiplayerSynchronizer, NavigationAgent2D};
use godot::obj::{OnReady, WithBaseField};
use godot::prelude::{godot_api, Base, Camera2D, Gd, GodotClass, NodePath, ToGodot, Var, Vector2};

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

    fn ready(&mut self) {
        self.navigation_agent.set_path_desired_distance(4.0f32);
        self.navigation_agent.set_target_desired_distance(4.0f32);
        
        if self.base().is_multiplayer_authority() {
            self.camera.make_current();
        }
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

}