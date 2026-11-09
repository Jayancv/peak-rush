# Peak Rush

A cozy 2D side-scrolling hiking game for Android and iOS, built with Godot.

- Design: [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md)
- Roadmap: [`docs/PLAN.md`](docs/PLAN.md)
- Working with Claude Code: [`CLAUDE.md`](CLAUDE.md)

## Requirements
- **Godot 4.7.2-stable** (standard build, GDScript; .NET isn't needed)
- GUT 9.7.1 (bundled in `addons/gut/`)

In the commands below, `godot` means your Godot 4.7.2 executable (on Windows, use the
`_console.exe` build so output shows in the terminal).

## Run
```bash
# First time after cloning (rebuilds the .godot/ cache and imports assets)
godot --headless --path . --import

# Play
godot --path .
```
Desktop controls: **D / Right** = walk, **Space / W / Up** = jump, **Esc** = pause/back.
The mouse emulates touch.

## Tests
```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```
A run is green only if it ends with `All tests passed!` and the output has no
`SCRIPT ERROR`, `Parse Error` or `Failed to load` lines. (The `SceneRouter: scene not found` error
line is expected, because a test triggers it on purpose.)

You can also run the tests in the editor from the **GUT** panel at the bottom.
