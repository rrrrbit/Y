extends TileBehavior

const TILE_SIZE = Vector2(64,64)
const TILE_COLOR = Color("7a09fa")
func _tick(coords, tileData: TileData, tileAttribs, delta, cam: Camera2D, tilemap: TileMapLayer):
	
	if not tileAttribs.has("seen"):
		tileAttribs["seen"] = false
	if not tileAttribs.has("colorDarkness"):
		tileAttribs["colorDarkness"] = 1.0
		
	var thisTileRect : Rect2 = Rect2(tilemap.map_to_local(coords)-TILE_SIZE/2, TILE_SIZE)
	var viewportRect = cam.get_viewport().get_visible_rect()
	var viewportSize : Vector2 = viewportRect.end-viewportRect.position
	var camRect : Rect2 = Rect2(cam.get_screen_center_position()-viewportSize/2,viewportSize)
	tileAttribs["seen"] = camRect.intersects(thisTileRect,true)
	if tileAttribs["seen"]:
		tileAttribs["health"] = 10.0
		tileAttribs["colorDarkness"] = move_toward(tileAttribs["colorDarkness"], 0.2, 1*delta)
		tileData.modulate.v = tileAttribs["colorDarkness"]
		
	else:
		tileAttribs["colorDarkness"] = move_toward(tileAttribs["colorDarkness"], 1.0, 1*delta)
		tileData.modulate = Color.WHITE
	tileAttribs["lightColor"] = TILE_COLOR * tileAttribs["colorDarkness"] * 1.5
	tileAttribs["brightness"] = tileAttribs["colorDarkness"] * 6
	
