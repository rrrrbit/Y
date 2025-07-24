extends Control

signal pauseUpdated

var paused = false:
	set(val):
		pauseUpdated.emit()
		paused=val
		_on_pause_updated()

func _process(delta):
	get_tree().paused = paused
	if Input.is_action_just_pressed("PAUSE") and !%MENU_options.visible:
		paused = !paused
	if !get_tree().root.has_focus() and !paused:
		paused = true

func _on_pause_updated():
	visible = paused

func _on_exit_pressed():
	#await %GAME.Save()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/MENU_main.tscn")

func _on_options_pressed():
	hide()
	%MENU_options.show()

func _on_resume_pressed():
	paused = false
	hide()
