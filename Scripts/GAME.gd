extends Node2D
	
func _process(delta):
	%HUD/text_stats.text = (
		"fps: "+str(Engine.get_frames_per_second())
	)
	var y = -1-round(%WORLD.local_to_map(%PLAYER.position).y)
	%HUD/text_y.text = "Y: " + str(y)
	%BG.color.v = remap(y,0,-500.0,1,0)
