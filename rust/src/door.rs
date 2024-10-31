use godot::classes::{Area2D, PathFollow2D};
use godot::global::{maxf, minf};
use godot::prelude::{godot_api, Base, Gd, GodotClass, INode2D, Node2D, OnReady};

#[derive(GodotClass)]
#[class(init, base=Node2D)]
pub struct Door {
    #[export]
    #[init(val = 3f64)]
    speed: f64,
    #[init(node = "DoorPath/DoorPosition")]
    door_position: OnReady<Gd<PathFollow2D>>,
    #[init(node = "DetectionArea")]
    trigger_area: OnReady<Gd<Area2D>>,
    opening: bool,

    base: Base<Node2D>
}

#[godot_api]
impl INode2D for Door {
    fn physics_process(&mut self, delta: f64) {
        let progress = self.door_position.get_progress_ratio() as f64;

        if self.opening && progress != 1.0 {
            self.door_position
                .set_progress_ratio(minf(progress + self.speed * delta, 1.0f64) as f32)
        } else if !self.opening && progress != 0.0 {
            self.door_position
                .set_progress_ratio(maxf(progress - self.speed * delta, 0.0f64) as f32)
        }
    }
}

#[godot_api]
impl Door {
    #[func]
    fn area_entered(&mut self, _obj: Gd<Node2D>) {
        self.opening = true
    }
    
    #[func]
    fn area_exited(&mut self, _obj: Gd<Node2D>) {
        // TODO: not called after peer disconnect
        if !self.trigger_area.has_overlapping_bodies() {
            self.opening = false   
        }
    }
}