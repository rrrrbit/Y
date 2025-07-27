extends Resource
class_name TileType

@export var tileName := "tile name"
@export var hardness := 1
@export var isLightSource := false
@export var ambientLight := false
@export var lightColor := Color.BLACK
@export var brightness := 0.0
@export var atlasCoords: Array[Vector2i] = []
@export var sourceID := 0
@export var altFlipH := false
@export var altFlipV := false
@export var altRotate := false
@export var lightModeBreak := false
@export var behaviorScript : Script:
	set(val):
		behaviorScript = val
		behavior = behaviorScript.new()
var behavior: TileBehavior = null

func _to_string():
	return tileName
