extends Node
class_name Game

const GAME = preload("res://ScriptsAndScenes/game.tscn")

@onready var pause_panel: PanelContainer = $Controls/PausePanel
@onready var finish_panel: PanelContainer = $Controls/FinishPanel


static func instantiate(gridmap : Map) -> Game:
	var game : Game = GAME.instantiate()
	var world_3d : SubViewport = game.find_child("SubViewport")
	world_3d.add_child(gridmap)
	return game

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pause_panel.show()
		get_tree().paused = true

func finish_level() -> void:
	finish_panel.show()
	get_tree().paused = true
