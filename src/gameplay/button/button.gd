@tool
extends Node3D
class_name RedButton

const VALUE_PARTICLE_SCENE: PackedScene = preload("uid://cawdlct1o0i5q")
const VALUE_PARTICLE_POOL_SIZE: int = 8

signal pressed

#region Dependencies
@onready var click_area: Area3D = %ClickArea
@onready var anim: AnimationPlayer = %AnimationPlayer

@export_category("Visuals")
@export var material: Material:
	set(value): material = value; if is_node_ready(): button_mesh.material_override = value
@export var value: float = 0.0

@export_category("References")
@export var button_mesh: MeshInstance3D
@export var base_mesh: MeshInstance3D
#endregion

var is_hovering: bool = false
var press_tween: Tween
var value_particle_pool: Array[GPUParticles3D] = []

#region Private Methods
func _ready() -> void:
	button_mesh.material_override = material
	if Engine.is_editor_hint(): return
	_create_value_particle_pool()
	click_area.mouse_entered.connect(_on_mouse_entered)
	click_area.mouse_exited.connect(_on_mouse_exited)

func _create_value_particle_pool() -> void:
	for _index: int in VALUE_PARTICLE_POOL_SIZE:
		var particle: GPUParticles3D = VALUE_PARTICLE_SCENE.instantiate() as GPUParticles3D
		particle.emitting = false
		particle.finished.connect(_on_value_particle_finished.bind(particle))
		add_child(particle)
		value_particle_pool.append(particle)

func _emit_value_particle(pos: Vector3, p_value: float = 0.0) -> void:
	for particle: GPUParticles3D in value_particle_pool:
		if particle.emitting: continue
		particle.global_position = pos
		var text_mesh: TextMesh = particle.draw_pass_1 as TextMesh
		if text_mesh != null:
			text_mesh.text = "+$" + Utils.pretty_print_num(absf(p_value))
		particle.restart()
		particle.emitting = true
		return

func _on_value_particle_finished(particle: GPUParticles3D) -> void:
	particle.emitting = false

func _get_mouse_click_position() -> Vector3:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null: return global_position

	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_end: Vector3 = ray_origin + camera.project_ray_normal(mouse_position) * 1000.0
	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	ray_query.collide_with_areas = true
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray_query)
	return hit.get("position", global_position)

func _on_mouse_entered() -> void:
	is_hovering = true

func _on_mouse_exited() -> void:
	is_hovering = false

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	if Input.is_action_just_pressed("click") and is_hovering:
		_on_pressed()

func _on_pressed() -> void:
	pressed.emit()
	anim.stop()
	anim.play("press")
	_emit_value_particle(_get_mouse_click_position(), value)

#endregion

## Trigger the button pressing, signal pressed is emitted.
func press() -> void:
	_on_pressed()
