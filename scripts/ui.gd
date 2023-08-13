class_name UI extends CanvasLayer

var hovering_top := false
var hovering_bottom := false

func select(tile: GateGrid.tiles) -> void:
	global.selected = tile
	
	print(global.selected)

func select_buffer() -> void:
	select(GateGrid.tiles.BUFFER_OFF)

func select_read() -> void:
	select(GateGrid.tiles.READ)

func select_write() -> void:
	select(GateGrid.tiles.WRITE)

func select_not() -> void:
	select(GateGrid.tiles.NOT_OFF)

func select_or() -> void:
	select(GateGrid.tiles.OR_OFF)

func select_and() -> void:
	select(GateGrid.tiles.AND_OFF)

func select_xor() -> void:
	select(GateGrid.tiles.XOR_OFF)
	
func select_cross() -> void:
	select(GateGrid.tiles.CROSS)

func select_switch() -> void:
	select(GateGrid.tiles.SWITCH_OFF)

func _ready() -> void:
	global.ui = self

func panel_top_mouse_entered() -> void:
	hovering_top = true

func panel_top_mouse_exited() -> void:
	hovering_top = false

func panel_bottom_mouse_entered() -> void:
	hovering_bottom = true

func panel_bottom_mouse_exited() -> void:
	hovering_bottom = false

func toggle_sim() -> void:
	global.simulating = not global.simulating
	
	if global.simulating:
		global.tilemap.start_simulation() 
