extends TileMapLayer

@onready var TILE_SIZE = tile_set.tile_size

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	var thisTileRect : Rect2 = Rect2(map_to_local(coords)-TILE_SIZE/2, TILE_SIZE)
	var viewportRect = %PLAYERCAM.get_viewport().get_visible_rect()
	var viewportSize : Vector2 = viewportRect.end-viewportRect.position
	var camRect : Rect2 = Rect2(%PLAYERCAM.get_screen_center_position()-viewportSize/2,viewportSize)
	return camRect.intersects(thisTileRect,true)
