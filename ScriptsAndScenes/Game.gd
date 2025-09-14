extends Node
class_name Game

const GAME = preload("res://ScriptsAndScenes/game.tscn")

static func instantiate(gridmap : Map) -> Game:
	var game : Game = GAME.instantiate()
	var world_3d : SubViewport = game.find_child("SubViewport")
	world_3d.add_child(gridmap)
	return game

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		$CanvasLayer/PausePanel.show()
		get_tree().paused = true

func finish_level() -> void:
	$CanvasLayer/FinishPanel.show()
	get_tree().paused = true
