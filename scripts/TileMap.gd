extends TileMap

enum tiles {
	BUFFER_OFF,
	BUFFER_ON,
	NOT_OFF,
	NOT_ON,
	READ,
	WRITE,
	OR_OFF,
	OR_ON,
	AND_OFF,
	AND_ON,
	XOR_OFF,
	XOR_ON,
	CROSS,
	SWITCH_OFF,
	SWITCH_ON
}

const tile_coords := {
	Vector2i(0, 0): tiles.BUFFER_OFF,
	Vector2i(1, 0): tiles.BUFFER_ON,
	Vector2i(2, 0): tiles.NOT_OFF,
	Vector2i(3, 0): tiles.NOT_ON,
	Vector2i(0, 1): tiles.READ,
	Vector2i(1, 1): tiles.WRITE,
	Vector2i(2, 1): tiles.OR_OFF,
	Vector2i(3, 1): tiles.OR_ON,
	Vector2i(0, 2): tiles.AND_OFF,
	Vector2i(1, 2): tiles.AND_ON,
	Vector2i(2, 2): tiles.XOR_OFF,
	Vector2i(3, 2): tiles.XOR_ON,
	Vector2i(0, 3): tiles.CROSS,
	Vector2i(1, 3): tiles.SWITCH_OFF,
	Vector2i(2, 3): tiles.SWITCH_ON
}

const powered := {
	tiles.BUFFER_OFF: tiles.BUFFER_ON,
	tiles.BUFFER_ON: tiles.BUFFER_ON,
	tiles.NOT_OFF: tiles.NOT_ON,
	tiles.NOT_ON: tiles.NOT_ON,
	tiles.READ: tiles.READ,
	tiles.WRITE: tiles.WRITE,
	tiles.OR_OFF: tiles.OR_ON,
	tiles.OR_ON: tiles.OR_ON,
	tiles.AND_OFF: tiles.AND_ON,
	tiles.AND_ON: tiles.AND_ON,
	tiles.XOR_OFF: tiles.XOR_ON,
	tiles.XOR_ON: tiles.XOR_ON,
	tiles.CROSS: tiles.CROSS,
	tiles.SWITCH_OFF: tiles.SWITCH_ON,
	tiles.SWITCH_ON: tiles.SWITCH_ON
}

const non_powered := {
	tiles.BUFFER_OFF: tiles.BUFFER_OFF,
	tiles.BUFFER_ON: tiles.BUFFER_OFF,
	tiles.NOT_OFF: tiles.NOT_OFF,
	tiles.NOT_ON: tiles.NOT_OFF,
	tiles.READ: tiles.READ,
	tiles.WRITE: tiles.WRITE,
	tiles.OR_OFF: tiles.OR_OFF,
	tiles.OR_ON: tiles.OR_OFF,
	tiles.AND_OFF: tiles.AND_OFF,
	tiles.AND_ON: tiles.AND_OFF,
	tiles.XOR_OFF: tiles.XOR_OFF,
	tiles.XOR_ON: tiles.XOR_OFF,
	tiles.CROSS: tiles.CROSS,
	tiles.SWITCH_OFF: tiles.SWITCH_OFF,
	tiles.SWITCH_ON: tiles.SWITCH_OFF
}

const directions := [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT
]

var compiled: Array[Dictionary]
var values: Array[bool]
var next_values: Array[bool]
var index := {}
var types := {}
var currently_updating: Array[int]
var update_queue: Array[int]

func is_gate(tile: tiles) -> bool:
	return [
		tiles.NOT_OFF,
		tiles.NOT_ON,
		tiles.OR_OFF,
		tiles.OR_ON,
		tiles.AND_OFF,
		tiles.AND_ON,
		tiles.XOR_OFF,
		tiles.XOR_ON,
		tiles.SWITCH_OFF,
		tiles.SWITCH_ON
	].has(tile)

func is_non_groupable(tile: tiles) -> bool:
	return [
		tiles.READ,
		tiles.WRITE
	].has(tile)

func compile() -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	
	for i in get_used_cells(0):
		var cell: tiles = tile_coords[get_cell_atlas_coords(0, i)]
		types[i] = cell
		
		if is_non_groupable(cell): continue
		
		var success := false
		
		for j in directions:
			if index.has(i + j) and types[i + j] == cell:
				res[index[i + j]].contains.push_back(i)
				index[i] = index[i + j]
				success = true
				break
		
		if success: continue
		
		res.push_back({
			type = cell,
			contains = [i],
			updates = [],
			dependencies = []
		})
		
		index[i] = res.size() - 1
	
	# make sure groups are not split
	for i in range(res.size()):
		for j in res[i].contains:
			for k in directions:
				if not types.has(j + k) or not index.has(j + k): continue
				if index[j + k] == i: continue
				if types[j + k] != res[i].type: continue
				
				var idx: int = index[j + k]
				
				for l in res[idx].contains:
					res[i].contains.push_back(l)
					index[l] = i
				
				res[idx].contains = []
	
	for i in res:
		var middle: Array[Vector2i] = []
			
		for j in i.contains:
			for k in directions:
				if middle.has(j + k) or not types.has(j + k): continue
				if (
					(i.type == tiles.BUFFER_OFF and types[j + k] == tiles.READ) or
					(is_gate(i.type) and types[j + k] == tiles.WRITE)
				):
					middle.push_back(j + k)
		
		for j in middle:
			for k in directions:
				if not types.has(j + k) or is_non_groupable(types[j + k]): continue
				if not index.has(j + k) or i.contains.has(j + k) or i.updates.has(index[j + k]): continue
				i.updates.push_back(index[j + k])
				res[index[j + k]].dependencies.push_back(index[i.contains[0]])
		
		continue
	
	return res

func update() -> void:
	currently_updating = update_queue.duplicate(true)
	update_queue = []
	
	for i in currently_updating:
		var comp := compiled[i]
		var type: tiles = comp.type
		var dependencies: Array = comp.dependencies
		
		for j in comp.updates: update_queue.push_back(j)
		
		if type == tiles.BUFFER_OFF or type == tiles.OR_OFF or type == tiles.NOT_OFF:
			var res := false
			for j in dependencies: res = res or values[j]
			
			if type == tiles.NOT_OFF: res = not res
			
			next_values[i] = res
			continue
		
		if type == tiles.AND_OFF:
			var res := true
			for j in dependencies: res = res or values[j]
			
			next_values[i] = res
			continue
		
		if type == tiles.XOR_OFF:
			var res := false
			for j in dependencies: res = (res or values[j]) and not (res and values[j])
			
			next_values[i] = res
			continue
		
		if type == tiles.SWITCH_OFF:
			next_values[i] = not values[i]
			continue
	
	values = next_values.duplicate(true)
	
	for i in range(values.size()):
		for j in compiled[i].contains:
			var cell: Vector2i = tile_coords.find_key(compiled[i].type)
			set_cell(0, j, 0, powered[cell] if values[i] else non_powered[cell])

func mouse_pos() -> Vector2i:
	return local_to_map(to_local(get_global_mouse_position()))

func hovering():
	var atlas := get_cell_atlas_coords(0, mouse_pos())
	return tile_coords[atlas] if tile_coords.has(atlas) else null

func hovering_clickable() -> bool:
	return [
		tiles.SWITCH_OFF,
		tiles.SWITCH_ON
	].has(hovering())

func _ready() -> void:
	compiled = compile()
	for i in range(compiled.size()):
		print(i, compiled[i])
		values.push_back(false)
	
	print(values.size())

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("place") and hovering() != null:
		if powered[hovering()] == tiles.SWITCH_ON:
			if index.has(mouse_pos()):
				pass
				update_queue.push_back(index[mouse_pos()])
