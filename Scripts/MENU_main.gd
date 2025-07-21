extends Control

var progress = []
var loading : bool

func _process(delta):
	%loadingText.visible = loading
	var status = ResourceLoader.load_threaded_get_status("res://Scenes/GAME.tscn",progress)
	%loadingText.text = str(progress[0])+"%"
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get("res://Scenes/GAME.tscn"))

func _on_btn_play_pressed():
	ResourceLoader.load_threaded_request("res://Scenes/GAME.tscn")
	loading = true
	
	



func _on_btn_quit_pressed():
	get_tree().quit()
