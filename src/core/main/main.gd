extends Node
class_name Main

@onready var button: RedButton = %Button
@onready var camera: Camera3D = %Camera3D
@onready var sb_container: Node3D = %SpecialButtons
@onready var sb_spawn_area: Control = %SpecialButtonSpawnArea

static var instance: Main

var camera_origin_rotation: Vector3
var camera_origin_position: Vector3
var shake_time: float = 0.0

var shake_duration: float = 0.5
var shake_strength: float = 0.01

func _on_button_pressed() -> void:
	button.value = 1
	Global.save_data.clicks += 1
	shake(0.1, 0.005)
	_spawn_special_button()

func shake(duration: float, strength: float) -> void:
	shake_time = duration
	shake_duration = duration
	shake_strength = strength

func _ready() -> void:
	instance = self
	camera_origin_rotation = camera.rotation
	camera_origin_position = camera.position
	button.pressed.connect(_on_button_pressed)

func _process(delta: float) -> void:
	if shake_time > 0.0:
		shake_time = maxf(shake_time - delta, 0.0)
		var intensity: float = shake_time / shake_duration
		camera.rotation = camera_origin_rotation
		camera.rotation.z += randf_range(-1.0, 1.0) * shake_strength * intensity
		camera.position = camera_origin_position + Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * shake_strength * 5.0 * intensity
	else:
		camera.rotation = camera_origin_rotation
		camera.position = camera_origin_position

#region SpecialButtons

func _spawn_special_button() -> void:
	var _type: Variant = [SpecialButton.SpecialButtons.RGB, SpecialButton.SpecialButtons.DIAMOND, SpecialButton.SpecialButtons.GOLD, null, null, null, null, null, null, null].pick_random()
	if not _type: return # TODO: Fix
	var type: SpecialButton.SpecialButtons = _type
	var sb: SpecialButton = SpecialButton.create(type)
	sb_container.add_child(sb)
	var spawn_rect: Rect2 = sb_spawn_area.get_global_rect()
	var center: Vector2 = sb_spawn_area.position + (sb_spawn_area.size / 2)
	var point: Vector2 = Vector2(
		_get_edge_skewed_coordinate(
			spawn_rect.position.x,
			spawn_rect.end.x,
			center.x
		),
		_get_edge_skewed_coordinate(
			spawn_rect.position.y,
			spawn_rect.end.y,
			center.y
		)
	)
	sb.global_position = camera.project_position(point, 2.0)

func _get_edge_skewed_coordinate(minimum: float, maximum: float, center: float) -> float:
	var distance_to_minimum: float = maxf(center - minimum, 0.0)
	var distance_to_maximum: float = maxf(maximum - center, 0.0)
	var total_distance: float = distance_to_minimum + distance_to_maximum
	if is_zero_approx(total_distance):
		return randf_range(minimum, maximum)

	var minimum_probability: float = distance_to_minimum / total_distance
	if randf() < minimum_probability:
		return clampf(center - sqrt(randf()) * distance_to_minimum, minimum, maximum)
	return clampf(center + sqrt(randf()) * distance_to_maximum, minimum, maximum)

#endregion
