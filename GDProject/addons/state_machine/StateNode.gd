@tool
class_name StateNode extends GraphNode

var id: int
var type: int
var events: Array[String] = []
var outputs: Array[int] = []


func _to_string():
	return "(%s) -> {id: %s, type: %s, position: %s, outputs: %s}" % [get_instance_id(), id, type, position_offset, outputs]


func _get_event_label(event) -> Label:
	var field := Label.new()
	field.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	field.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	field.autowrap_mode = TextServer.AUTOWRAP_OFF
	field.text = event
	field.name = event
	return field


func configure(newID: int):
	id = newID
	set_container()
	var counter: int = 0
	for event in events:
		add_child(_get_event_label(event))
		set_slot_enabled_right(counter, true)
		set_slot_color_right(counter, Color.DEEP_SKY_BLUE)
		counter += 1
		outputs.append(-1)
	set_slot_enabled_left(0, true)
	set_slot_color_left(0, Color.ROYAL_BLUE)


func configure_starting():
	id = -1
	set_container()
	var input: Label = Label.new()
	input.text = ""
	input.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(input)
	set_slot_enabled_right(0, true)
	outputs.append(-1)


func reconfigure(newType: int, newTitle: String, newEvents: Array[String]):
	type = newType
	title = newTitle
	var counter: int = 0
	for event in events:
		var node = get_node(event)
		remove_child(get_node(event))
		node.queue_free()
	events = newEvents.duplicate()
	var newOutputs: Array[int] = []
	for event in events:
		add_child(_get_event_label(event))
		set_slot_enabled_right(counter, true)
		set_slot_color_right(counter, Color.DEEP_SKY_BLUE)
		counter += 1
		if newOutputs.size() >= outputs.size():
			newOutputs.append(-1)
		else:
			newOutputs.append(outputs[newOutputs.size()])
	set_slot_enabled_left(0, true)
	set_slot_color_left(0, Color.ROYAL_BLUE)
	outputs = newOutputs


func set_container():
	custom_minimum_size.x = 120
	var hbox := get_titlebar_hbox()
	var titleLabel: Label = hbox.get_child(0)
	titleLabel.label_settings = LabelSettings.new()
	titleLabel.label_settings.outline_size = 1


static func create(type: int, newTitle: String, newEvents: Array[String], pos: Vector2 = Vector2.ZERO) -> StateNode:
	var newState := StateNode.new()
	newState.type = type
	newState.title = newTitle
	newState.events = newEvents.duplicate()
	newState.position_offset = pos
	newState.configure(type)
	return newState


static func create_starting(output: int, pos: Vector2 = Vector2.ZERO) -> StateNode:
	var newNode := StateNode.new()
	newNode.type = -2
	newNode.title = "START"
	newNode.events = []
	newNode.position_offset = pos
	newNode.configure_starting()
	newNode.outputs[0] = output
	return newNode
