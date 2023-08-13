class_name GateGrid extends TileMap

@export var updates_per_tick := 1

const save_location := "user://save.dat"

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

static func is_gate(tile: tiles) -> bool:
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

static func is_non_groupable(tile: tiles) -> bool:
	return [
		tiles.READ,
		tiles.WRITE,
		tiles.CROSS
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
	
	for i in range(res.size()):
		for j_idx in range(res[i].contains.size()):
			var j: Vector2i = res[i].contains[j_idx]
			
			for k in directions:
				if not types.has(j + k) or not index.has(j + k): continue
				if index[j + k] == i: continue
				if types[j + k] != res[i].type: continue
				
				var idx: int = index[j + k]
				
				for l in res[idx].contains:
					res[i].contains.push_back(l)
					index[l] = i
				
				res[idx].contains = []
			
			for k in directions:
				if not types.has(j + k): continue
				if types[j + k] != tiles.CROSS: continue
				if not types.has(j + k * 2) or not index.has(j + k * 2): continue
				
				var idx: int = index[j + k * 2]
				
				for l in res[idx].contains:
					res[i].contains.push_back(l)
					index[l] = i
				
				res[idx].contains = []
	
	for idx in range(res.size()):
		var i: Dictionary = res[idx]
		var middle: Array[Vector2i] = []
		
		if i.type == tiles.NOT_OFF: add_to_queue(idx)
			
		for j in i.contains:
			for k in directions:
				if middle.has(j + k) or not types.has(j + k): continue
				
				if i.type == tiles.BUFFER_OFF and types[j + k] == tiles.READ:
					middle.push_back(j + k)
				
				if is_gate(i.type) and types[j + k] == tiles.WRITE:
					var double := false
					
					for l in directions:
						if types.has(j + k + l) and types[j + k + l] == tiles.READ: 
							middle.push_back(j + k + l)
							double = true
					
					if not double:
						middle.push_back(j + k)
		
		for j in middle:
			for k in directions:
				if not types.has(j + k) or is_non_groupable(types[j + k]): continue
				if not index.has(j + k) or i.contains.has(j + k) or i.updates.has(index[j + k]): continue
				i.updates.push_back(index[j + k])
				res[index[j + k]].dependencies.push_back(idx)
		
		continue
	
	return res

func update() -> void:
	if not global.simulating:
		currently_updating = []
		update_queue = []
		compiled = []
		types = {}
		index = {}
		values = []
		next_values = []
		
		for i in get_used_cells(0):
			set_cell(0, i, 0, tile_coords.find_key(non_powered[tile_coords[get_cell_atlas_coords(0, i)]]))
		
		return
	
	currently_updating = update_queue.duplicate(true)
	update_queue = []
	
	for i in currently_updating:
		var comp := compiled[i]
		var type: tiles = comp.type
		var dependencies: Array = comp.dependencies
		
		if type == tiles.BUFFER_OFF or type == tiles.OR_OFF or type == tiles.NOT_OFF:
			var res := false
			for j in dependencies: res = res or values[j]
			
			if type == tiles.NOT_OFF: res = not res
			
			next_values[i] = res
			continue
		
		if type == tiles.AND_OFF:
			var res := true
			for j in dependencies: res = res and values[j]
			
			next_values[i] = res
			continue
		
		if type == tiles.XOR_OFF:
			var res := false
			for j in dependencies: res = (res or values[j]) and not (res and values[j])
			
			next_values[i] = res
			continue
		
		if type == tiles.SWITCH_OFF:
			if dependencies.size() != 0:
				var res := false
				for j in dependencies: res = res or values[j]
				if not res: continue
			
			next_values[i] = not values[i]
			continue
	
	for i in currently_updating:
		if next_values[i] != values[i]:
			for j in compiled[i].updates: add_to_queue(j)
	
	values = next_values.duplicate(true)
	
	for i in range(values.size()):
		var type: tiles = compiled[i].type
		for j in compiled[i].contains:
			var cell: Vector2i = tile_coords.find_key(powered[type] if values[i] else non_powered[type])
			set_cell(0, j, 0, cell)

func tick() -> void:
	for i in range(updates_per_tick):
		update()

func mouse_pos() -> Vector2i:
	return local_to_map(to_local(get_global_mouse_position()))

func hovering():
	var atlas := get_cell_atlas_coords(0, mouse_pos())
	return tile_coords[atlas] if tile_coords.has(atlas) else null

func hovering_clickable() -> bool:
	return [
		tiles.SWITCH_OFF,
		tiles.SWITCH_ON
	].has(hovering()) and global.simulating

func start_simulation() -> void:
	global.selected = -1
	
	save_data()
	
	compiled = compile()
	for i in range(compiled.size()):
		values.push_back(false)
		next_values = values.duplicate(true)

func add_to_queue(idx: int) -> void:
	if update_queue.has(idx): return
	update_queue.push_back(idx)

func generate_save_data() -> Dictionary:
	var res := {}
	
	for i in get_used_cells(0):
		res[i] = tile_coords[get_cell_atlas_coords(0, i)]
	
	return res

func load_save_data(data: Dictionary) -> void:
	for i in data._autosave.keys():
		var tile: tiles = data._autosave[i]
		if tile == null: continue
		
		var coords: Vector2i = tile_coords.find_key(tile)
		if coords == null: continue
		
		set_cell(0, i, 0, coords)

func save_data() -> void:
	if global.simulating: return
	
	var file := FileAccess.open(save_location, FileAccess.WRITE)
	
	file.store_var({
		_autosave = generate_save_data()
	}, true)
	
	file.close()

func load_data() -> void:
	if not FileAccess.file_exists(save_location): return
	
	var file := FileAccess.open(save_location, FileAccess.READ)
	
	var data: Dictionary = file.get_var(true)
	
	if data == null: return
	
	load_save_data(data)

func _ready() -> void:
	load_data()
	
	global.tilemap = self

func _process(delta: float) -> void:
	if global.ui != null and not (global.ui.hovering_top or global.ui.hovering_bottom):
		if global.simulating and Input.is_action_just_pressed("place") and hovering() != null:
			if powered[hovering()] == tiles.SWITCH_ON:
				if index.has(mouse_pos()) and compiled[index[mouse_pos()]].dependencies.size() == 0:
					add_to_queue(index[mouse_pos()])
	
		if not global.simulating:
			if Input.is_action_pressed("place") and global.selected != -1:
				set_cell(0, mouse_pos(), 0, tile_coords.find_key(global.selected))
		
			if Input.is_action_pressed("delete"):
				set_cell(0, mouse_pos())

func _on_tree_exiting() -> void:
	save_data()
