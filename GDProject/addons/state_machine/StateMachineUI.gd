@tool
extends Control

class Connection:
	var from_node: int
	var from_port: int
	var to_node: int
	var to_port: int
	
	func _init(from_node_arg: int, from_port_arg: int, to_node_arg: int, to_port_arg: int):
		from_node = from_node_arg
		from_port = from_port_arg
		to_node = to_node_arg
		to_port = to_port_arg
	
	func is_equal(other: Connection):
		return from_node == other.from_node and from_port == other.from_port and to_node == other.to_node and to_port == other.to_port
	
	func is_connection_in_array(list: Array[Connection]):
		for elem in list:
			if is_equal(elem): return true
		return false


class ClipboardNode:
	var id: int
	var pos: Vector2
	var type: int
	var outputs: Array[int]
	var properties: Dictionary
	
	func _init(id: int, pos: Vector2, type: int, outputs: Array[int], properties: Dictionary):
		self.id = id
		self.pos = pos
		self.type = type
		self.outputs = outputs.duplicate()
		self.properties = properties.duplicate(true)


var clipboard: Array[ClipboardNode] = []


var target: StateMachineNode = null:
	set(value):
		target = value
		on_target_SFM_assigned()

var targetResource: StateMachine = null:
	set(value):
		if targetResource == value: return
		if targetResource != null:
			targetResource._states_added.disconnect(on_states_added)
			targetResource._states_deleted.disconnect(on_states_deleted)
			targetResource._state_name_changed.disconnect(on_state_change_name)
			targetResource._state_script_changed.disconnect(on_state_change_script)
		targetResource = value
		if targetResource != null: 
			targetResource._states_added.connect(on_states_added)
			targetResource._states_deleted.connect(on_states_deleted)
			targetResource._state_name_changed.connect(on_state_change_name)
			targetResource._state_script_changed.connect(on_state_change_script)
		if is_node_ready(): configure()

var undoRedo: EditorUndoRedoManager

@onready var dialogAddButton: Button = $newNodePop.get_ok_button()
@onready var graph: GraphEdit = $GraphEdit


func _ready():
	var example := NodePath("root/branch1/branch2/leaf")
	graph.popup_request.connect(on_mouse_interaction)
	graph.connection_request.connect(on_connection)
	graph.disconnection_request.connect(on_disconnection)
	graph.node_selected.connect(on_node_selected)
	graph.node_deselected.connect(on_node_deselected)
	graph.delete_nodes_request.connect(on_delete_request)
	graph.connection_to_empty.connect(on_connection_to_empty)
	graph.begin_node_move.connect(begin_move_node)
	graph.end_node_move.connect(end_move_node)
	
	$newNodePop/ItemList.item_selected.connect(on_item_selected)
	$newNodePop.confirmed.connect(on_confirmed)
	
	$PopupMenu.id_pressed.connect(on_context_select)
	configure()


func _unhandled_key_input(event: InputEvent):
	if not graph.has_focus(): return
	if event.is_action("ui_copy"):
		copy(false)
		get_viewport().set_input_as_handled()
	elif event.is_action("ui_cut"):
		copy(true)
		get_viewport().set_input_as_handled()
	elif event.is_action("ui_paste"):
		paste()
		get_viewport().set_input_as_handled()
	elif event.is_action("ui_graph_duplicate"):
		duplicate_selection()
		get_viewport().set_input_as_handled()


var mouse_pos: Vector2 = Vector2.ZERO
func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = event.position - global_position


func handle_resource_change(resource: Resource):
	if targetResource == null: return
	for state in targetResource.states:
		if state == null or state.state == null: continue
		if state.state.resource_path == resource.resource_path:
			state.state = state.state
			break


func clean():
	graph.clear_connections()
	selected_nodes.clear()
	for node in graph.get_children(): 
		graph.remove_child(node)
		node.queue_free()
	$newNodePop/ItemList.clear()
	$ColorRect.color = EditorInterface.get_editor_settings().get("interface/theme/base_color")
	$ColorRect.show()
	$ColorRect.mouse_filter = MOUSE_FILTER_STOP


func configure():
	clean()
	if targetResource == null: return
	$ColorRect.hide()
	$ColorRect.mouse_filter = MOUSE_FILTER_IGNORE
	populate_item_list()
	var newStartingNode := StateNode.create_starting(targetResource._startingNode.output, targetResource._startingNode.pos)
	graph.add_child(newStartingNode)
	var invalid_nodes: Array[int] = []
	for node in targetResource._graphData:
		if not targetResource._find_state_from_id(node.type) in targetResource.get_valid_states():
			invalid_nodes.append(node.id)
			continue
		var newNode := create_node_action(node.type, node.pos, node.id, node.exports, false)
		for export in node.exports.values():
			if export.dirty:
				newNode.force_property_update(export.value, export.name)
	for node_id in invalid_nodes:
		targetResource._delete_graph_node(node_id)
	if targetResource._startingNode.output != -1:
		var target := find_node_from_id(targetResource._startingNode.output)
		if target != null:
			create_connection_action(Connection.new(-1, 0, target.id, 0), false)
	for node in targetResource._graphData:
		for index in node.outputs.size():
			if node.outputs[index] == -1: continue
			var target := find_node_from_id(node.outputs[index])
			if target != null:
				create_connection_action(Connection.new(node.id, index, target.id, 0), false)


func set_target(node: StateMachineNode):
	if target != null: target.state_machine_assigned.disconnect(on_target_SFM_assigned)
	target = node
	if target != null: target.state_machine_assigned.connect(on_target_SFM_assigned)


func on_target_SFM_assigned():
	if target == null: targetResource = null
	else: targetResource = target.stateMachine


func on_states_added(ids: Array[int]):
	populate_item_list()


func on_states_deleted(ids: Array[int]):
	for node: StateNode in graph.get_children():
		if node.resource.id in ids:
			delete_node_no_undo(node.id)
	populate_item_list()


func on_state_change_name(id: int):
	for node in graph.get_children():
		if node.resource.id == id:
			node.title = targetResource._find_state_from_id(id).name
	populate_item_list()


func on_state_change_script(id: int):
	var state := targetResource._find_state_from_id(id)
	if not state.is_valid(): 
		on_states_deleted([id])
		return
	var states := targetResource.get_valid_states()
	for node in graph.get_children():
		if node.resource.id == id:
			prune_excess_connections(node, node.resource.exitEvents.size())
			node.reconfigure()
	populate_item_list()


func prune_excess_connections(node: StateNode, newOutputSize: int):
	for connection in graph.get_connection_list():
		if connection['from_node'] == node.name and connection["from_port"] >= newOutputSize:
			var to_node := find_node_from_name(connection['to_node'])
			var oldConn := Connection.new(node.id, connection['from_port'], to_node.id, connection['to_port'])
			delete_connection_action(oldConn)


func on_force_script_reload():
	for state in targetResource.states:
		if state != null: state.state = state.state


var item_ids: Array[int] = []
func populate_item_list():
	$newNodePop/ItemList.clear()
	item_ids.clear()
	for state in targetResource.get_valid_states():
		$newNodePop/ItemList.add_item(state.name)
		item_ids.append(state.id)


func update_resource_from_id(id: int):
	var node := find_node_from_id(id)
	targetResource._update_graph_node(node)


#region Graph API
func on_connection(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	create_connection(Connection.new(find_node_from_name(from_node).id, from_port, find_node_from_name(to_node).id, to_port))


func on_disconnection(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	delete_connection(Connection.new(find_node_from_name(from_node).id, from_port, find_node_from_name(to_node).id, to_port))


var selected_nodes: Array[StateNode] = []
func on_node_selected(node: Node):
	selected_nodes.append(node)


func on_node_deselected(node: Node):
	selected_nodes.erase(node)


func set_selection(ids: Array[int]):
	for node in graph.get_children():
		if node.id in ids:
			node.selected = true
		else:
			node.selected = false


func duplicate_selection():
	var dupList: Array[ClipboardNode] = []
	for node in selected_nodes:
		if node.id == -1: continue
		dupList.append(ClipboardNode.new(node.id, node.position_offset, node.resource.id, node.outputs, node.properties))
	duplicate_nodes(dupList, Vector2(10, 10))


func on_delete_request(nodes: Array[StringName]):
	var nodeIDs: Array[int] = []
	for node: String in nodes:
		if graph.has_node(node):
			nodeIDs.append(find_node_from_name(node).id)
	if nodeIDs.is_empty(): return
	delete_nodes(nodeIDs)


func on_delete_selection():
	var nodeIDs: Array[int] = []
	for node: StateNode in selected_nodes:
		nodeIDs.append(node.id)
	if nodeIDs.is_empty(): return
	delete_nodes(nodeIDs)


func on_mouse_interaction(pos: Vector2):
	if selected_nodes.is_empty():
		on_popup_request()
	else:
		on_context_request()


func on_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2):
	inputNodeID = find_node_from_name(from_node).id
	inputNodePort = from_port
	inputNodeRequest = true
	on_popup_request()
#endregion


func on_context_request():
	var shouldDisable: bool = selected_nodes.size() == 1 and selected_nodes[0].id == -2
	$PopupMenu.set_item_disabled(2, shouldDisable)
	$PopupMenu.set_item_disabled(3, shouldDisable)
	$PopupMenu.set_item_disabled(4, clipboard.is_empty())
	$PopupMenu.set_item_disabled(5, shouldDisable)
	$PopupMenu.set_item_disabled(6, shouldDisable)
	$PopupMenu.set_item_disabled(8, clipboard.is_empty())
	$PopupMenu.position = mouse_pos + get_screen_position()
	$PopupMenu.show()


func on_context_select(id: int):
	match id:
		0: on_popup_request()
		2: copy(true)
		3: copy(false)
		4: paste()
		5: on_delete_selection()
		6: duplicate_selection()
		8: clipboard.clear()


#region New Node Handler
var inputNodeID: int
var inputNodePort: int
var inputNodeRequest: bool = false
func on_popup_request():
	get_screen_position()
	$newNodePop.position = mouse_pos + get_screen_position() - ($newNodePop.size / 2.0)
	if $newNodePop/ItemList.get_selected_items().is_empty():
		dialogAddButton.disabled = true
	$newNodePop.show()
	dialogAddButton.release_focus()


var selectedItem: int = 0
func on_item_selected(index: int):
	if not $newNodePop/ItemList.get_selected_items().is_empty():
		dialogAddButton.disabled = false
		selectedItem = item_ids[index]


func on_confirmed():
	create_node()
#endregion


#region Basic Actions
static var nodeIDCounter: int = 0
func create_node():
	undoRedo.create_action("Create state")
	while find_node_from_id(nodeIDCounter) != null:
		nodeIDCounter += 1
	var newID = nodeIDCounter
	undoRedo.add_do_method(self, "create_node_action", selectedItem, (graph.scroll_offset + mouse_pos) / graph.zoom, newID, {})
	var newIDcontainer: Array[int] = [newID]
	undoRedo.add_do_method(self, "set_selection", newIDcontainer)
	if inputNodeRequest:
		inputNodeRequest = false
		var newConn: Connection = Connection.new(inputNodeID, inputNodePort, newID, 0)
		undoRedo.add_do_method(self, "create_connection_action", newConn)
		undoRedo.add_undo_method(self, "delete_connection_action", newConn)
	undoRedo.add_undo_method(self, "delete_node_action", newID)
	undoRedo.commit_action()


func delete_nodes(ids: Array[int], is_cut: bool = false):
	undoRedo.create_action("%s state(s)" % ("Cut" if is_cut else "Delete"))
	ids.erase(-1)
	var connections: Array[Connection] = []
	for id in ids:
		var node := find_node_from_id(id)
		for connection in graph.get_connection_list():
			if connection['from_node'] == node.name or connection['to_node'] == node.name:
				var from_node_id := find_node_from_name(connection['from_node']).id
				var to_node_id := find_node_from_name(connection['to_node']).id
				var newConn: Connection = Connection.new(from_node_id, connection['from_port'], to_node_id, connection['to_port'])
				undoRedo.add_do_method(self, "delete_connection_action", newConn)
				if not newConn.is_connection_in_array(connections):
					connections.append(newConn)
	for id in ids:
		var node := find_node_from_id(id)
		undoRedo.add_do_method(self, "delete_node_action", id)
		undoRedo.add_undo_method(self, "create_node_action", node.resource.id, node.position_offset, id, node.properties)
	for connection in connections:
		undoRedo.add_undo_method(self, "create_connection_action", connection)
	undoRedo.commit_action()


func create_connection(conn: Connection):
	if conn.from_node == conn.to_node: return
	undoRedo.create_action("Create connection")
	var from_node_name = get_node_name(conn.from_node)
	var connections: Array[Connection] = []
	for line in graph.get_connection_list():
		if line['from_port'] == conn.from_port and line['from_node'] == from_node_name:
			var conn_to_node_id = find_node_from_name(line['to_node']).id
			var oldConn := Connection.new(conn.from_node, line['from_port'], conn_to_node_id, line['to_port'])
			undoRedo.add_do_method(self, "delete_connection_action", oldConn)
			connections.append(oldConn)
	undoRedo.add_do_method(self, "create_connection_action", conn)
	undoRedo.add_undo_method(self, "delete_connection_action", conn)
	for connection in connections:
		undoRedo.add_undo_method(self, "create_connection_action", connection)
	undoRedo.commit_action()


func delete_connection(conn: Connection):
	undoRedo.create_action("Delete connection")
	undoRedo.add_do_method(self, "delete_connection_action", conn)
	undoRedo.add_undo_method(self, "create_connection_action", conn)
	undoRedo.commit_action()


func begin_move_node():
	undoRedo.create_action("Move state(s)")
	for node in selected_nodes:
		undoRedo.add_undo_method(self, "move_node_action", node.id, node.position_offset)


func end_move_node():
	for node in selected_nodes:
		undoRedo.add_do_method(self, "move_node_action", node.id, node.position_offset)
		targetResource._update_graph_node(node)
	undoRedo.commit_action(false)


func move_node_action(id: int, pos: Vector2):
	var node := find_node_from_id(id)
	node.position_offset = pos


func create_node_action(stateID: int, pos: Vector2, id: int, exports: Dictionary = {}, update_data: bool = true) -> StateNode:
	if find_node_from_id(id) != null: 
		push_error("Duplicated id when creating a node, if you see this report it as a bug")
	var states := targetResource.get_valid_states()
	var state := targetResource._find_state_from_id(stateID)
	if state == null or not state.is_valid(): 
		push_error("Attempted to create node of invalid state %s" % state)
		return
	var newNode := StateNode.create(id, state, pos)
	graph.add_child(newNode)
	newNode.internal_var_updated.connect(update_resource_from_id.bind(newNode.id))
	for export in exports.values():
		if export.dirty:
			newNode.force_property_update(export.value, export.name)
	if update_data:
		targetResource._update_graph_node(newNode)
	return newNode


func delete_node_no_undo(id: int):
	var node := find_node_from_id(id)
	for connection in graph.get_connection_list():
		if connection['from_node'] == node.name or connection['to_node'] == node.name:
			var from_node_id := find_node_from_name(connection['from_node']).id
			var to_node_id := find_node_from_name(connection['to_node']).id
			var newConn: Connection = Connection.new(from_node_id, connection['from_port'], to_node_id, connection['to_port'])
			delete_connection_action(newConn, false)
	delete_node_action(id)


func delete_node_action(id: int, update_data: bool = true):
	var node := find_node_from_id(id)
	if node.id == -2: return
	node.queue_free()
	if node in selected_nodes:
		selected_nodes.erase(node)
	if update_data:
		targetResource._delete_graph_node(node.id)


func create_connection_action(conn: Connection, update_data: bool = true):
	var from_node := find_node_from_id(conn.from_node)
	var to_node := find_node_from_id(conn.to_node)
	graph.connect_node(from_node.name, conn.from_port, to_node.name, conn.to_port)
	from_node.outputs[conn.from_port] = conn.to_node
	if update_data:
		targetResource._update_graph_node(from_node)


func delete_connection_action(conn: Connection, update_data: bool = true):
	var from_node := find_node_from_id(conn.from_node)
	var to_node := find_node_from_id(conn.to_node)
	graph.disconnect_node(from_node.name, conn.from_port, to_node.name, conn.to_port)
	from_node.outputs[conn.from_port] = -1
	if update_data:
		targetResource._update_graph_node(from_node)
#endregion


#region Copy Paste
func copy(delete: bool):
	clipboard.clear()
	for node in selected_nodes:
		if node.id == -1: continue
		clipboard.append(ClipboardNode.new(node.id, node.position_offset, node.resource.id, node.outputs, node.properties))
	if delete:
		var ids: Array[int] = []
		for node in selected_nodes:
			ids.append(node.id)
		delete_nodes(ids, true)


func get_clipboard_rect() -> Rect2:
	if clipboard.is_empty(): return Rect2(Vector2.ZERO, Vector2.ZERO)
	var positions: Array[Vector2]
	var minPosition: Vector2
	for node in clipboard:
		positions.append(node.pos)
	var pos := positions.min()
	var rect := Rect2(pos, positions.max() - pos)
	return rect


func paste():
	if clipboard.is_empty(): return
	var graph_mouse: Vector2 = (graph.scroll_offset + mouse_pos) / graph.zoom - (get_clipboard_rect().size * 0.5)
	duplicate_nodes(clipboard, graph_mouse, true)
#endregion


#region Advanced Actions
func duplicate_nodes(nodes: Array[ClipboardNode], offset: Vector2, is_paste: bool = false):
	if nodes.is_empty(): return
	var idMappings := {}
	var newIDs: Array[int] = []
	undoRedo.create_action("%s state(s)" % ("Paste" if is_paste else "Duplicate"))
	for clNode in nodes:
		while find_node_from_id(nodeIDCounter) != null or nodeIDCounter in newIDs:
			nodeIDCounter += 1
		var newID = nodeIDCounter
		var newPos := clNode.pos - (get_clipboard_rect().position if is_paste else Vector2.ZERO)
		undoRedo.add_do_method(self, "create_node_action", clNode.type, newPos + offset, newID, clNode.properties)
		idMappings[clNode.id] = newID
		newIDs.append(newID)
	undoRedo.add_do_method(self, "set_selection", newIDs)
	for clNode in nodes:
		for index in clNode.outputs.size():
			if clNode.outputs[index] == -1 or clNode.outputs[index] not in idMappings: continue
			var newConn := Connection.new(idMappings[clNode.id], index, idMappings[clNode.outputs[index]], 0)
			undoRedo.add_do_method(self, "create_connection_action", newConn)
			undoRedo.add_undo_method(self, "delete_connection_action", newConn)
	for clNode in nodes:
		undoRedo.add_undo_method(self, "delete_node_action", idMappings[clNode.id])
	undoRedo.commit_action()
#endregion


func find_node_from_id(nodeID: int) -> StateNode:
	for node in graph.get_children():
		if node.id == nodeID: return node
	return null


func find_node_from_name(nodeName: StringName) -> StateNode:
	return graph.get_node(String(nodeName))


func get_node_name(source) -> String:
	if source is StateNode:
		return source.name
	if source is int:
		var node := find_node_from_id(source)
		return node.name
	return ""
