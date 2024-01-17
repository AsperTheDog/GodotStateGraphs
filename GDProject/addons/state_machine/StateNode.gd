@tool
class_name StateNode extends GraphNode

var id: int
var type: int
var properties: Dictionary = {}
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
	_set_container()
	if properties.is_empty():
		custom_minimum_size.x = 150
	else:
		custom_minimum_size.x = 250
	var counter: int = 0
	for event in events:
		add_child(_get_event_label(event))
		set_slot_enabled_right(counter, true)
		set_slot_color_right(counter, Color.DEEP_SKY_BLUE)
		counter += 1
		outputs.append(-1)
	set_slot_enabled_left(0, true)
	set_slot_color_left(0, Color.ROYAL_BLUE)
	if not properties.is_empty():
		var sep := HSeparator.new()
		sep.name = "separator"
		add_child(sep)
	for property in properties.values():
		add_child(_get_export_field(property))


func configure_starting():
	id = -1
	_set_container()
	custom_minimum_size.x = 150
	var input: Label = Label.new()
	input.text = ""
	input.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(input)
	set_slot_enabled_right(0, true)
	outputs.append(-1)


func reconfigure(newType: int, newTitle: String, newEvents: Array[String], newProperties: Dictionary):
	type = newType
	title = newTitle
	var counter: int = 0
	for node in get_children():
		remove_child(node)
		node.queue_free()
	events = newEvents.duplicate()
	var newOutputs: Array[int] = []
	for event in events:
		add_child(_get_event_label(event))
		set_slot_enabled_right(counter, true)
		set_slot_color_right(counter, Color.DEEP_SKY_BLUE)
		counter += 1
		if newOutputs.size() >= outputs.size(): newOutputs.append(-1)
		else: newOutputs.append(outputs[newOutputs.size()])
	set_slot_enabled_left(0, true)
	set_slot_color_left(0, Color.ROYAL_BLUE)
	outputs = newOutputs
	for property in newProperties.values():
		if property.name in properties:
			property.value = properties[property.name].value
	properties = newProperties
	if not properties.is_empty():
		var sep := HSeparator.new()
		sep.name = "separator"
		add_child(sep)
	for property in properties.values():
		add_child(_get_export_field(property))


func _set_container():
	var hbox := get_titlebar_hbox()
	var titleLabel: Label = hbox.get_child(0)
	titleLabel.label_settings = LabelSettings.new()
	titleLabel.label_settings.outline_size = 1


func _get_export_field(export: StateResource.ExportElement) -> Control:
	var hbox := HBoxContainer.new()
	var label := Label.new()
	label.text = export.name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hbox.add_child(label)
	match export.type:
		TYPE_INT:
			var field := EditorSpinSlider.new()
			field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			field.allow_greater = true
			field.allow_lesser = true
			field.step = 1
			field.value = export.value
			field.value_changed.connect((func(value, key): properties[key].value = value).bind(export.name))
			hbox.add_child(field)
		TYPE_STRING:
			var field := LineEdit.new()
			field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			field.text = export.value
			field.text_changed.connect((func(value, key): properties[key].value = value).bind(export.name))
			hbox.add_child(field)
		TYPE_FLOAT:
			var field := EditorSpinSlider.new()
			field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			field.allow_greater = true
			field.allow_lesser = true
			field.step = 0.005
			field.value = export.value
			field.hide_slider = true
			field.value_changed.connect((func(value, key): properties[key].value = value).bind(export.name))
			hbox.add_child(field)
		TYPE_BOOL:
			var field := CheckBox.new()
			field.toggled.connect((func(value, key): properties[key].value = value).bind(export.name))
			hbox.add_child(field)
	return hbox


static func create(type: int, newTitle: String, newEvents: Array[String], exports: Dictionary, pos: Vector2 = Vector2.ZERO) -> StateNode:
	var newState := StateNode.new()
	newState.type = type
	newState.title = newTitle
	newState.properties = exports.duplicate()
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
