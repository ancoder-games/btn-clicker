extends CanvasLayer
class_name UIEffects

#region Singleton
static var instance: UIEffects

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

@onready var vignette: ColorRect = %Vignette

func set_vignette(mat: Material) -> void:
	vignette.material = mat

func show_vignette() -> void:
	vignette.show()

func hide_vignette() -> void:
	vignette.hide()