extends TileBehavior

var healthModulateGradient : Gradient = preload("res://Tiles/Behaviors/iaomiteGradient.tres")
func _tick(coords, tileData, tileAttribs, delta, _cam, _tilemap):
	
	if not tileAttribs.has("colorDarkness"):
		tileAttribs["colorDarkness"] = 0.0
	if not tileAttribs.has("health"):
		tileAttribs["health = 0.0"]
	
	tileAttribs["health"] = clamp(tileAttribs["health"] + delta*10.0, 0.0, 8.0)
	if tileAttribs["health"] < 8.0:
		tileAttribs["colorDarkness"] = 1.0
		tileData.modulate = healthModulateGradient.sample(1-tileAttribs["health"]/8.0)
	else:
		tileAttribs["colorDarkness"] = move_toward(tileAttribs["colorDarkness"], 0.25, 4*delta)
		tileData.modulate.v = tileAttribs["colorDarkness"]
		
		
