extends Node

func lerpd(a,b,k,t,d):
	return (
		a.lerp(b,1-(1-k)**(d/t)) if typeof(a) in [TYPE_VECTOR2,TYPE_VECTOR3,TYPE_COLOR]
		else lerpf(a,b,1-(1-k)**(d/t))
		)
		
func Wait(t):
	await get_tree().create_timer(t).timeout
	
func get_neighbors(coords:Vector2i) -> Array[Vector2i]: 
	var neighbors : Array[Vector2i] = []
	for x in range(-1,2):
		for y in range(-1,2):
			neighbors.append(coords+Vector2i(x,y))
	return neighbors
	
func get_adjacent(coords:Vector2i) -> Array[Vector2i]: 
	return [
		coords+Vector2i.UP,
		coords+Vector2i.DOWN,
		coords+Vector2i.LEFT,
		coords+Vector2i.RIGHT
	]
