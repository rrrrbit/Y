extends TileMapLayer

@export var tileTypeDict : TileTypeDict
@export var noises : Dictionary[String,Noise]
@onready var tileTypes := tileTypeDict.tileTypeDict

var clusterTypes : Dictionary[String,ClusterType]

var tileAttrib : Dictionary

var chunkSize := Vector2i(32,32)

var SEED = 0

var deltaTime := 0.0
#var generatedChunks : Array[Vector2i]

var loadedChunks : Array[Vector2i]

var cachedChunks : Dictionary[Vector2i,Array]

@export var reservedChunks : Array[Vector2i]

const LAYER_TRANSITION_WIDTH = [
	2,
	4,
	8,
	16
]

var LTW = LAYER_TRANSITION_WIDTH


const CAVE_DEPTH = 16

const LAYER_BOUNDARIES = [
	4,
	64,
	256,
	512
]

var playerChunkPos: Vector2i

func _ready():
	getClusterTypes()
	initGen()

func getClusterTypes():
	for tileType in tileTypes.keys():
		if is_instance_of(tileTypes[tileType], ClusterType):
			clusterTypes[tileType] = tileTypes[tileType]

func unloadChunk(posX: int, posY: int):
	var tilesArray = []
	var chunkPosGlobal := Vector2i(posX*chunkSize.x, posY*chunkSize.y) 
	for x in range(chunkSize.x):
		for y in range(chunkSize.y):
			var currentTile := Vector2i(x,y)+chunkPosGlobal
			var tileData := get_cell_tile_data(currentTile)
			var tileTypeName := "air"
			if tileData:
				tileTypeName = tileData.get_custom_data("tileTypeName")
			tilesArray.append(tileTypeName)
			delete_tile(currentTile)
	
	cachedChunks[Vector2i(posX,posY)] = tilesArray
	loadedChunks.erase(Vector2i(posX,posY))

func loadChunk(posX: int, posY: int):
	if not cachedChunks.has(Vector2i(posX,posY)):
		generate_chunk(posX,posY)
		return
	var chunkState = cachedChunks[Vector2i(posX,posY)]
	
	var chunkPosGlobal := Vector2i(posX*chunkSize.x, posY*chunkSize.y) 
	for x in range(chunkSize.x):
		for y in range(chunkSize.y):
			var currentTile := Vector2i(x,y)+chunkPosGlobal
			var targetTileType : String = chunkState.pop_front()
			
			if targetTileType == "air":
				set_cell(currentTile)
			else:
				set_cell(currentTile,
					tileTypes[targetTileType].sourceID,
					tileTypes[targetTileType].atlasCoords[0],
					returnTileAlt(
						tileTypes[targetTileType].altFlipH,
						tileTypes[targetTileType].altFlipV,
						tileTypes[targetTileType].altRotate
						))
						
	cachedChunks.erase(Vector2i(posX,posY))
	loadedChunks.append(Vector2i(posX,posY))
	
func initGen():
	SEED = randi()
	tileAttrib.clear()
	
	var startTime = Time.get_unix_time_from_system()
	
	for i in range(-1,1):
		for j in range(-1,1):
			generate_chunk(i,j)
	var endTime = Time.get_unix_time_from_system()
	var timeTaken = endTime - startTime
	print("generation took ",timeTaken, " seconds")

func _process(delta):
	deltaTime = delta
	playerChunkPos = floor(%PLAYER.position/Vector2(chunkSize)/Vector2(tile_set.tile_size))
	
	var neighborChunks = [
		Vector2i(playerChunkPos.x-1,playerChunkPos.y-1),
		Vector2i(playerChunkPos.x,  playerChunkPos.y-1),
		Vector2i(playerChunkPos.x+1,playerChunkPos.y-1),
		Vector2i(playerChunkPos.x-1,playerChunkPos.y),
		Vector2i(playerChunkPos.x,  playerChunkPos.y),
		Vector2i(playerChunkPos.x+1,playerChunkPos.y),
		Vector2i(playerChunkPos.x-1,playerChunkPos.y+1),
		Vector2i(playerChunkPos.x,  playerChunkPos.y+1),
		Vector2i(playerChunkPos.x+1,playerChunkPos.y+1),
	]
	
	for i in loadedChunks:
		if not neighborChunks.has(i) and not reservedChunks.has(i):
			unloadChunk(i.x,i.y)
	
	for i in neighborChunks:
		if not loadedChunks.has(i) and not reservedChunks.has(i):
			loadChunk(i.x,i.y)
	
	
	notify_runtime_tile_data_update()
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

func generate_layer_base(posX, posY):
	
	var targetTileType := "air"
	
	#grass
	if posY == 0:
		targetTileType = "grass"
		
	#dirt
	elif 1 <= posY and posY < LAYER_BOUNDARIES[0] - LTW[0]:
		targetTileType = "dirt"
		
	#dirt-rock transition
	elif LAYER_BOUNDARIES[0] - LTW[0] <= posY and posY < LAYER_BOUNDARIES[0] + LTW[0]:
		seed(SEED + posX)
		if posY <= randi_range(LAYER_BOUNDARIES[0] - LTW[0], LAYER_BOUNDARIES[0] + LTW[0] - 1):
			targetTileType = "dirt"
		else:
			targetTileType = "rock"
			
	#rock
	elif LAYER_BOUNDARIES[0]+LTW[0] <= posY and posY < LAYER_BOUNDARIES[1]-LTW[1]:
		targetTileType = "rock"
		
	#rock-dense rock transition
	elif LAYER_BOUNDARIES[1]-LTW[1] <= posY and posY < LAYER_BOUNDARIES[1]+LTW[1]:
		seed(SEED + posX * posY)
		if randf() < inverse_lerp(LAYER_BOUNDARIES[1]-LTW[1],LAYER_BOUNDARIES[1]+LTW[1],posY):
			targetTileType = "denseRock"
		else:
			targetTileType = "rock"
			
	#dense rock
	elif LAYER_BOUNDARIES[1]+LTW[1] <= posY and posY < LAYER_BOUNDARIES[2] - LTW[2]:
		targetTileType = "denseRock"
		
	#dense rock - plutonic rock transition
	elif LAYER_BOUNDARIES[2]-LTW[2] <= posY and posY < LAYER_BOUNDARIES[2]+LTW[2]:
		seed(SEED + posX * posY)
		if randf() < inverse_lerp(LAYER_BOUNDARIES[2]-LTW[2],LAYER_BOUNDARIES[2]+LTW[2],posY):
			targetTileType = "plutRock"
		else:
			targetTileType = "denseRock"
			
	#plutonic rock
	elif LAYER_BOUNDARIES[2]+LTW[2] <= posY and posY < LAYER_BOUNDARIES[3] - LTW[3]:
		targetTileType = "plutRock"
		
	#plutonic rock - tenebrite transition 
	elif LAYER_BOUNDARIES[3]-LTW[3] <= posY and posY < LAYER_BOUNDARIES[3]+LTW[3]:
		seed(SEED + posX * posY)
		if randf() < inverse_lerp(LAYER_BOUNDARIES[3]-LTW[3],LAYER_BOUNDARIES[3]+LTW[3],posY):
			targetTileType = "tenebrite"
		else:
			targetTileType = "plutRock"
			
	#tenebrite
	elif LAYER_BOUNDARIES[3]+LTW[3] <= posY :#and currentTile.y < LAYER_BOUNDARIES[3] - LTW[3]:
		targetTileType = "tenebrite"
		
	return targetTileType
	
func generate_caves(lastTargetTileType, posX, posY):
	
	if lastTargetTileType == "iaomite":return lastTargetTileType
	
	var targetTileType = lastTargetTileType
	
	noises["spaghetti"].seed = SEED
	noises["blob"].seed = SEED+1
	
	if posY >= CAVE_DEPTH:
		#spaghetti
		if noises["spaghetti"].get_noise_2d(posX, posY*2)*clamp(inverse_lerp(CAVE_DEPTH,CAVE_DEPTH+16,posY),0.0,1.0) > 0.95:
			targetTileType = "air"
		#blob
		if noises["blob"].get_noise_2d(posX, posY*2)*clamp(inverse_lerp(CAVE_DEPTH,CAVE_DEPTH+16,posY),0,1) > 0.4:
			targetTileType = "air"
	
	return targetTileType

func generate_chunk(posX, posY):
	if reservedChunks.has(Vector2i(posX,posY)):return
	var chunkPosGlobal := Vector2i(posX*chunkSize.x, posY*chunkSize.y) 
	
	for x in range(chunkSize.x):
		for y in range(chunkSize.y):
			var currentTile := Vector2i(x,y)+chunkPosGlobal
			
			var targetTileType = generate_layer_base(currentTile.x,currentTile.y)
			
			noises["spaghetti2"].seed = SEED+2
			if targetTileType == "plutRock":
				if noises["spaghetti2"].get_noise_2d(currentTile.x, currentTile.y*1.5)*clamp(inverse_lerp(256,320,currentTile.y),0.0,1.0) > 0.9:
					targetTileType = "iaomite"
			
			targetTileType = generate_caves(targetTileType,currentTile.x,currentTile.y)
			
			#region: generate other structures
			
			
			#endregion
			
			if targetTileType == "air":
				set_cell(currentTile)
			else:
				set_cell(currentTile,
					tileTypes[targetTileType].sourceID,
					tileTypes[targetTileType].atlasCoords[0],
					returnTileAlt(
						tileTypes[targetTileType].altFlipH,
						tileTypes[targetTileType].altFlipV,
						tileTypes[targetTileType].altRotate
						))
			
			
			#region: place clusters
			for clusterType in clusterTypes.values():
				if clusterType.minDepth <= currentTile.y and currentTile.y <= clusterType.maxDepth and randf() < clusterType.chance:
					place_cluster(currentTile, clusterType.tileName)
			#endregion 

	#generatedChunks.append(Vector2i(posX,posY))
	loadedChunks.append(Vector2i(posX,posY))

func place_cluster(start: Vector2i, clusterType: String):
	var clusterTypeData = clusterTypes[clusterType]
	
	var size = randi_range(clusterTypeData.minSize,clusterTypeData.maxSize)
	
	var toProcess = [start]
	var processed = {}
	
	while toProcess.size() > 0 and size > 0:
		var current = toProcess.pop_front()
		if processed.has(current) or get_cell_source_id(current) == -1:
			continue
		set_cell(current,
					clusterTypeData.sourceID,
					clusterTypeData.atlasCoords[0],
					returnTileAlt(
						clusterTypeData.altFlipH,
						clusterTypeData.altFlipV,
						clusterTypeData.altRotate
						))
		processed[current] = true
		size -= 1
		
		toProcess.append(current + Vector2i.LEFT)
		toProcess.append(current + Vector2i.RIGHT)
		toProcess.append(current + Vector2i.UP)
		toProcess.append(current + Vector2i.DOWN)
		
		toProcess.shuffle()

func digTileGlobal(globalPos: Vector2):
	var tile := local_to_map(globalPos)
	digTile(tile)

func digTile(tilePos: Vector2i):
	if get_cell_atlas_coords(tilePos) == -Vector2i.ONE: return
	var tileType = get_tile_type(tilePos)
	
	get_tile_attrib(tilePos,"health",tileType.hardness)	
	
	tileAttrib[tilePos]["health"] -= 1
	
	if tileAttrib[tilePos]["health"] == 0:
		delete_tile(tilePos)
	else:
		var breakSpriteSelect = 15 - floor( (tileAttrib[tilePos]["health"]-1.0) / (tileType.hardness-1.0) * 16.0 )
		$breakingVisualLayer.set_cell(tilePos,0,Vector2i(breakSpriteSelect,0))

func get_tile_attrib(tilePos: Vector2i, attrib: String, default):
	if not tilePos in tileAttrib:
		tileAttrib[tilePos] = {}
	if not attrib in tileAttrib[tilePos]:
		tileAttrib[tilePos][attrib] = default
	return tileAttrib[tilePos][attrib]

func get_tile_type(coords: Vector2i) -> TileType:
	var tileData := get_cell_tile_data(coords)
	var tileTypeName := "air"
	if tileData:
		tileTypeName = tileData.get_custom_data("tileTypeName")
	return tileTypeDict.tileTypeDict[tileTypeName]

func delete_tile(tilePos: Vector2i):
	set_cell(tilePos)
	$breakingVisualLayer.set_cell(tilePos)
	tileAttrib.erase(tilePos)

func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	if get_tile_type(coords).behavior:
		if not coords in tileAttrib:
			tileAttrib[coords] = {}
	return tileAttrib.has(coords)

func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	if get_tile_type(coords).behavior:
		get_tile_type(coords).behavior._tick(coords,tile_data,tileAttrib[coords])
		
