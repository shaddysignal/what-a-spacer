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
    pub fn info(&self, message: String) {
        self.write(Level::Info, message);
    }

    #[func]
    pub fn warn(&self, message: String) {
        self.write(Level::Warn, message);
    }

    #[func]
    pub fn error(&self, message: String) {
        self.write(Level::Error, message);
    }

    #[func]
    pub fn trace(&self, message: String) {
        self.write(Level::Trace, message);
    }

    #[func]
    pub fn debug(&self, message: String) {
        self.write(Level::Debug, message);
    }

    fn write(&self, level: Level, message: String) {
        if self.max_level >= level {
            godot_print!(
                "{} {:<5} [{}] {}",
                Utc::now().format("%Y-%m-%d %H:%M:%S,%3f"),
                level,
                self.path,
                message
            );
        }
    }

}