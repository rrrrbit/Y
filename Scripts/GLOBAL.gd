extends Node

func lerpd(a,b,t,d):
	return (
		a.lerp(b,1-(1-t)**d) if typeof(a) in [TYPE_VECTOR2,TYPE_VECTOR3,TYPE_COLOR]
		else lerpf(a,b,1-(1-t)**d)
		)
		
func Wait(t):
	await get_tree().create_timer(t).timeout
