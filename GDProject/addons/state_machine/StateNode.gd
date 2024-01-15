@tool
class_name StateNode extends GraphNode

var type: int
var events: Array[String] = []
var id: int
var outputs: Array[int] = []

func configure(newID: int):
	id = newID
	set_container()
	var input: Label = Label.new()
	input.text = ""
	input.autowrap_mode = TextServer.AUTOWRAP_OFF
	var sep: HSeparator = HSeparator.new()
	sep.name = "sep"
	sep.set("theme_override_constants/separation", 20) 
	add_child(input)
	add_child(sep)
	set_slot_enabled_left(0, true)
	set_slot_color_left(0, Color.YELLOW)
	
	var counter: int = 2
	for event in events:
		var field: Label = Label.new()
		field.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		field.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		field.autowrap_mode = TextServer.AUTOWRAP_OFF
		field.text = event
		add_child(field)
		set_slot_enabled_right(counter, true)
		set_slot_color_right(counter, Color.AQUA)
		counter += 1
		outputs.append(-1)


func configure_starting():
	id = -1
	set_container()
	var input: Label = Label.new()
	input.text = ""
	input.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(input)
	set_slot_enabled_right(0, true)
	outputs.append(-1)


func set_container():
	custom_minimum_size.x = 120
	var hbox := get_titlebar_hbox()
	var titleLabel: Label = hbox.get_child(0)
	titleLabel.label_settings = LabelSettings.new()
	titleLabel.label_settings.outline_size = 2


static func create(type: int, newTitle: String, outputs: Array[String], pos: Vector2 = Vector2.ZERO):
	var newState := StateNode.new()
	newState.type = type
	newState.title = newTitle
	newState.events = outputs
	newState.position_offset = pos
	newState.configure(type)
	return newState


static func create_starting(output: int, pos: Vector2 = Vector2.ZERO):
	var newNode := StateNode.new()
	newNode.type = -1
	newNode.title = "START"
	newNode.events = []
	newNode.position_offset = pos
	newNode.configure_starting()
	newNode.outputs[0] = output
	return newNode


func _to_string():
	return "(%s) -> {id: %s, type: %s, position: %s, outputs: %s}" % [get_instance_id(), id, type, position_offset, outputs]
