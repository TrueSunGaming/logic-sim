extends Sprite2D

func _process(delta: float) -> void:
	if global.selected == -1:
		hide()
	else:
		show()
		region_rect.position = Vector2(GateGrid.tile_coords.find_key(global.selected) * 16)
		position = get_parent().mouse_pos() * get_parent().tile_set.tile_size
