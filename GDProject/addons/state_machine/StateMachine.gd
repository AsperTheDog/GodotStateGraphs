@tool
class_name StateMachine extends Resource

signal _states_deleted(ids: Array[int])
signal _states_added(ids: Array[int])

signal _state_name_changed(id: int)
signal _state_script_changed(id: int)

class NodeData:
	var id: int
	var pos: Vector2
	var state: StateResource
	var outputs: Array[int]
	var exports: Dictionary
	
	func update_property(value, property: String):
		exports[property].value = value
		exports[property].dirty = value != state.exports[property].value
	
	func duplicate() -> NodeData:
		var newData := NodeData.new()
		newData.id = id
		newData.pos = pos
		newData.state = state
		newData.outputs = outputs.duplicate()
		newData.exports = exports
		newData.dereference_exports()
		return newData
	
	func recalculate_script_data():
		while state.exitEvents.size() > outputs.size():
			outputs.append(-1)
		while state.exitEvents.size() < outputs.size():
			outputs.pop_back()
		var newExports: Dictionary = {}
		for export in state.exports.values():
			newExports[export.name] = export.duplicate()
			if export.name in exports:
				newExports[export.name].value = exports[export.name].value
				newExports[export.name].dirty = exports[export.name].value != export.value
		exports = newExports
	
	static func create_starting() -> NodeData:
		var newRes := NodeData.new()
		newRes.id = -2
		newRes.state = null
		newRes.outputs.append(-1)
		return newRes
	
	func dereference_exports():
		var newExports: Dictionary = {}
		for export in exports.values():
			newExports[export.name] = exports[export.name].duplicate()
		exports = newExports


@export var states: Array[StateResource] = []:
	set(value):
		var added: Array[int] = []
		for index in value.size():
			if value[index] == null:
				value[index] = StateResource.new()
			var elem = value[index]
			if not elem in states:
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

var _startingNode := NodeData.create_starting()
var _graphData: Array[NodeData] = []

static var stateIDcounter: int = 0


func _create_node_resource(id: int, stateID: int, pos: Vector2) -> NodeData:
	var newRes := NodeData.new()
	newRes.id = id
	newRes.pos = pos
	newRes.state = _find_state_from_id(stateID)
	newRes.recalculate_script_data()
	return newRes


func _add_node_resource(resource: NodeData):
	var res = _find_node_from_id(resource.id)
	if res != null: return
	_graphData.append(resource)
	emit_changed()
	_save_resource()


func _delete_node_resource(id: int):
	var res := _find_node_from_id(id)
	if res == null: return
	_graphData.erase(res)
	emit_changed()
	_save_resource()


func _find_state_from_id(id: int) -> StateResource:
	for state in states:
		if state == null: continue
		if state.id == id:
			return state
	return null


func _find_node_from_id(id: int) -> NodeData:
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


func _get(property: StringName):
	if property.begins_with("states/"):
		if property.get_slice('/', 1) == "starting":
			var prop = property.get_slice('/', 2)
			match prop:
				"position": 
					return _startingNode.pos
				"output":
					return _startingNode.outputs[0]
			return null
		var idStr := property.get_slice('/', 1)
		if not idStr.is_valid_int():
			return null
		var id := idStr.to_int()
		var node := _find_node_from_id(id)
		if node == null:
			_graphData.append(NodeData.new())
			node = _graphData.back()
			node.id = id
		var prop = property.get_slice('/', 2)
		match prop:
			"position": 
				return node.pos
			"type":
				return node.state.id
			"outputs":
				return node.outputs
			"exports":
				var exportName = property.get_slice('/', 3)
				if exportName not in node.exports: return null
				return node.exports[exportName].value
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
					_startingNode.outputs[0] = value
					return true
			return false
		var idStr := property.get_slice('/', 1)
		if not idStr.is_valid_int():
			return false
		var id := idStr.to_int()
		var node := _find_node_from_id(id)
		if node == null:
			_graphData.append(NodeData.new())
			node = _graphData.back()
			node.id = id
		var prop = property.get_slice('/', 2)
		match prop:
			"position": 
				node.pos = value
				return true
			"type":
				node.state = _find_state_from_id(value)
				node.exports = node.state.exports
				node.dereference_exports()
				return true
			"outputs":
				node.outputs = value
				return true
			"exports":
				var exportName = property.get_slice('/', 3)
				if exportName not in node.state.exports: return false
				node.exports[exportName] = node.state.exports[exportName].duplicate()
				node.update_property(value, exportName)
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
		for export in node.exports.values():
			if not export.dirty: continue
			var exportEntry := template.duplicate()
			exportEntry["name"] = root + "exports/" + export.name
			exportEntry["type"] = export.type
			list.append(exportEntry)
	return list
