extends TileBehavior

var healthModulateGradient : Gradient = preload("res://TileTypes/Behaviors/iaomiteGradient.tres")
const TILE_COLOR = Color("00cdf9")
func _tick(coords, tileData, tileAttribs, delta, _cam, _tilemap):
	
	if not tileAttribs.has("colorDarkness"):
		tileAttribs["colorDarkness"] = 0.0
	if not tileAttribs.has("health"):
		tileAttribs["health = 0.0"]
	
	tileAttribs["health"] = clamp(tileAttribs["health"] + delta*10.0, 0.0, 8.0)
	if tileAttribs["health"] < 8.0:
		tileAttribs["colorDarkness"] = 1.
		tileData.modulate = healthModulateGradient.sample(1-tileAttribs["health"]/8.0)
		tileAttribs["lightColor"] = tileData.modulate * TILE_COLOR
	else:
		tileAttribs["colorDarkness"] = move_toward(tileAttribs["colorDarkness"], 0.25, 4*delta)
		tileData.modulate.v = tileAttribs["colorDarkness"]
		tileAttribs["lightColor"] = tileAttribs["colorDarkness"] * TILE_COLOR
		
	tileAttribs["brightness"] = tileAttribs["colorDarkness"] * 2.25
	
		
