extends Node

const VIEW_OBSTRUCTING_CELLS = ["Wall", "Wall2", "Wall3", "Wall4", "Wall5"]
const GROUND_CELLS = ["Wall", "Wall4", "Wall5"]

func subtract_arrays(minuend : Array, subtrahend : Array) -> Array:
	var result = minuend.duplicate()
	for item in subtrahend:
		result.erase(item)
	return result
