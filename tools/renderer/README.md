# Viewport Render Exporter

`renderer.tscn` is a style-agnostic `SubViewport` that exports its rendered
contents to PNG. It does not add pixelation, shaders, lighting, cameras, or any
other visual treatment.

## Usage

1. Add `renderer.tscn` to a scene or inherit from it.
2. Add the content, cameras, lights, world/environment, UI, shaders, and
   post-processing effects you want as children of the renderer.
3. Set the inherited `SubViewport` **Size** to the desired frame resolution.
4. Set **Output Path** to the destination PNG.
5. Select the renderer and press **Export Render** in the Inspector.

If the Godot file selector stores a selected resource as a `uid://` reference,
the exporter resolves it back to its project path before saving. Unknown or
stale UIDs are rejected with a validation message.

With **Render Animation** disabled, the output is one sprite. With it enabled,
assign an `AnimationPlayer`, select an animation, then configure FPS and the
inclusive frame range. The output is one spritesheet. `End Frame = -1` captures
through the animation's final frame.

`Spritesheet Columns = 0` creates one horizontal row. Set a positive column
count to wrap frames into multiple rows. `Spritesheet Padding` inserts
transparent space between cells.

Enable **Generate Normal Map** to export a normal texture beside the sprite.
Each frame is converted from its alpha-weighted luminance, using **Normal Map
Strength** to control the depth. Animated normal maps use the same frame order,
columns, and padding as the color spritesheet. Leave **Normal Map Output Path**
empty to derive it from the color output (`unit.png` becomes
`unit_normal.png`), or set a separate PNG path explicitly.

The exporter restores the selected `AnimationPlayer` after capture. Export
progress and results are available through `export_started`, `export_progress`,
`export_completed`, `normal_map_exported`, and `export_failed` signals.
