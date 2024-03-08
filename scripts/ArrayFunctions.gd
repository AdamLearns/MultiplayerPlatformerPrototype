extends Node

func random_array_element(array: Array) -> Variant:
	return array[randi() % array.size()]
