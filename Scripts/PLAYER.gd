extends CharacterBody2D

const GRAV = 2000.0

const ACCELFACTOR = 0.999995
const ACCELFACTOR_SHARP = 0.9999995
const MAXSPEED = 300.0
const JUMP_VELOCITY = -550.0

var digInterval = 0.3
var digTimer = 0

func _process(delta):
	if Input.is_action_just_pressed("DIG"):
		%WORLD.digTileGlobal(get_global_mouse_position())
		digTimer = digInterval
	
	if Input.is_action_pressed("DIG"):
		digTimer-=delta
		if digTimer<=0:
			%WORLD.digTileGlobal(get_global_mouse_position())
			digTimer = digInterval

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += Vector2.DOWN * GRAV * delta

	# Handle jump.
	if Input.is_action_pressed("UP") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("LEFT","RIGHT")*MAXSPEED
	
	
	if abs(direction-velocity.x) <= MAXSPEED+50:
		
		velocity.x = GLOBAL.lerpd(velocity.x,direction,ACCELFACTOR,delta)
	else:
		velocity.x = GLOBAL.lerpd(velocity.x,direction,ACCELFACTOR_SHARP,delta)

	move_and_slide()
