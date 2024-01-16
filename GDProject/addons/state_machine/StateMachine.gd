@tool
class_name StateMachine extends Resource

signal _states_deleted(ids: Array[int])
signal _states_added(ids: Array[int])

signal _state_name_changed(id: int)
signal _state_script_changed(id: int)

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
		var added: Array[int] = []
		for elem in value:
			if not elem in states and elem != null:
				if elem.id == -1:
					while _find_state_from_id(stateIDcounter) != null and stateIDcounter not in added: 
						stateIDcounter += 1
					elem.id = stateIDcounter
				elem._name_updated.connect(_on_state_name_changed.bind(elem.id))
				elem._script_updated.connect(_on_state_script_changed.bind(elem.id))
				added.append(elem.id)
		var deleted: Array[int] = []
		for elem in states:
			if not elem in value and elem != null:
				elem._name_updated.disconnect(_on_state_name_changed)
				elem._script_updated.disconnect(_on_state_script_changed)
				deleted.append(elem.id)
		states = value
		if not added.is_empty(): _states_added.emit(added)
		if not deleted.is_empty(): _states_deleted.emit(deleted)
		emit_changed()

var _startingNode := _StartingNode.new()
var _graphData: Array[_NodeData] = []

static var stateIDcounter: int = 0


func _update_graph_node(node: StateNode):
	if node.id == -1:
		_startingNode.pos = node.position_offset
		_startingNode.output = node.outputs[0]
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
					return _startingNode.pos
				"output":
					return _startingNode.output
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
					_startingNode.pos = value
					return true
				"output":
					_startingNode.output = value
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
		var typeEntry := template.duplicate()
		typeEntry["name"] = root + "type"
		typeEntry["type"] = TYPE_INT
		list.append(typeEntry)
		var posEntry := template.duplicate()
		posEntry["name"] = root + "position"
		posEntry["type"] = TYPE_VECTOR2
		list.append(posEntry)
		var outputEntry := template.duplicate()
		outputEntry["name"] = root + "outputs"
		outputEntry["type"] = TYPE_PACKED_INT32_ARRAY
		list.append(outputEntry)
	return list


func _find_state_from_id(id: int) -> StateResource:
	for state in states:
		if state == null: continue
		if state.id == id:
			return state
	return null


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


func _on_state_name_changed(id: int):
	_state_name_changed.emit(id)


func _on_state_script_changed(id: int):
	_state_script_changed.emit(id)


func get_valid_states() -> Array[StateResource]:
	return states.filter(func(state: StateResource): return state != null and state.is_valid())
