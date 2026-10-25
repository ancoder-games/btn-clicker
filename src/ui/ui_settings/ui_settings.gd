extends CanvasLayer
class_name UISettings

#region Singleton
static var instance: UISettings

func _enter_tree() -> void:
	if is_instance_valid(instance):
		push_error("Singleton is found twice in scene tree.")
		queue_free()
	else:
		instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null
#endregion

@onready var anim: AnimationPlayer = %AnimationPlayer
@onready var master_volume_slider: HSlider = %MasterVolumeSlider
@onready var music_volume_slider: HSlider = %MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = %SFXVolumeSlider
@onready var ui_volume_slider: HSlider = %UIVolumeSlider

func _ready() -> void:
	## Load volumes from save
	master_volume_slider.value = Global.save_data.settings_master_volume * 100
	music_volume_slider.value = Global.save_data.settings_music_volume * 100
	sfx_volume_slider.value = Global.save_data.settings_sfx_volume * 100
	ui_volume_slider.value = Global.save_data.settings_ui_volume * 100

	## When settings change, save to save
	master_volume_slider.value_changed.connect(func(value: float) -> void: Global.save_data.settings_master_volume = value / 100)
	music_volume_slider.value_changed.connect(func(value: float) -> void: Global.save_data.settings_music_volume = value / 100)
	sfx_volume_slider.value_changed.connect(func(value: float) -> void: Global.save_data.settings_sfx_volume = value / 100)
	ui_volume_slider.value_changed.connect(func(value: float) -> void: Global.save_data.settings_ui_volume = value / 100)

	## Update volume when save changes
	Global.save_data.settings_master_volume_changed.connect(_update_volumes)
	Global.save_data.settings_music_volume_changed.connect(_update_volumes)
	Global.save_data.settings_sfx_volume_changed.connect(_update_volumes)
	Global.save_data.settings_ui_volume_changed.connect(_update_volumes)

	## Update volumes on load
	_update_volumes()

func _update_volumes() -> void:
	var master_bus_index: int = AudioServer.get_bus_index("Master")
	var music_bus_index: int = AudioServer.get_bus_index("Music")
	var sfx_bus_index: int = AudioServer.get_bus_index("SFX")
	var ui_bus_index: int = AudioServer.get_bus_index("UI")

	AudioServer.set_bus_volume_linear(master_bus_index, Global.save_data.settings_master_volume)
	AudioServer.set_bus_volume_linear(music_bus_index, Global.save_data.settings_music_volume)
	AudioServer.set_bus_volume_linear(sfx_bus_index, Global.save_data.settings_sfx_volume)
	AudioServer.set_bus_volume_linear(ui_bus_index, Global.save_data.settings_ui_volume)


func open() -> void:
	anim.play("open")

func close() -> void:
	anim.play("close")
