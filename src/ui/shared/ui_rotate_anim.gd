extends Control

@export_category("Rotate")
@export var start_rotation: float = 0.0
@export var end_rotation: float = 45.0
@export var duration: float = 0.5
@export var easing: Tween.EaseType

func _ready() -> void:
    offset_transform_enabled = true

func play() -> void:
    var tween: Tween = create_tween()
    tween.tween_method(func(t: float) -> void: offset_transform_rotation = lerp_angle(start_rotation, end_rotation, t), 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func play_reverse() -> void:
    var tween: Tween = create_tween()
    tween.tween_method(func(t: float) -> void: offset_transform_rotation = lerp_angle(end_rotation, start_rotation, t), 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
