extends BaseButton

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)

func _on_mouse_entered() -> void:
	UIService.play_hover()

func _on_mouse_exited() -> void:
	UIService.play_hover()

func _on_pressed() -> void:
	UIService.play_click()