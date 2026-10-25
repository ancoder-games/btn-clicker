@tool
class_name RendererTool
extends SubViewport

## Captures this SubViewport exactly as configured and saves either one sprite
## or an animation spritesheet. Add any 2D, 3D, shader, or post-processing
## children needed for the desired style; this exporter applies no style itself.

signal export_started(frame_count: int)
signal export_progress(frame_index: int, frame_count: int)
signal export_completed(file_path: String, frame_count: int)
signal export_failed(message: String)
signal normal_map_exported(file_path: String)

const LOG_CONTEXT: String = "RendererTool"
const NORMAL_MAP_CLEAR_COLOR: Color = Color(0.5, 0.5, 1.0, 0.0)
const ANIMATION_PROPERTY_NAMES: Array[StringName] = [
	&"animation_player",
	&"animation_name",
	&"frames_per_second",
	&"start_frame",
	&"end_frame",
	&"spritesheet_columns",
	&"spritesheet_padding",
]
const NORMAL_MAP_PROPERTY_NAMES: Array[StringName] = [
	&"normal_map_output_path",
	&"normal_map_strength",
]

@export_category("Render Export")
## PNG file written by the exporter. Missing directories are created.
@export_file("*.png") var output_path: String = "res://renders/render.png"
@export_tool_button("Export Render", "Save")
var export_button: Callable = export_render

@export_group("Animation")
## When disabled, exports one sprite. When enabled, exports a spritesheet.
@export var render_animation: bool = false:
	set(value):
		render_animation = value
		notify_property_list_changed()
## AnimationPlayer sampled during an animated export.
@export var animation_player: AnimationPlayer:
	set(value):
		animation_player = value
		notify_property_list_changed()
## Animation sampled during export. The inspector lists animations from the player.
@export var animation_name: StringName = &""
@export_range(1, 120, 1, "or_greater") var frames_per_second: int = 12
## First animation frame to capture, inclusive.
@export_range(0, 100000, 1, "or_greater") var start_frame: int = 0
## Last frame to capture, inclusive. Use -1 for the animation's final frame.
@export_range(-1, 100000, 1, "or_greater") var end_frame: int = -1

@export_subgroup("Sprite Sheet")
## Frames per row. Use 0 to place every frame on one row.
@export_range(0, 1024, 1, "or_greater") var spritesheet_columns: int = 0
## Transparent pixels inserted between frames.
@export_range(0, 256, 1, "or_greater") var spritesheet_padding: int = 0

@export_group("Normal Map")
## Also exports a normal map generated from each captured frame's luminance.
@export var generate_normal_map: bool = false:
	set(value):
		generate_normal_map = value
		notify_property_list_changed()
## Optional PNG destination. Empty uses `<Output Path>_normal.png`.
@export_file("*.png") var normal_map_output_path: String = ""
## Surface depth applied while converting the captured sprite to normals.
@export_range(-32.0, 32.0, 0.05, "or_less", "or_greater")
var normal_map_strength: float = 1.0

@export_group("Capture")
## Rendered frames allowed to settle before each capture.
@export_range(1, 10, 1, "or_greater") var settle_frames: int = 2

var _is_exporting: bool = false


func _ready() -> void:
	if size.x <= 0 or size.y <= 0:
		Log.warn("%s requires a positive SubViewport size." % LOG_CONTEXT)


func _validate_property(property: Dictionary) -> void:
	var property_name: StringName = StringName(str(property.get("name", "")))
	if property_name in ANIMATION_PROPERTY_NAMES and not render_animation:
		property["usage"] = PROPERTY_USAGE_STORAGE
		return
	if property_name in NORMAL_MAP_PROPERTY_NAMES and not generate_normal_map:
		property["usage"] = PROPERTY_USAGE_STORAGE
		return

	if property_name == &"animation_name" and animation_player != null:
		property["hint"] = PROPERTY_HINT_ENUM
		property["hint_string"] = ",".join(animation_player.get_animation_list())


## Starts an editor-safe export. This method is also available to scripts.
func export_render() -> void:
	if _is_exporting:
		Log.warn("%s is already exporting." % LOG_CONTEXT)
		return
	if not is_inside_tree():
		_report_failure("%s must be inside the scene tree." % LOG_CONTEXT)
		return

	_run_export()


func _run_export() -> void:
	_is_exporting = true
	var settings_error: String = _get_settings_error()
	if not settings_error.is_empty():
		_report_failure(settings_error)
		return

	var previous_update_mode: SubViewport.UpdateMode = render_target_update_mode
	var expected_frame_count: int = _get_export_frame_count()
	var captured_frames: Array[Image] = []
	export_started.emit(expected_frame_count)

	if render_animation:
		captured_frames = await _capture_animation_frames()
	else:
		var image: Image = await _capture_frame()
		if image != null:
			captured_frames.append(image)
			export_progress.emit(1, 1)

	render_target_update_mode = previous_update_mode
	if captured_frames.size() != expected_frame_count:
		_report_failure(
			"Captured %d of %d expected frames."
			% [captured_frames.size(), expected_frame_count]
		)
		return

	var output_image: Image
	if render_animation:
		output_image = _build_spritesheet(captured_frames)
	else:
		output_image = captured_frames[0]
	if output_image == null:
		_report_failure("Could not build the output image.")
		return

	var normal_map_image: Image
	if generate_normal_map:
		normal_map_image = _build_normal_map_output(captured_frames)
		if normal_map_image == null:
			_report_failure("Could not build the normal map image.")
			return

	var saved_path: String = _save_image(output_image, output_path)
	if saved_path.is_empty():
		return
	var saved_normal_map_path: String = ""
	if generate_normal_map:
		saved_normal_map_path = _save_image(
			normal_map_image,
			_get_normal_map_output_path()
		)
		if saved_normal_map_path.is_empty():
			return
		normal_map_exported.emit(saved_normal_map_path)

	_is_exporting = false
	Log.info(
		"%s saved %d frame(s) to %s"
		% [LOG_CONTEXT, captured_frames.size(), saved_path]
	)
	if generate_normal_map:
		Log.info("%s saved a normal map to %s" % [LOG_CONTEXT, saved_normal_map_path])
	export_completed.emit(saved_path, captured_frames.size())


func _capture_animation_frames() -> Array[Image]:
	var captured_frames: Array[Image] = []
	var animation_state: AnimationState = _store_animation_state()
	var last_frame: int = _get_capture_end_frame()
	var frame_count: int = last_frame - start_frame + 1

	animation_player.play(animation_name)
	animation_player.pause()

	for frame_number: int in range(start_frame, last_frame + 1):
		var sample_time: float = minf(
			float(frame_number) / float(frames_per_second),
			animation_player.get_animation(animation_name).length
		)
		animation_player.seek(sample_time, true)
		animation_player.advance(0.0)

		var image: Image = await _capture_frame()
		if image == null:
			break
		captured_frames.append(image)
		export_progress.emit(captured_frames.size(), frame_count)

	_restore_animation_state(animation_state)
	return captured_frames


func _capture_frame() -> Image:
	render_target_update_mode = SubViewport.UPDATE_ONCE
	for _settle_index: int in range(settle_frames):
		await get_tree().process_frame
		render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw

	var viewport_texture: ViewportTexture = get_texture()
	if viewport_texture == null:
		return null
	var image: Image = viewport_texture.get_image()
	if image == null or image.is_empty():
		return null
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	return image


func _build_spritesheet(
	frames: Array[Image],
	clear_color: Color = Color.TRANSPARENT
) -> Image:
	if frames.is_empty():
		return null

	var frame_size: Vector2i = frames[0].get_size()
	for frame: Image in frames:
		if frame.get_size() != frame_size:
			Log.error("%s captured mismatched frame sizes." % LOG_CONTEXT)
			return null

	var columns: int = frames.size()
	if spritesheet_columns > 0:
		columns = mini(spritesheet_columns, frames.size())
	var rows: int = ceili(float(frames.size()) / float(columns))
	var sheet_size: Vector2i = Vector2i(
		frame_size.x * columns + spritesheet_padding * maxi(0, columns - 1),
		frame_size.y * rows + spritesheet_padding * maxi(0, rows - 1)
	)
	var spritesheet: Image = Image.create(
		sheet_size.x,
		sheet_size.y,
		false,
		Image.FORMAT_RGBA8
	)
	spritesheet.fill(clear_color)

	for frame_index: int in range(frames.size()):
		var column: int = frame_index % columns
		var row: int = floori(float(frame_index) / float(columns))
		var destination: Vector2i = Vector2i(
			column * (frame_size.x + spritesheet_padding),
			row * (frame_size.y + spritesheet_padding)
		)
		spritesheet.blit_rect(
			frames[frame_index],
			Rect2i(Vector2i.ZERO, frame_size),
			destination
		)

	return spritesheet


func _build_normal_map_output(frames: Array[Image]) -> Image:
	var normal_map_frames: Array[Image] = []
	for frame: Image in frames:
		normal_map_frames.append(_create_normal_map(frame))

	if render_animation:
		return _build_spritesheet(normal_map_frames, NORMAL_MAP_CLEAR_COLOR)
	return normal_map_frames[0]


func _create_normal_map(source: Image) -> Image:
	var source_size: Vector2i = source.get_size()
	var height_map: Image = Image.create(
		source_size.x,
		source_size.y,
		false,
		Image.FORMAT_L8
	)

	for y: int in range(source_size.y):
		for x: int in range(source_size.x):
			var source_pixel: Color = source.get_pixel(x, y)
			var height: float = source_pixel.get_luminance() * source_pixel.a
			height_map.set_pixel(x, y, Color(height, height, height))

	height_map.bump_map_to_normal_map(normal_map_strength)
	if height_map.get_format() != Image.FORMAT_RGBA8:
		height_map.convert(Image.FORMAT_RGBA8)

	for y: int in range(source_size.y):
		for x: int in range(source_size.x):
			var normal_pixel: Color = height_map.get_pixel(x, y)
			normal_pixel.a = source.get_pixel(x, y).a
			height_map.set_pixel(x, y, normal_pixel)

	return height_map


func _save_image(image: Image, file_path: String) -> String:
	var normalized_path: String = _get_normalized_png_path(file_path)
	var absolute_path: String = _get_absolute_path(normalized_path)
	var output_directory: String = absolute_path.get_base_dir()
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(
		output_directory
	)
	if directory_error != OK:
		_report_failure(
			"Could not create output directory '%s': %s"
			% [output_directory, error_string(directory_error)]
		)
		return ""

	var save_error: Error = image.save_png(absolute_path)
	if save_error != OK:
		_report_failure(
			"Could not save PNG '%s': %s"
			% [normalized_path, error_string(save_error)]
		)
		return ""

	if Engine.is_editor_hint() and normalized_path.begins_with("res://"):
		EditorInterface.get_resource_filesystem().scan()
	return normalized_path


func _get_settings_error() -> String:
	if size.x <= 0 or size.y <= 0:
		return "SubViewport size must be greater than zero."
	if output_path.strip_edges().is_empty():
		return "Output Path cannot be empty."
	if _get_normalized_output_path().is_empty():
		return "Output Path contains an unknown resource UID. Choose the file again."
	if (
		generate_normal_map
		and not normal_map_output_path.strip_edges().is_empty()
		and _get_normal_map_output_path().is_empty()
	):
		return "Normal Map Output Path contains an unknown resource UID. Choose the file again."
	if (
		generate_normal_map
		and _get_normalized_output_path() == _get_normal_map_output_path()
	):
		return "Normal Map Output Path must differ from Output Path."
	if not render_animation:
		return ""
	if animation_player == null:
		return "Animation Player is required for an animated export."
	if animation_name.is_empty():
		return "Animation Name is required for an animated export."
	if not animation_player.has_animation(animation_name):
		return "Animation '%s' does not exist on the selected player." % animation_name
	if start_frame > _get_animation_last_frame():
		return "Start Frame is beyond the end of the animation."
	if _get_capture_end_frame() < start_frame:
		return "End Frame must be greater than or equal to Start Frame."
	return ""


func _get_export_frame_count() -> int:
	if not render_animation:
		return 1
	return _get_capture_end_frame() - start_frame + 1


func _get_animation_last_frame() -> int:
	var animation: Animation = animation_player.get_animation(animation_name)
	var frame_count: int = maxi(
		1,
		ceili(animation.length * float(frames_per_second))
	)
	return frame_count - 1


func _get_capture_end_frame() -> int:
	var animation_last_frame: int = _get_animation_last_frame()
	if end_frame < 0:
		return animation_last_frame
	return mini(end_frame, animation_last_frame)


func _store_animation_state() -> AnimationState:
	var state: AnimationState = AnimationState.new()
	state.animation_name = StringName(animation_player.current_animation)
	state.position = animation_player.current_animation_position
	state.speed_scale = animation_player.speed_scale
	state.was_playing = animation_player.is_playing()
	return state


func _restore_animation_state(state: AnimationState) -> void:
	animation_player.speed_scale = state.speed_scale
	if state.animation_name.is_empty():
		animation_player.stop()
		return
	if not animation_player.has_animation(state.animation_name):
		animation_player.stop()
		return

	animation_player.play(state.animation_name)
	animation_player.seek(state.position, true)
	animation_player.advance(0.0)
	if not state.was_playing:
		animation_player.pause()


func _get_normalized_output_path() -> String:
	return _get_normalized_png_path(output_path)


func _get_normal_map_output_path() -> String:
	if not normal_map_output_path.strip_edges().is_empty():
		return _get_normalized_png_path(normal_map_output_path)
	return _get_normalized_output_path().get_basename() + "_normal.png"


func _get_normalized_png_path(file_path: String) -> String:
	var normalized_path: String = _resolve_file_path(file_path)
	if normalized_path.is_empty():
		return ""
	if normalized_path.get_extension().to_lower() != "png":
		normalized_path = normalized_path.get_basename() + ".png"
	return normalized_path


func _resolve_file_path(file_path: String) -> String:
	var normalized_path: String = file_path.strip_edges()
	if not normalized_path.begins_with("uid://"):
		return normalized_path

	var resource_id: int = ResourceUID.text_to_id(normalized_path)
	if resource_id < 0 or not ResourceUID.has_id(resource_id):
		return ""
	return ResourceUID.get_id_path(resource_id)


func _get_absolute_path(file_path: String) -> String:
	if file_path.begins_with("res://") or file_path.begins_with("user://"):
		return ProjectSettings.globalize_path(file_path)
	if file_path.is_absolute_path():
		return file_path
	return ProjectSettings.globalize_path("res://" + file_path.trim_prefix("./"))


func _report_failure(message: String) -> void:
	_is_exporting = false
	Log.error(message)
	export_failed.emit(message)


class AnimationState:
	var animation_name: StringName = &""
	var position: float = 0.0
	var speed_scale: float = 1.0
	var was_playing: bool = false
