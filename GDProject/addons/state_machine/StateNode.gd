@tool
class_name StateNode extends GraphNode

signal internal_var_updated

var id: int
var properties: Dictionary = {}
var outputs: Array[int] = []

var resource: StateResource


func _to_string():
	return "(%s) -> {id: %s, type: %s, position: %s, outputs: %s}" % [get_instance_id(), id, resource.id, position_offset, outputs]


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
	for event in resource.exitEvents:
		add_child(_get_event_label(event))
		set_slot_enabled_right(counter, true)
		set_slot_color_right(counter, Color.DEEP_SKY_BLUE)
		counter += 1
		outputs.append(-1)
	set_slot_enabled_left(0, true)
	set_slot_color_left(0, Color.ROYAL_BLUE)
	_add_exports()


func configure_starting():
	title = resource.name
	id = -1
	_set_container()
	custom_minimum_size.x = 150
	var input: Label = Label.new()
	input.text = ""
	input.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(input)
	set_slot_enabled_right(0, true)
	outputs.append(-1)


func reconfigure():
	title = resource.name
	var counter: int = 0
	for node in get_children():
		set_slot_enabled_right(counter, false)
		counter += 1
		remove_child(node)
		node.queue_free()
	custom_minimum_size = Vector2(1, 1)
	size = Vector2(1, 1)
	var newOutputs: Array[int] = []
	counter = 0
	for event in resource.exitEvents:
		add_child(_get_event_label(event))
		set_slot_enabled_right(counter, true)
		set_slot_color_right(counter, Color.DEEP_SKY_BLUE)
		counter += 1
		if newOutputs.size() >= outputs.size(): newOutputs.append(-1)
		else: newOutputs.append(outputs[newOutputs.size()])
	set_slot_enabled_left(0, true)
	set_slot_color_left(0, Color.ROYAL_BLUE)
	outputs = newOutputs
	var newProperties: Dictionary = {}
	for property in resource.exportVariables.values():
		newProperties[property.name] = property.duplicate()
		if property.name in properties and properties[property.name].dirty:
			newProperties[property.name].value = properties[property.name].value
			newProperties[property.name].dirty = true
	properties = newProperties
	if properties.is_empty():
		custom_minimum_size.x = 150
	else:
		custom_minimum_size.x = 250
	_add_exports()
	position_offset += Vector2.ONE
	position_offset -= Vector2.ONE
	

func _set_container():
	var hbox := get_titlebar_hbox()
	var titleLabel: Label = hbox.get_child(0)
	titleLabel.label_settings = LabelSettings.new()
	titleLabel.label_settings.outline_size = 1


func _add_exports():
	if not properties.is_empty():
		var sep := HSeparator.new()
		sep.set("theme_override_constants/separation", 10)
		sep.name = "separator"
		add_child(sep)
	var count := 0
	for property in properties.values():
		count += 1
		var hbox: HBoxContainer = _get_export_field(property)
		add_child(hbox)
		var sep := HSeparator.new()
		sep.set("theme_override_styles/separator", StyleBoxEmpty.new())
		sep.set("theme_override_constants/separation", 5)
		add_child(sep)


func _get_export_field(export: StateResource.ExportElement) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.name = export.name
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text = export.name
	label.name = "label"
	hbox.add_child(label)
	match export.type:
		TYPE_INT:
			var field = (EditorSpinSlider as Variant).new()
			field.name = "field"
			field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			field.allow_greater = true
			field.allow_lesser = true
			field.step = 1
			field.value = export.value
			field.value_changed.connect(_on_property_updated.bind(export.name))
			hbox.add_child(field)
		TYPE_STRING:
			var field := LineEdit.new()
			field.name = "field"
			field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			field.text = export.value
			field.text_changed.connect(_on_property_updated.bind(export.name))
			hbox.add_child(field)
		TYPE_FLOAT:
			var field = (EditorSpinSlider as Variant).new()
			field.name = "field"
			field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			field.allow_greater = true
			field.allow_lesser = true
			field.step = 0.005
			field.value = export.value
			field.hide_slider = true
			field.value_changed.connect(_on_property_updated.bind(export.name))
			hbox.add_child(field)
		TYPE_BOOL:
			var field := CheckBox.new()
			field.name = "field"
			field.alignment = HORIZONTAL_ALIGNMENT_CENTER
			field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			field.toggled.connect(_on_property_updated.bind(export.name))
			hbox.add_child(field)
	if export.dirty:
		hbox.get_node("label").self_modulate = Color.GOLD
	else:
		hbox.get_node("label").self_modulate = Color.WHITE
	return hbox


static func create(id: int, resource: StateResource, pos: Vector2 = Vector2.ZERO) -> StateNode:
	var newState := StateNode.new()
	newState.resource = resource
	newState.title = resource.name
	newState.properties = {}
	for property in resource.exportVariables.values():
		newState.properties[property.name] = property.duplicate()
	newState.position_offset = pos
	newState.configure(id)
	return newState


static func create_starting(output: int, pos: Vector2 = Vector2.ZERO) -> StateNode:
	var newNode := StateNode.new()
	newNode.resource = StateResource.new()
	newNode.resource.id = -2
	newNode.resource.name = "START"
	newNode.position_offset = pos
	newNode.configure_starting()
	newNode.outputs[0] = output
	return newNode


func force_property_update(value, key):
	_change_property_value(value, key)
	var field := get_node(key + "/field")
	match resource.exportVariables[key].type:
		TYPE_INT: field.set_value_no_signal(value)
		TYPE_FLOAT: field.set_value_no_signal(value)
		TYPE_STRING: field.text = value
		TYPE_BOOL: field.set_pressed_no_signal(value)


func _on_property_updated(value, key):
	_change_property_value(value, key)
	internal_var_updated.emit()


func _change_property_value(value, key):
	properties[key].value = value
	properties[key].dirty = properties[key].value != resource.exportVariables[key].value
	if has_node(key):
		if properties[key].dirty:
			get_node(key + "/label").self_modulate = Color.GOLD
		else:
			get_node(key + "/label").self_modulate = Color.WHITE
