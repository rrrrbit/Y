extends Node2D
	
func _process(delta):
	%HUD/fpsText.text = (
		"fps: "+str(Engine.get_frames_per_second()) + "\n" + 
		"loaded chunks: " + str(%WORLD.loadedChunks.size()) + "\n" +
		"cached chunks: " + str(%WORLD.cachedChunks.size())
	)
	
	
