@tool
class_name StateNode extends GraphNode

signal internal_var_updated

var resource: StateMachine.NodeData

var workingDir: String = get_script().resource_path.get_base_dir()
var icons: Dictionary = {
	"frame": load(workingDir + "/icons/onEval.svg"),
	"enter": load(workingDir + "/icons/onEnter.svg"),
	"exit": load(workingDir + "/icons/onExit.svg")
}


func _get_event_label(event) -> Label:
	var field := Label.new()
	field.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	field.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	field.autowrap_mode = TextServer.AUTOWRAP_OFF
	field.text = event
	field.name = event
	return field


func configure():
	_set_container()
	if resource.exports.is_empty():
		custom_minimum_size.x = 200
	else:
		custom_minimum_size.x = 300 if not resource.state.is_jump_state() else 200
	var counter: int = 0
	for event in resource.state.exitEvents:
		add_child(_get_event_label(event))
		set_slot_enabled_right(counter, true)
		counter += 1
	if not resource.state.is_jump_state():
		set_slot_enabled_left(0, true)
	_add_exports()
	update_colors()


func configure_starting():
	title = "START"
	_set_container()
	custom_minimum_size.x = 150
	var input: Label = Label.new()
	input.text = ""
	input.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(input)
	set_slot_enabled_right(0, true)


func reconfigure():
	title = resource.state.name
	add_container_icons()
	var counter: int = 0
	for node in get_children():
		set_slot_enabled_right(counter, false)
		counter += 1
		remove_child(node)
		node.queue_free()
	custom_minimum_size = Vector2(1, 1)
	size = Vector2(1, 1)
	counter = 0
	for event in resource.state.exitEvents:
		add_child(_get_event_label(event))
		set_slot_enabled_right(counter, true)
		counter += 1
	if not resource.state.is_jump_state():
		set_slot_enabled_left(0, true)
	if resource.exports.is_empty():
		custom_minimum_size.x = 200
	else:
		custom_minimum_size.x = 300 if not resource.state.is_jump_state() else 200
	_add_exports()
	update_colors()
	force_node_refresh()


func force_node_refresh():
	position_offset += Vector2.ONE
	position_offset -= Vector2.ONE


func update_colors():
	for index in get_child_count():
		if is_slot_enabled_left(index): set_slot_color_left(index, resource.state.connectionColor)
		if is_slot_enabled_right(index): set_slot_color_right(index, resource.state.connectionColor)
	force_node_refresh()


func add_container_icons():
	var hbox := get_titlebar_hbox()
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.size_flags_horizontal = Control.SIZE_SHRINK_END
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if hbox.has_node("onEnterIcon"): 
		var node := hbox.get_node("onEnterIcon")
		hbox.remove_child(node)
		node.queue_free()
	if hbox.has_node("onExitIcon"): 
		var node := hbox.get_node("onExitIcon")
		hbox.remove_child(node)
		node.queue_free()
	if hbox.has_node("onFrameIcon"): 
		var node := hbox.get_node("onFrameIcon")
		hbox.remove_child(node)
		node.queue_free()
	if resource.state.hasOnEnter:
		var newIcon := icon.duplicate()
		newIcon.texture = icons["enter"]
		newIcon.name = "onEnterIcon"
		hbox.add_child(newIcon)
	if resource.state.hasOnExit:
		var newIcon := icon.duplicate()
		newIcon.texture = icons["exit"]
		newIcon.name = "onExitIcon"
		hbox.add_child(newIcon)
	if resource.state.hasOnFrame:
		var newIcon := icon.duplicate()
		newIcon.texture = icons["frame"]
		newIcon.name = "onFrameIcon"
		hbox.add_child(newIcon)


func _set_container():
	var hbox := get_titlebar_hbox()
	var titleLabel: Label = hbox.get_child(0)
	titleLabel.label_settings = LabelSettings.new()
	titleLabel.label_settings.outline_size = 1
	titleLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if resource.state != null: add_container_icons()


func _add_exports():
	if not resource.exports.is_empty():
		var sep := HSeparator.new()
		sep.set("theme_override_constants/separation", 10)
		sep.name = "separator"
		add_child(sep)
	var count := 0
	for property in resource.exports.values():
		count += 1
		var hbox: HBoxContainer = _get_export_field(property)
		add_child(hbox)
		var sep := HSeparator.new()
		sep.set("theme_override_styles/separator", StyleBoxEmpty.new())
		sep.set("theme_override_constants/separation", 5)
		add_child(sep)


func _get_export_field(export: ExportElement) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.name = export.name
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text = export.name
	label.name = "label"
	label.self_modulate = Color.GOLD if export.dirty else Color.WHITE
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
			field.set_pressed_no_signal(export.value)
			field.toggled.connect(_on_property_updated.bind(export.name))
			hbox.add_child(field)
	if export.dirty:
		hbox.get_node("label").self_modulate = Color.GOLD
	else:
		hbox.get_node("label").self_modulate = Color.WHITE
	return hbox


static func create(resource: StateMachine.NodeData) -> StateNode:
	var newState := StateNode.new()
	newState.resource = resource
	newState.title = resource.state.name
	newState.position_offset = resource.pos
	newState.configure()
	return newState


static func create_starting(resource: StateMachine.NodeData) -> StateNode:
	var newNode := StateNode.new()
	newNode.resource = resource
	newNode.position_offset = resource.pos
	newNode.configure_starting()
	return newNode


func force_property_update(value, key):
	_change_property_value(value, key)
	var field := get_node(key + "/field")
	match resource.exportVariables[key].type:
		TYPE_INT: field.set_value_no_signal(value)
		TYPE_FLOAT: field.set_value_no_signal(value)
		TYPE_STRING: field.text = value
		TYPE_BOOL: field.set_pressed_no_signal(value)


func _on_property_updated(value, key: String):
	_change_property_value(value, key)
	internal_var_updated.emit()


func _change_property_value(value, key: String):
	resource.update_property(value, key)
	if has_node(key):
		get_node(key + "/label").self_modulate = Color.GOLD if resource.exports[key].dirty else Color.WHITE
