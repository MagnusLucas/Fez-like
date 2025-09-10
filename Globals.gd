extends Node

const VIEW_OBSTRUCTING_CELLS = {
	"Wall" : true,
	"Wall2" : true,
	"Wall3" : true,
	"Wall4" : true,
	"Wall5" : true,
}
const GROUND_CELLS = {
	"Wall" : true,
	"Wall4" : true,
	"Wall5" : true,
}

const EMPTY_CELL = {
	"EMPTY" : true,
	"Vines1" : true,
}

func subtract_arrays(minuend : Array, subtrahend : Array) -> Array:
	var result = minuend.duplicate()
	for item in subtrahend:
		result.erase(item)
	return result
