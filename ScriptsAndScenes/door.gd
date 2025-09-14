extends Area3D
class_name Door

const DELAY_TIME := 0.5
@onready var finish_lvl_delay: Timer = $FinishLvlDelay


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		finish_lvl_delay.start(DELAY_TIME)


func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		finish_lvl_delay.stop()


func _on_finish_lvl() -> void:
	get_node("/root/Game").finish_level()
