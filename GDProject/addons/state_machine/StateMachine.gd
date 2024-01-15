@tool
class_name StateMachine extends Resource

signal _updated_state_node(index: int)

class _NodeData:
	var pos: Vector2
	var type: int
	var id: int
	var outputs: Array[int]

class _StartingNode:
	var pos: Vector2 = Vector2.ZERO
	var output: int = -1

@export var states: Array[StateResource] = []:
	set(value):
		states = value
		_setup_change_detection()
		_rebuild_nodes()
		emit_changed()

var _startingNode := StateNode.new():
	set(value):
		_startingNode = value
		if _startingNode == null or not is_instance_valid(_startingNode):
			_startingNode = _build_starting_node()
var _stateNodes: Array[StateNode] = []

var _graphStartingNode := _StartingNode.new()
var _graphData: Array[_NodeData] = []


func _setup_change_detection():
	for index in states.size():
		var elem := states[index]
		if elem != null:
			if not elem.nameUpdated.is_connected(_on_state_name_update): 
				elem.nameUpdated.connect(_on_state_name_update.bind(index))
			if not elem.scriptUpdated.is_connected(_on_state_script_update): 
				elem.scriptUpdated.connect(_on_state_script_update.bind(index))


func _on_state_name_update(index: int):
	_stateNodes[index].title = states[index].name
	_updated_state_node.emit(index)


func _on_state_script_update(index: int):
	_stateNodes[index] = _build_node(index)
	_updated_state_node.emit(index)


func _rebuild_nodes():
	_stateNodes.clear()
	_startingNode = _build_starting_node()
	for state in states.size():
		if states[state] == null: continue
		_stateNodes.append(_build_node(state))


func _build_starting_node():
	var newNode := StateNode.new()
	newNode.type = -1
	newNode.title = "START"
	newNode.events = []
	newNode.position_offset = _graphStartingNode.pos
	newNode.configure_starting()
	newNode.outputs[0] = _graphStartingNode.output
	return newNode


func _build_node(index: int):
	var newNode := StateNode.new()
	newNode.type = index
	newNode.title = states[index].name
	newNode.events = states[index].exitEvents
	newNode.configure(index)
	return newNode


func _update_graph_node(node: StateNode):
	if node.id == -1:
		_graphStartingNode.pos = node.position_offset
		_graphStartingNode.output = node.outputs[0]
	else:
		var dataNode := _find_node_from_id(node.id)
		if dataNode == null:
			_graphData.append(_NodeData.new())
			dataNode = _graphData.back()
			dataNode.id = node.id
		dataNode.pos = node.position_offset
		dataNode.type = node.type
		dataNode.outputs = node.outputs.duplicate()
	emit_changed()
	_save_resource()


func _delete_graph_node(id: int):
	var node := _find_node_from_id(id)
	if node == null: return
	_graphData.erase(node)
	emit_changed()
	_save_resource()


func _get(property: StringName):
	if property.begins_with("states/"):
		if property.get_slice('/', 1) == "starting":
			var prop = property.get_slice('/', 2)
			match prop:
				"position": 
					return _graphStartingNode.pos
				"output":
					return _graphStartingNode.output
			return null
		var idStr := property.get_slice('/', 1)
		if not idStr.is_valid_int():
			return null
		var id := idStr.to_int()
		var node := _find_node_from_id(id)
		if node == null:
			_graphData.append(_NodeData.new())
			node = _graphData.back()
			node.id = id
		var prop = property.get_slice('/', 2)
		match prop:
			"position": 
				return node.pos
			"type":
				return node.type
			"outputs":
				return node.outputs
	return null


func _set(property: StringName, value):
	if property.begins_with("states/"):
		if property.get_slice('/', 1) == "starting":
			var prop = property.get_slice('/', 2)
			match prop:
				"position":
					_graphStartingNode.pos = value
					return true
				"output":
					_graphStartingNode.output = value
					return true
			return false
		var idStr := property.get_slice('/', 1)
		if not idStr.is_valid_int():
			return false
		var id := idStr.to_int()
		var node := _find_node_from_id(id)
		if node == null:
			_graphData.append(_NodeData.new())
			node = _graphData.back()
			node.id = id
		var prop = property.get_slice('/', 2)
		match prop:
			"position": 
				node.pos = value
				return true
			"type":
				node.type = value
				return true
			"outputs":
				node.outputs = value
				return true
	return false


func _get_property_list():
	var list: Array = []
	var template: Dictionary = {"name": null, "type": null, "usage": PROPERTY_USAGE_NO_EDITOR}
	var startingPosEntry = template.duplicate()
	startingPosEntry["name"] = "states/starting/position"
	startingPosEntry["type"] = TYPE_VECTOR2
	list.append(startingPosEntry)
	var startingOutputEntry = template.duplicate()
	startingOutputEntry["name"] = "states/starting/output"
	startingOutputEntry["type"] = TYPE_INT
	list.append(startingOutputEntry)
	for node in _graphData:
		var root: String = "states/%s/" % node.id
		var posEntry := template.duplicate()
		posEntry["name"] = root + "position"
		posEntry["type"] = TYPE_VECTOR2
		list.append(posEntry)
		var typeEntry := template.duplicate()
		typeEntry["name"] = root + "type"
		typeEntry["type"] = TYPE_INT
		list.append(typeEntry)
		var outputEntry := template.duplicate()
		outputEntry["name"] = root + "outputs"
		outputEntry["type"] = TYPE_PACKED_INT32_ARRAY
		list.append(outputEntry)
	return list


func _find_node_from_id(id: int) -> _NodeData:
	for node in _graphData:
		if node.id == id: 
			return node
	return null


var flaggedForSave: bool = false
func _save_resource():
	if not flaggedForSave:
		flaggedForSave = true
		_save.call_deferred()


func _save():
	flaggedForSave = false
	ResourceSaver.save(self, resource_path)
