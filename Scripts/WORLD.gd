extends TileMapLayer

@export var tileTypeDict : TileTypeDict
@export var noises : Dictionary[String,Noise]
@onready var tileTypes := tileTypeDict.tileTypeDict

@export var updateChunks := true
@export var tickChunks := true

@onready var TILE_SIZE = tile_set.tile_size

var tickingTiles := 0

var lightmap : Dictionary[Vector2i,Color]

var clusterTypes : Dictionary[String,ClusterType]

var tileAttrib : Dictionary

var chunkSize := Vector2i(32,16)

var SEED = 0

var deltaTime := 0.0
#var generatedChunks : Array[Vector2i]

var loadedChunks : Array[Vector2i]

var cachedChunks : Dictionary[Vector2i,Array]

var cachedSourceLightmaps = {}

@export var reservedChunks : Array[Vector2i]
@export var initialGenerate : Rect2i
const LAYER_TRANSITION_WIDTH = [
	2,
	4,
	4,
	4,
	4
]

var LTW = LAYER_TRANSITION_WIDTH

var lightTickSpeed := 1/48.0
var lightTickTimer := 0.0

var lightingDirty = false

var camRect : Rect2
const CAVE_DEPTH = 50

const LAYER_BOUNDARIES = [
	4,
	250,
	500,
	1000,
	1500,
]

var playerChunkPos: Vector2i

func _ready():
	var test :Texture2D
	
	getClusterTypes()
	initGen()
	for i in reservedChunks:
		loadedChunks.append(i)
		
	await GLOBAL.Wait(0.2)
	lightingDirty = true

func getClusterTypes():
	for tileType in tileTypes.keys():
		if is_instance_of(tileTypes[tileType], ClusterType):
			clusterTypes[tileType] = tileTypes[tileType]

func initGen():
	SEED = randi()
	tileAttrib.clear()
	
	var startTime = Time.get_unix_time_from_system()
	
	for i in range(initialGenerate.position.x,initialGenerate.end.x):
		for j in range(initialGenerate.position.y,initialGenerate.end.y):
			generate_chunk(i,j)
	var endTime := Time.get_unix_time_from_system()
	var timeTaken : float = endTime - startTime
	print("generation took ",timeTaken, " seconds")
	
	

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
	elif LAYER_BOUNDARIES[3]+LTW[3] <= posY and posY < LAYER_BOUNDARIES[4] - LTW[4]:
		targetTileType = "tenebrite"
	
	#tenebrite - null transition 
	elif LAYER_BOUNDARIES[4]-LTW[4] <= posY and posY < LAYER_BOUNDARIES[4]+LTW[4]:
		seed(SEED + posX * posY)
		if randf() < inverse_lerp(LAYER_BOUNDARIES[4]-LTW[4],LAYER_BOUNDARIES[4]+LTW[4],posY):
			targetTileType = "air"
		else:
			targetTileType = "tenebrite"
	
	return targetTileType
	
func generate_caves(lastTargetTileType, posX, posY):
	
	if lastTargetTileType in ["iaomite","conivium"]:return lastTargetTileType
	
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

func generate_ores_noise(lastTargetTileType, posX, posY):
	var targetTileType = lastTargetTileType
	noises["spaghetti2"].seed = SEED+2
	if targetTileType == "plutRock":
		if noises["spaghetti2"].get_noise_2d(posX, posY*1.5)*clamp(inverse_lerp(256,320,posY),0.0,1.0) > 0.875:
			targetTileType = "iaomite"
			
	noises["spaghetti3"].seed = SEED+3
	if targetTileType == "tenebrite":
		if noises["spaghetti3"].get_noise_2d(posX, posY) < -0.95:
			targetTileType = "conivium"
	return targetTileType

func place_cluster(start: Vector2i, clusterType: String):
	var clusterTypeData = clusterTypes[clusterType]
	
	var size = randi_range(clusterTypeData.minSize,clusterTypeData.maxSize)
	
	var toProcess : Array[Vector2i] = [start]
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
		
		toProcess.append_array(GLOBAL.get_adjacent(current))
		
		toProcess.shuffle()

func generate_chunk(posX, posY):
	if reservedChunks.has(Vector2i(posX,posY)):return
	var chunkPosGlobal := Vector2i(posX*chunkSize.x, posY*chunkSize.y) 
	
	for x in range(chunkSize.x):
		for y in range(chunkSize.y):
			var currentTile := Vector2i(x,y)+chunkPosGlobal
			
			var targetTileType = generate_layer_base(currentTile.x,currentTile.y)
			
			targetTileType = generate_ores_noise(targetTileType,currentTile.x,currentTile.y)
			
			targetTileType = generate_caves(targetTileType,currentTile.x,currentTile.y)
			
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



func digTile(tilePos: Vector2i):
	if get_cell_atlas_coords(tilePos) == -Vector2i.ONE: return
	var tileType = get_tile_type(tilePos)
	
	get_tile_attrib(tilePos,"health",tileType.hardness)
	
	tileAttrib[tilePos]["health"] -= 1

func delete_tile(tilePos: Vector2i):
	set_cell(tilePos)
	$breakingVisualLayer.set_cell(tilePos)
	tileAttrib.erase(tilePos)

func _process(delta):
	
	var viewportRect = %PLAYERCAM.get_viewport().get_visible_rect()
	var viewportSize : Vector2 = viewportRect.end-viewportRect.position
	camRect = Rect2(%PLAYERCAM.get_screen_center_position()-viewportSize/2,viewportSize)
	
	deltaTime = delta
	playerChunkPos = floor(%PLAYER.position/Vector2(chunkSize)/Vector2(tile_set.tile_size))
	
	var neighborChunks = GLOBAL.get_neighbors(playerChunkPos)
	
	for i in loadedChunks:
		if not neighborChunks.has(i) and not reservedChunks.has(i) and updateChunks:
			unloadChunk(i.x,i.y)
	
	for i in neighborChunks:
		if not loadedChunks.has(i) and not reservedChunks.has(i) and updateChunks:
			loadChunk(i.x,i.y)
	
	tickingTiles = 0
	if tickChunks: notify_runtime_tile_data_update()
	
	tickBehavior(delta)
	
	if lightingDirty:
		update_lighting()
		lightingDirty = false

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

func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return camRect.intersects(Rect2(map_to_local(coords)-Vector2(TILE_SIZE)/2, TILE_SIZE),true) 

func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	var tileType = get_tile_type(coords)
	var mod = Color.WHITE
	if tileAttrib.has(coords):
		mod = tileAttrib[coords].get("modulate", Color.WHITE)
	tile_data.modulate = mod * lightmap.get(coords,Color.WHITE)
	
	var h = tileType.hardness
	if tileAttrib.has(coords):
		h = tileAttrib[coords].get("health",h)
	if h <= 0:
		delete_tile(coords)
		lightingDirty = true
	else:
		var breakSpriteSelect = 15 - floor( (h-1.0) / (tileType.hardness-1.0) * 16.0 )
		$breakingVisualLayer.set_cell(coords,1 if tileType.lightModeBreak else 0,Vector2i(breakSpriteSelect,0),returnTileAlt(true,true,true,coords.x*coords.y))

func tickBehavior(delta):
	for chunk in loadedChunks:
		var chunkPosGlobal := chunk * chunkSize
		for x in range(chunkSize.x):
			for y in range(chunkSize.y):
				var currentTile : Vector2i = Vector2i(x,y)+chunkPosGlobal 
				var currentTileType = get_tile_type(currentTile)
				if !currentTileType.behavior:
					continue
				get_tile_attrib(currentTile,"health",currentTileType.hardness)
				currentTileType.behavior._tick(currentTile,tileAttrib[currentTile],delta, %PLAYERCAM, self)

func update_lighting():
	if !%PLAYER.playerTile:
		return
	var sources := {}
	
	for chunk in loadedChunks:
		var chunkPosGlobal := chunk * chunkSize
		for x in range(chunkSize.x):
			for y in range(chunkSize.y):
				var currentTile : Vector2i = Vector2i(x,y)+chunkPosGlobal
				if not camRect.intersects(Rect2(map_to_local(currentTile)-Vector2(TILE_SIZE)/2, TILE_SIZE),true):
					continue
				
				var d = abs(%PLAYER.global_position - map_to_local(currentTile))
				var b = clamp(1-max(d.x,d.y)/(64*6),0,1)
				lightmap[currentTile] = Color.BLACK + Color(b,b,b)
				
	for chunk in loadedChunks:
		var chunkPosGlobal := chunk * chunkSize
		for x in range(chunkSize.x):
			for y in range(chunkSize.y):
				var currentTile : Vector2i = Vector2i(x,y)+chunkPosGlobal
				var currentTileType = get_tile_type(currentTile)
				
				if not currentTileType.isLightSource: continue
				
				var tileBrightness = get_tile_attrib(currentTile, "brightness", 0.0)
				var tileLightColor = get_tile_attrib(currentTile, "lightColor", Color.BLACK)
				
				if currentTileType.ambientLight:
					tileAttrib[currentTile]["brightness"] = currentTileType.brightness
					tileAttrib[currentTile]["lightColor"] = currentTileType.lightColor
					
				if tileLightColor != Color.BLACK and tileBrightness > 0.0:
					sources[currentTile] = [tileLightColor, tileBrightness]
				
	for source in sources:
		var sourceLightmap = source_lightmap(source, sources[source][0], sources[source][1])
		for i in sourceLightmap:
			lightmap[i] = lightBlend(lightmap.get(i, Color.BLACK), sourceLightmap[i])

func lightBlend(a : Color, b : Color) -> Color:
	if a.v+b.v == 0: return Color.BLACK
	var w = ((a*a.v+b*b.v)/(a.v+b.v))
	return Color.from_hsv(
		w.h,
		w.s,
		max(a.v,b.v)
	)

func source_lightmap(source, color, brightness):
	var processed = {}
	var queue : Array[Vector2i] = [source]
	var sourceTileType := get_tile_type(source)
	var thisLightmap : Dictionary[Vector2i,Color] = {}
	while !queue.is_empty():
		var current : Vector2i = queue.pop_front()
		
		var d : Vector2i = abs(source - current)
		var distance : int = max(d.x,d.y)
		
		var thisColor : Color = color * (1.0-distance/brightness)

		if (
			processed.has(current) or 
			thisColor.get_luminance() < 0.05 or
			str(get_tile_type(current)) == "air"
			):
			continue
			
		thisLightmap[current] = thisColor
		
		processed[current] = true
		for i in GLOBAL.get_adjacent(current):
			queue.append(i)
	return thisLightmap

func find_air_body(start: Vector2i, maxDistance: int):
	var toVisit : Array[Vector2i] = [start]
	var visited = []
	
	while !toVisit.is_empty():
		var current = toVisit.pop_back()
		
		var distance = max((current-start).abs().x, (current-start).abs().y)
		
		if visited.has(current) or str(get_tile_type(current)) != "air" or distance > maxDistance:
			continue
			
		visited.append(current)
		toVisit.append_array(GLOBAL.get_adjacent(current))
		
	return visited

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

func is_tile_diggable(coords:Vector2i, playerCoords: Vector2i, range: int) -> bool:
	var airBody = find_air_body(playerCoords, range)
	var airBodyAdjacent = []
	for tile in airBody:
		airBodyAdjacent.append_array(GLOBAL.get_adjacent(tile))

	var distance = max((coords-playerCoords).abs().x, (coords-playerCoords).abs().y)
	return airBodyAdjacent.has(coords) and distance <= range and str(get_tile_type(coords)) != "air"

func returnTileAlt(flipH: bool, flipV: bool, rotate: bool, randSeed: int = randi()):
	var alt := 0
	if rotate:
		seed(randSeed)
		match randi_range(0,3):
			1: alt = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H
			2: alt = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V
			3: alt = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V
	seed(randSeed+1)
	if flipH and randf() < 0.5: alt ^= TileSetAtlasSource.TRANSFORM_FLIP_H
	seed(randSeed+2)
	if flipV and randf() < 0.5: alt ^= TileSetAtlasSource.TRANSFORM_FLIP_V
	
	return alt
