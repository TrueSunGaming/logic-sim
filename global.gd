extends Node

var simulating := false
var selected: GateGrid.tiles = -1

var tilemap: GateGrid
var ui: UI

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("simulate"):
		if not simulating:
			tilemap.save_data()
		
		simulating = not simulating
		
		if simulating:
			tilemap.start_simulation()
	
	if Input.is_action_just_pressed("exit"):
		simulating = false
	
	if not simulating and Input.is_action_just_pressed("deselect"):
		selected = -1
	
	tilemap.get_node("../UI/PanelBottom").visible = not simulating
