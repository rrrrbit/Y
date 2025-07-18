extends Control

var paused = false

func _process(delta):
	get_tree().paused = paused
	if Input.is_action_just_pressed("PAUSE"):
		paused = !paused
		print("sgfdfg")
	if !get_tree().root.has_focus():
		paused = true
	visible = paused
	
func _on_exit_pressed():
	#await %GAME.Save()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/MENU_main.tscn")
	
func _on_resume_pressed():
	paused = !paused
