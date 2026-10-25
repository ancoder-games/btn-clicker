extends Node

@onready var hover_sound: AudioStreamPlayer = %HoverSound
@onready var click_sound: AudioStreamPlayer = %ClickSound
@onready var slider_sound: AudioStreamPlayer = %SliderSound

func play_hover() -> void:
	hover_sound.play()

func play_click() -> void:
	click_sound.play()

func play_slider() -> void:
	slider_sound.play()
