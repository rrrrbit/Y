extends TileMapLayer

var tileAttrib : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func digTile(tilePos: Vector2i):
	var tileData := get_cell_tile_data(tilePos)
	var hardness := 1
	if tileData:
		hardness = tileData.get_custom_data("hardness")
	
	if not tilePos in tileAttrib:
		print("tile attributes not found, created attributes for this tile")
		tileAttrib[tilePos] = {}
	if not "health" in tileAttrib[tilePos]:
		print("health not found in this tile's attributes, created health attribute")
		tileAttrib[tilePos]["health"] = hardness
		
	tileAttrib[tilePos]["health"] -= 1
	
	#break sprite selection logic is in desmos graph
	
	if tileAttrib[tilePos]["health"] < 1:
		set_cell(tilePos)
	pass

func OnPlayerClick(pos: Vector2):
	
	var tile := local_to_map(pos)
	digTile(tile)
