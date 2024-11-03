use godot::classes::{Area2D, PathFollow2D};
use godot::global::{maxf, minf};
use godot::obj::WithBaseField;
use godot::prelude::{godot_api, Base, Gd, GodotClass, INode2D, Node2D, OnReady};
use crate::logging::{Level, Log};

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
    #[init(val = OnReady::manual())]
    log_ref: OnReady<Gd<Log>>,
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

    fn ready(&mut self) {
        self.log_ref.init(Log::create(Level::Trace, self.base().get_path()));
    }
}

#[godot_api]
impl Door {
    #[func]
    fn area_entered(&mut self, obj: Gd<Node2D>) {
        self.log_ref.bind().trace(format!("Door detected {} entering", obj.get_path()));
        self.opening = true
    }
    
    #[func]
    fn area_exited(&mut self, obj: Gd<Node2D>) {
        self.log_ref.bind().trace(format!("Door detected {} leaving", obj.get_path()));
        
        let mut bodies = self.trigger_area.get_overlapping_bodies();
        bodies.erase(&obj);
        
        if bodies.is_empty() {
            self.opening = false   
        }
    }
}