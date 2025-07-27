extends TileBehavior

var healthModulateGradient : Gradient = preload("res://TileTypes/Behaviors/iaomiteGradient.tres")
const TILE_COLOR = Color("00cdf9")
func _tick(coords, tileAttribs, delta, _cam, tilemap):
	if not tileAttribs.has("colorDarkness"):
		tileAttribs["colorDarkness"] = 0.0
	if not tileAttribs.has("health"):
		tileAttribs["health"] = 8.0
	if not tileAttribs.has("brightness"):
		tileAttribs["brightness"] = 0.0
		
	var lastBrightness = tileAttribs["brightness"]
	
	tileAttribs["modulate"] = Color.WHITE
	
	tileAttribs["health"] = min(tileAttribs["health"] + delta*10.0, 8.0)
	if tileAttribs["health"] < 8.0:
		tileAttribs["colorDarkness"] = 1.
		tileAttribs["modulate"] = healthModulateGradient.sample(1-tileAttribs["health"]/8.0)
		tileAttribs["lightColor"] = tileAttribs["modulate"] * TILE_COLOR
	else:
		tileAttribs["colorDarkness"] = move_toward(tileAttribs["colorDarkness"], 0.25, 4*delta)
		tileAttribs["modulate"].v = tileAttribs["colorDarkness"]
		tileAttribs["lightColor"] = tileAttribs["colorDarkness"] * TILE_COLOR
		
	tileAttribs["brightness"] = tileAttribs["colorDarkness"] * 4
	
	if tileAttribs["brightness"]!= lastBrightness:
		tilemap.lightingDirty = true
