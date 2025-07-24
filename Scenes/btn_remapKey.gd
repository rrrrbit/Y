extends Button
class_name btn_remapKey

@export var action: String

func _init():
	toggle_mode = true
	
# Called when the node enters the scene tree for the first time.
func _ready():
	set_process_unhandled_input(false)
	pass # Replace with function body.

func _toggled(toggled_on):
	set_process_unhandled_input(toggled_on)
	if toggled_on:
		text = "..."
		
func _unhandled_input(event):
	if event.is_pressed():
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action,event)
		button_pressed = false
		release_focus()
		update_text()
		$"..".keybinds[action] = event
		$"..".save_keymap()
		
func update_text():
	text = InputMap.action_get_events(action)[0].as_text()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
