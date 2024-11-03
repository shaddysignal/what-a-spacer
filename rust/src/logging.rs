use crate::ordered_string_enum;
use chrono::prelude::Utc;
use godot::global::godot_print;
use godot::prelude::{godot_api, GString, Gd, GodotClass, GodotConvert, IRefCounted, NodePath};

ordered_string_enum! {
    enum Level default Trace {
        Error = "ERROR",
        Warn = "WARN",
        Info = "INFO",
        Debug = "DEBUG",
        Trace = "TRACE"
    }
}

static mut GLOBAL_LEVEL: Level = Level::Trace;

#[derive(GodotClass)]
#[class(init)]
pub struct Log {
    max_level: Level,
    path: NodePath
}

#[godot_api]
impl IRefCounted for Log {
    
}

#[godot_api]
impl Log {

    #[func]
    pub fn create(level: Level, path: NodePath) -> Gd<Self> {
        Gd::from_object(Log {
            max_level: level,
            path,
        })
    }

    #[func]
    pub fn global_info(level: Level, message: String) {
        unsafe {
            Log::write(&GLOBAL_LEVEL, &level, message, "PLACE WITHOUTH PATH".to_string())
        }
    }
    
    #[func]
    pub fn global_level_update(new_level: Level) {
        unsafe {
            GLOBAL_LEVEL = new_level
        }
    }
    
    #[func]
    pub fn info(&self, message: String) {
        Log::write(&self.max_level, &Level::Info, message, self.path.to_string());
    }

    #[func]
    pub fn warn(&self, message: String) {
        Log::write(&self.max_level, &Level::Warn, message, self.path.to_string());
    }

    #[func]
    pub fn error(&self, message: String) {
        Log::write(&self.max_level, &Level::Error, message, self.path.to_string());
    }

    #[func]
    pub fn trace(&self, message: String) {
        Log::write(&self.max_level, &Level::Trace, message, self.path.to_string());
    }

    #[func]
    pub fn debug(&self, message: String) {
        Log::write(&self.max_level, &Level::Debug, message, self.path.to_string());
    }

    fn write(max_level: &Level, level: &Level, message: String, path: String) {
        if max_level >= level {
            godot_print!(
                "{} {:<5} [{}] {}",
                Utc::now().format("%Y-%m-%d %H:%M:%S,%3f"),
                level,
                path,
                message
            );
        }
    }

}