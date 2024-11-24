mod door;
mod player;
// mod loading_scene;
mod logging;
mod util;

use godot::prelude::*;

struct SpacersExtension;

#[gdextension]
unsafe impl ExtensionLibrary for SpacersExtension {}
