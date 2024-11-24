Building
---------------

1. Follow godot editor build [here](https://godotsteam.com/howto/multiplayer_peer/). Use msvc as build tool if on windows.
2. Install rust and build `./rust`. (If platform windows, should change `./godot/Spacers.gdextension`. `windows.*.x86_64` lines should point to new `spacers.dll`)
3. Run custom godot editor, load project from `./godot`, reload. Should be possible to run
4. Run steam, so project can run without problem
