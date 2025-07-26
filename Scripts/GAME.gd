extends Node2D
	
func _process(delta):
	%HUD/text_stats.text = (
		"fps: "+str(Engine.get_frames_per_second()) + "\n" + 
		"loaded chunks: " + str(%WORLD.loadedChunks.size()) + "\n" +
		"cached chunks: " + str(%WORLD.cachedChunks.size()) + "\n" +
		"tracked tile attribs: " + str(%WORLD.tileAttrib.size()) + "\n" +
		"ticking tiles: " + str(%WORLD.tickingTiles)
	)
	%HUD/text_y.text = "Y: " + str(-1-round(%WORLD.local_to_map(%PLAYER.position).y))
	
	
