extends Node3D
class_name SpecialButton

const SCENE: PackedScene = preload("uid://dpm8p0r3ijute")

@onready var button: RedButton = %Button
@onready var anim: AnimationPlayer = %AnimationPlayer

enum SpecialButtons {
	GOLD,
	DIAMOND,
	RGB,
}

const SPECIAL_BUTTON_DATA: Dictionary[SpecialButtons, Dictionary] = {
	SpecialButtons.GOLD: {
		material = preload("uid://0g8o775l1hhq"),
		vignette = preload("uid://bbjk58jqke0s1"),
		multiplier = 2.0,
		clicks = 5.0
	},
	SpecialButtons.DIAMOND: {
		material = preload("uid://wotxjtf7ue1f"),
		vignette = preload("uid://ijott1tjoxpa"),
		multiplier = 5.0,
		clicks = 10.0
	},
	SpecialButtons.RGB: {
		material = preload("uid://7fi66yarpn82"),
		vignette = preload("uid://b6olrpf835n7u"),
		multiplier = 10.0,
		clicks = 20.0
	},
}

@export var button_type: SpecialButtons = SpecialButtons.GOLD
var button_data: Dictionary:
	get: return SPECIAL_BUTTON_DATA[button_type]

var enabled: bool = false
var clicks: int = 0

static var btn_count: int = 0

func _on_button_pressed() -> void:
	if not enabled: return
	button.value = 1 * button_data.multiplier
	Global.save_data.clicks += 1 * button_data.multiplier
	Main.instance.shake(0.2, 0.05)
	clicks += 1
	_update_vignette()
	if clicks >= button_data.clicks:
		enabled = false
		anim.play("disappear")
		
		btn_count -= 1
		if btn_count <= 0:
			UIEffects.instance.hide_vignette()
		await anim.animation_finished
		queue_free()

func _update_vignette() -> void:
	var v: Material = button_data.vignette
	UIEffects.instance.set_vignette(v)

func _ready() -> void:
	btn_count += 1
	button.material = button_data.material
	UIEffects.instance.show_vignette()
	_update_vignette()
	button.pressed.connect(_on_button_pressed)
	anim.play("appear")
	await anim.animation_finished
	enabled = true

static func create(type: SpecialButtons) -> SpecialButton:
	var sb: SpecialButton = SCENE.instantiate()
	sb.button_type = type
	return sb
