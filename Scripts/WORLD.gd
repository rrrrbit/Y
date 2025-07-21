extends TileMapLayer

var tileAtlasCoords = {
	
	"air" : Vector2i(-1,-1),
	"grass" : Vector2i(0,0),
	"dirt" : Vector2i(1,0),
	"rock" : Vector2i(2,0),
	"denseRock" : Vector2i(3,0),
	"plutRock" : Vector2i(4,0),
	"tenebrite" : Vector2i(5,0),
	
}

var tileAttrib : Dictionary

var chunkWidth := 64
var chunkHeight := 128

var SEED = 0

const LAYER_TRANSITION_WIDTH = [
	2,
	4,
	8,
	16
]

var LTW = LAYER_TRANSITION_WIDTH

@export var spaghettiNoise : Noise
@export var blobNoise : Noise
@export var spaghettiNoise2 : Noise

const CAVE_DEPTH = 16

const LAYER_BOUNDARIES = [
	4,
	64,
	256,
	512
]
# Called when the node enters the scene tree for the first time.
func _ready():
	initGen()

func initGen():
	SEED = randi()
	tileAttrib.clear()
	
	var startTime = Time.get_unix_time_from_system()
	
	for i in range(-1,1):
		for j in range(0,5):
			generate_chunk(i,j)
	var endTime = Time.get_unix_time_from_system()
	var timeTaken = endTime - startTime
	print("generation took ",timeTaken, " seconds")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func returnTileAlt(flipH: bool, flipV: bool, rotate: bool):
	var alt := 0
	if rotate:
		match randi_range(0,3):
			1: alt = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H
			2: alt = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V
			3: alt = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V
				
	if flipH and randf() < 0.5: alt ^= TileSetAtlasSource.TRANSFORM_FLIP_H
	if flipV and randf() < 0.5: alt ^= TileSetAtlasSource.TRANSFORM_FLIP_V
	return alt

func generate_chunk(posX, posY):
	var chunkPosGlobal := Vector2i(posX*chunkWidth, posY*chunkHeight) 
	
	for x in range(chunkWidth):
		for y in range(chunkHeight):
			var currentTile := Vector2i(x,y)+chunkPosGlobal
			
			var targetTile = "air"
			var targetTileAlt = 0
			
			#region: generate layers
			
			#grass
			if currentTile.y == 0:
				targetTile = "grass"
				targetTileAlt = returnTileAlt(true,false,false)
			#dirt
			elif 1 <= currentTile.y and currentTile.y < LAYER_BOUNDARIES[0]-LTW[0]:
				targetTile = "dirt"
				targetTileAlt = returnTileAlt(true,true,true)
			#dirt-rock transition
			elif LAYER_BOUNDARIES[0]-LTW[0] <= currentTile.y and currentTile.y < LAYER_BOUNDARIES[0]+LTW[0]:
				seed(SEED+currentTile.x)
				if currentTile.y <= randi_range(LAYER_BOUNDARIES[0]-LTW[0], LAYER_BOUNDARIES[0]+LTW[0]-1):
					targetTile = "dirt"
					targetTileAlt = returnTileAlt(true,true,true)
				else:
					targetTile = "rock"
					targetTileAlt = returnTileAlt(true,true,false)
			#rock
			elif LAYER_BOUNDARIES[0]+LTW[0] <= currentTile.y and currentTile.y < LAYER_BOUNDARIES[1]-LTW[1]:
				targetTile = "rock"
				targetTileAlt = returnTileAlt(true,true,false)
			#rock-dense rock transition
			elif LAYER_BOUNDARIES[1]-LTW[1] <= currentTile.y and currentTile.y < LAYER_BOUNDARIES[1]+LTW[1]:
				seed(SEED+currentTile.x*currentTile.y)
				if randf() < inverse_lerp(LAYER_BOUNDARIES[1]-LTW[1],LAYER_BOUNDARIES[1]+LTW[1],currentTile.y):
					targetTile = "denseRock"
					targetTileAlt = returnTileAlt(true,true,true)
				else:
					targetTile = "rock"
					targetTileAlt = returnTileAlt(true,true,false)
			#dense rock
			elif LAYER_BOUNDARIES[1]+LTW[1] <= currentTile.y and currentTile.y < LAYER_BOUNDARIES[2] - LTW[2]:
				targetTile = "denseRock"
				targetTileAlt = returnTileAlt(true,true,true)
			#dense rock - plutonic rock transition
			elif LAYER_BOUNDARIES[2]-LTW[2] <= currentTile.y and currentTile.y < LAYER_BOUNDARIES[2]+LTW[2]:
				seed(SEED+currentTile.x*currentTile.y)
				if randf() < inverse_lerp(LAYER_BOUNDARIES[2]-LTW[2],LAYER_BOUNDARIES[2]+LTW[2],currentTile.y):
					targetTile = "plutRock"
					targetTileAlt = returnTileAlt(true,true,true)
				else:
					targetTile = "denseRock"
					targetTileAlt = returnTileAlt(true,true,true)
			#plutonic rock
			elif LAYER_BOUNDARIES[2]+LTW[2] <= currentTile.y and currentTile.y < LAYER_BOUNDARIES[3] - LTW[3]:
				targetTile = "plutRock"
				targetTileAlt = returnTileAlt(true,true,true)
			#plutonic rock - tenebrite transition 
			elif LAYER_BOUNDARIES[3]-LTW[3] <= currentTile.y and currentTile.y < LAYER_BOUNDARIES[3]+LTW[3]:
				seed(SEED+currentTile.x*currentTile.y)
				if randf() < inverse_lerp(LAYER_BOUNDARIES[3]-LTW[3],LAYER_BOUNDARIES[3]+LTW[3],currentTile.y):
					targetTile = "tenebrite"
					targetTileAlt = returnTileAlt(true,true,true)
				else:
					targetTile = "plutRock"
					targetTileAlt = returnTileAlt(true,true,true)
			#tenebrite
			elif LAYER_BOUNDARIES[3]+LTW[3] <= currentTile.y :#and currentTile.y < LAYER_BOUNDARIES[3] - LTW[3]:
				targetTile = "tenebrite"
				targetTileAlt = returnTileAlt(true,true,true)
			
			#endregion
			#region: generate caves
			spaghettiNoise.seed = SEED
			blobNoise.seed = SEED+1
			if currentTile.y >= CAVE_DEPTH:
				#spaghetti
				if spaghettiNoise.get_noise_2d(currentTile.x, currentTile.y*2)*clamp(inverse_lerp(CAVE_DEPTH,CAVE_DEPTH+16,currentTile.y),0.0,1.0) > 0.95:
					targetTile = "air"
					targetTileAlt = 0
				#blob
				if blobNoise.get_noise_2d(currentTile.x, currentTile.y*2)*clamp(inverse_lerp(CAVE_DEPTH,CAVE_DEPTH+16,currentTile.y),0,1) > 0.4:
					targetTile = "air"
					targetTileAlt = 0
			#endregion
			#region: generate ores
			spaghettiNoise2.seed = SEED
			#if get_cell_atlas_coords(currentTile) == Vector2i(3,0):
				#if spaghettiNoise.get_noise_2d(currentTile.x, currentTile.y*2)*clamp(inverse_lerp(CAVE_DEPTH,CAVE_DEPTH+16,currentTile.y),0.0,1.0) > 0.95:
					#targetTile = "air"
					#targetTileAlt = 0
				
			#endregion
			set_cell(currentTile,0,tileAtlasCoords[targetTile],targetTileAlt)

func digTileGlobal(globalPos: Vector2):
	var tile := local_to_map(globalPos)
	digTile(tile)

func digTile(tilePos: Vector2i):
	if get_cell_atlas_coords(tilePos) == -Vector2i.ONE: return
	var tileData := get_cell_tile_data(tilePos)
	var hardness := 0 #if no hardness value, default to zero
	if tileData:
		hardness = tileData.get_custom_data("hardness")
	
	if not tilePos in tileAttrib:
		tileAttrib[tilePos] = {}
	if not "health" in tileAttrib[tilePos]:
		tileAttrib[tilePos]["health"] = hardness
		
	tileAttrib[tilePos]["health"] -= 1
	
	
	
	if tileAttrib[tilePos]["health"] == 0:
		set_cell(tilePos)
		$breakingVisualLayer.set_cell(tilePos)
	else:
		var breakSpriteSelect = 15 - floor( (tileAttrib[tilePos]["health"]-1.0) / (hardness-1.0) * 16.0 )
		$breakingVisualLayer.set_cell(tilePos,0,Vector2i(breakSpriteSelect,0))
