extends CanvasLayer
class_name UIUpgrades

#region Singleton
static var instance: UIUpgrades

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

func open() -> void:
	anim.play("open")

func close() -> void:
	anim.play("close")