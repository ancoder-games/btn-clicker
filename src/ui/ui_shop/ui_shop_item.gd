extends HBoxContainer

@onready var item_name: Label = %ShopItemName
@onready var item_desc: Label = %ShopItemDescription
@onready var owned: Label = %Owned
@onready var icon: TextureRect = %Icon

@export var item: ShopItem

func _ready() -> void:
	if item == null: return
	icon.texture = item.icon
	item_name.text = item.name
	item_desc.text = item.desc
