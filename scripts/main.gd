extends Node2D

func update_cursor() -> void:
	if Input.is_action_pressed("move"): return Input.set_default_cursor_shape(Input.CURSOR_DRAG)
	if $TileMap.hovering_clickable(): return Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _process(delta: float) -> void:
	update_cursor()
