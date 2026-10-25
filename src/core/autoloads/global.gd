extends Node

var save_data: SaveData

func _enter_tree() -> void:
    save_data = SaveData.from_base64("")