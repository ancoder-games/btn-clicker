extends Control

@export_category("Scale")
@export var start_scale: Vector2 = Vector2(1.0, 1.0)
@export var end_scale: Vector2 = Vector2(1.2, 1.2)
@export var duration: float = 0.5

func _ready() -> void:
	offset_transform_enabled = true

func play() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "offset_transform_scale", end_scale, duration).from(start_scale).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func play_reverse() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "offset_transform_scale", start_scale, duration).from(end_scale).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
