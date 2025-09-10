extends Node

const VIEW_OBSTRUCTING_CELLS = {
	"type_names" : {
		"Wall" : true,
		"Wall2" : true,
		"Wall3" : true,
		"Wall4" : true,
		"Wall5" : true,
	}
}
const GROUND_CELLS = {
	"type_names" : {
		"Wall" : true,
		"Wall4" : true,
		"Wall5" : true,
	}
}

const EMPTY_CELL = {
	"type_names" : {
		"EMPTY" : true,
	}
}

func subtract_arrays(minuend : Array, subtrahend : Array) -> Array:
	var result = minuend.duplicate()
	for item in subtrahend:
		result.erase(item)
	return result
