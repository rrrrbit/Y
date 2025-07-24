extends Control

const keybindsPath = "user://keybinds.dat"
var keybinds: Dictionary

func _ready():
	for action in InputMap.get_actions():
		if InputMap.action_get_events(action).size() != 0:
			keybinds[action] = InputMap.action_get_events(action)[0]
	load_keymap()
	for child in get_children():
		if is_instance_of(child, btn_remapKey):
			child.update_text()

func load_keymap():
	if not FileAccess.file_exists(keybindsPath):
		save_keymap()
		return
	var file := FileAccess.open(keybindsPath, FileAccess.READ)
	var tempKeybinds = file.get_var(true) as Dictionary
	file.close()
	
	for action in keybinds.keys():
		if tempKeybinds.has(action):
			keybinds[action] = tempKeybinds[action]
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action,keybinds[action])

func save_keymap():
	var file := FileAccess.open(keybindsPath, FileAccess.WRITE)
	file.store_var(keybinds,true)
	file.close()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_btn_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/MENU_main.tscn")
