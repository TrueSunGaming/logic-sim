extends Camera2D

@export var zoom_speed: float

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("zoomout"): zoom /= zoom_speed + 1
	if Input.is_action_just_pressed("zoomin"): zoom *= zoom_speed + 1
	zoom = zoom.clamp(Vector2(0.1, 0.1), Vector2(10, 10))
	
	if event is InputEventMouseMotion and Input.is_action_pressed("move"):
		global_position -= event.relative / zoom

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if zoom.x < 1: return
	var tilesize: Vector2i = $"../TileMap".tile_set.tile_size
	
	var gpos := Vector2(
		int(global_position.x) % tilesize.x + global_position.x - sign(global_position.x) * floor(abs(global_position.x)),
		int(global_position.y) % tilesize.y + global_position.y - sign(global_position.y) * floor(abs(global_position.y))
	)
	
	var vsize: Vector2 = get_viewport().size / zoom.x
	
	for i in range(-vsize.x / (tilesize.x * 2), vsize.x / (tilesize.x * 2) + 2):
		draw_line(
			Vector2(i * tilesize.x - gpos.x, -vsize.y / 2),
			Vector2(i * tilesize.x - gpos.x, vsize.y / 2),
			Color("#454545"),
		)
	
	for i in range(-vsize.y / (tilesize.y * 2), vsize.y / (tilesize.y * 2) + 2):
		draw_line(
			Vector2(-vsize.x / 2, i * tilesize.y - gpos.y),
			Vector2(vsize.x / 2, i * tilesize.y - gpos.y),
			Color("#454545"),
		)
