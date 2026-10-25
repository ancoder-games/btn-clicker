extends HSlider

const SOUND_DEBOUNCE_SECONDS: float = 0.2

var _sound_debounced: bool = false

func _ready() -> void:
	value_changed.connect(_on_value_changed)

func _on_value_changed(_value: float) -> void:
	if _sound_debounced:
		return

	UIService.play_slider()
	_sound_debounced = true
	await get_tree().create_timer(SOUND_DEBOUNCE_SECONDS).timeout
	_sound_debounced = false
