@tool
extends PanelContainer

@onready var upgrade_name_label: Label = %UpgradeName
@onready var upgrade_button: Button = %Upgrade
@onready var upgrade_desc_label: Label = %UpgradeDesc
@onready var upgrade_icon_texture: TextureRect = %UpgradeIcon

@export var upgrade_name: String = "Broken":
	set(value): upgrade_name = value; update()
@export var upgrade_desc: String = "Description":
	set(value): upgrade_desc = value; update()
@export var upgrade_price: float = NAN:
	set(value): upgrade_price = value; update()
@export var upgrade_icon: Texture:
	set(value): upgrade_icon = value; update()

func _ready() -> void:
	update()

func update() -> void:
	if not is_node_ready(): return
	upgrade_name_label.text = upgrade_name
	upgrade_desc_label.text = upgrade_desc
	if not Engine.is_editor_hint():
		upgrade_button.text = "$" + Utils.pretty_print_num(upgrade_price)
	upgrade_icon_texture.texture = upgrade_icon
