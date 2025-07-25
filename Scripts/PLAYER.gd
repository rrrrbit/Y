extends CharacterBody2D

const GRAV = 2000.0

const MAXSPEED = 300.0
const JUMP_VELOCITY = -550.0

var digRange := 3

var digInterval = 0.25
var digTimer = 0

var selectedTile : Vector2i

var playerTile

func _process(delta):
	playerTile = %WORLD.local_to_map(position)
	
	selectedTile = %WORLD.local_to_map(get_global_mouse_position())
	if selectedTile == playerTile:
		selectedTile += Vector2i((get_global_mouse_position()-position).normalized().snapped(Vector2.ONE))
	
	var tileDiggable : bool = %WORLD.is_tile_diggable(selectedTile, playerTile, digRange)
	
	var selectPos : Vector2 = %WORLD.map_to_local(selectedTile)
	var selectModulate : bool = tileDiggable
	
	%tileSelect.position = GLOBAL.lerpd(%tileSelect.position, selectPos, 0.9, 0.05, delta)
	%tileSelect.modulate.a = GLOBAL.lerpd(%tileSelect.modulate.a, selectModulate, 0.9, 0.05, delta) 
	
	if Input.is_action_just_pressed("DIG") and tileDiggable:
		%WORLD.digTile(selectedTile)
		digTimer = digInterval
	
	if Input.is_action_pressed("DIG"):
		digTimer -= delta
		if digTimer <= 0 and tileDiggable:
			%WORLD.digTile(selectedTile)
			digTimer = digInterval

func _physics_process(delta):
	if not is_on_floor():
		velocity += Vector2.DOWN * GRAV * delta

	if Input.is_action_pressed("UP") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("LEFT","RIGHT")*MAXSPEED
	
	velocity.x = GLOBAL.lerpd(velocity.x,direction,0.6,0.1,delta)

	move_and_slide()
