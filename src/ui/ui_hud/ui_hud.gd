extends CanvasLayer

@onready var clicks_display: Label = %ClicksDisplay
@onready var clicks_display_anim: AnimationPlayer = %ClicksDisplayAnim

func _on_clicks_changed(clicks: float) -> void:
	clicks_display.text = Utils.pretty_print_num(floorf(clicks))
	clicks_display_anim.stop()
	clicks_display_anim.play("changed")

func _on_settings_pressed() -> void:
	UISettings.instance.open()

func _on_upgrade_pressed() -> void:
	UIUpgrades.instance.open()

func _on_shop_pressed() -> void:
	UIShop.instance.open()

func _on_ascend_pressed() -> void:
	UIAscend.instance.open()

func _ready() -> void:
	Global.save_data.clicks_changed.connect(_on_clicks_changed)
