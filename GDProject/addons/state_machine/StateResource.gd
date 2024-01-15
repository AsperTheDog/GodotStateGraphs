@tool
class_name StateResource extends Resource

signal nameUpdated
signal scriptUpdated

@export var name: String:
	set(value):
		if name == value: return
		name = value
		nameUpdated.emit()
		
@export var state: Script:
	set(value):
		if state == value: return
		if _check_state(value):
			state = value
			scriptUpdated.emit()

var approved: bool = false

var hasOnEnter: bool = false
var hasOnExit: bool = false
var hasOnFrame: bool = false

var exitEvents: Array[String] = []


func _init():
	_check_state(state)


func _check_state(stateArg: Script):
	if stateArg == null: return true
	var elem = stateArg.new()
	if not elem is State:
		printerr("Script does not extend State class")
		return false
	if "ExitEvents" not in elem or not elem.ExitEvents is Dictionary or elem.ExitEvents.size() == 0:
		printerr("The script " + stateArg.resource_path + " does not have an ExitEvents enumerator or is empty")
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
		printerr("The script " + stateArg.resource_path + " does not have the _on_check method overriden")
		return false
	exitEvents.clear()
	for event in elem.ExitEvents.keys():
		if elem.ExitEvents[event] != exitEvents.size():
			printerr("The script " + stateArg.resource_path + " has an incompatible ExitEvents enum. Do not assign custom numbers to the fields")
			return false
		exitEvents.append(event)
	return true
