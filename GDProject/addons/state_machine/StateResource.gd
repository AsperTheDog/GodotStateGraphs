@tool
class_name StateResource extends Resource

signal _name_updated
signal _script_updated
signal _color_updated


@export var scriptResource: Script:
	set(value):
		if _check_state(value):
			scriptResource = value
			_script_updated.emit()

@export var name: String = "":
	set(value):
		if name == value: return
		name = value
		_name_updated.emit()

@export var connectionColor: Color = Color.WHITE:
	set(value):
		connectionColor = value
		_color_updated.emit()


var id: int = -1

var hasOnEnter: bool = false
var hasOnExit: bool = false
var hasOnFrame: bool = false

var exports: Dictionary = {}
var exitEvents: Array[String] = []

static var allowedExports: Array[int] = [TYPE_STRING, TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_VECTOR2, TYPE_VECTOR3]


func _init():
	_check_state(scriptResource)


func _check_state(stateArg: Script) -> bool:
	if stateArg == null: return true
	var elem = stateArg.new()
	if not elem is State:
		push_error("The script " + stateArg.resource_path + " does not extend State class")
		return false
	if "ExitEvents" not in elem or not elem.ExitEvents is Dictionary or elem.ExitEvents.size() == 0:
		push_error("The script " + stateArg.resource_path + " does not have an ExitEvents enumerator or is empty")
		return false
	var hasOnCheck: bool = false
	var counts := {"_on_check": 0, "_on_enter": 0, "_on_exit": 0, "_on_frame": 0}
	for method in elem.get_method_list():
		if method['name'] in counts: counts[method['name']] += 1
		else: continue
		if "_on_check" == method['name']:
			hasOnCheck = counts[method['name']] == 2
		if "_on_enter" == method['name']:
			hasOnEnter = counts[method['name']] == 2
		if "_on_exit" == method['name']:
			hasOnExit = counts[method['name']] == 2
		if "_on_frame" == method['name']:
			hasOnFrame = counts[method['name']] == 2
	if not hasOnCheck:
		push_error("The script " + stateArg.resource_path + " does not have the _on_check method overriden")
		return false
	exitEvents.clear()
	for event in elem.ExitEvents.keys():
		if elem.ExitEvents[event] != exitEvents.size():
			push_error("The script " + stateArg.resource_path + " has an incompatible ExitEvents enum. Do not assign custom numbers to the fields")
			return false
		exitEvents.append(event)
	exports.clear()
	for property in elem.get_property_list():
		if property["type"] in allowedExports \
		and property["usage"] & PROPERTY_USAGE_STORAGE == PROPERTY_USAGE_STORAGE \
		and property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE == PROPERTY_USAGE_SCRIPT_VARIABLE:
			exports[property["name"]] = ExportElement.new(property["name"], property["type"], elem.get(property["name"]))
	if name == "":
		name = stateArg.resource_path.get_file().trim_suffix(".gd")
	return true


func is_valid():
	return scriptResource != null and name.length() > 0


func _get(property: StringName):
	if property == "id":
		return id


func _set(property, value):
	if property == "id":
		id = value


func _get_property_list():
	return [{"name": "id", "type": TYPE_INT, "usage": PROPERTY_USAGE_NO_EDITOR}]
	
