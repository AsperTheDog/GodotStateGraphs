@tool
class_name StateMachineNode extends Node

signal state_machine_assigned

enum RateType {PROCESS, PHYSICS_PROCESS, CUSTOM}
enum OutputType {VALID, INVALID, NULL}

class StateInstance:
	var node_data: StateMachine.NodeData
	var base_node: State
	var connected_nodes: Array[StateInstance] = []

	func _to_string():
		return str(base_node) + " -> " + str(connected_nodes)

@export var stateMachine: StateMachine:
	set(value):
		if stateMachine == value: return
		stateMachine = value
		state_machine_assigned.emit()

@export var step_rate: RateType = RateType.PROCESS
@export var auto_start: bool = true
@export var auto_restart: bool = false
@export var frame_on_transition: bool = false

var executing: bool = false

var activeState: StateInstance = null
var _stateInstances: Dictionary = {}

var _pendingOnEnter: bool = false

func _ready():
	if Engine.is_editor_hint(): return
	_stateInstances.clear()
	for state in stateMachine._graphData:
		var newStateInst := StateInstance.new()
		newStateInst.base_node = stateMachine._find_state_from_id(state.type).state.new()
		newStateInst.node_data = state
		newStateInst.base_node.node_id = state.id
		newStateInst.base_node.state_id = state.type
		newStateInst.base_node.state_name = stateMachine._find_state_from_id(state.type).name
		_stateInstances[state.id] = newStateInst
	for state in stateMachine._graphData:
		for output in state.outputs:
			if output == -1: 
				_stateInstances[state.id].connected_nodes.append(null)
				continue
			_stateInstances[state.id].connected_nodes.append(_stateInstances[output])
	reset(true)
	if auto_start:
		start()


func _process(delta: float):
	if Engine.is_editor_hint() or step_rate != RateType.PROCESS: return
	_evaluate()


func _physics_process(delta: float):
	if Engine.is_editor_hint() or step_rate != RateType.PHYSICS_PROCESS: return
	_evaluate()


func start():
	executing = true
	if _pendingOnEnter and activeState != null:
		_pendingOnEnter = false
		activeState.base_node._on_enter(self)


func pause():
	executing = false


func reset(ignore_auto: bool = false):
	executing = false
	if stateMachine._startingNode.output == -1: activeState = null
	else: activeState = _stateInstances[stateMachine._startingNode.output]
	_pendingOnEnter = true
	for inst in _stateInstances.values():
		for variable in inst.node_data.exports:
			inst.base_node.set(variable, inst.node_data.exports[variable].value)
	if auto_restart and not ignore_auto:
		start()


func evaluate():
	_evaluate()


func _evaluate():
	if not executing: return
	if activeState == null:
		executing = false
		if auto_restart:
			reset()
		return
	var ret = activeState.base_node._on_check(self)
	var ret_type := _get_output_type(ret)
	match ret_type:
		OutputType.NULL:
			_transition(null)
		OutputType.INVALID:
			activeState.base_node._on_frame(self)
		OutputType.VALID:
			_transition(activeState.connected_nodes[ret])


func _transition(next: StateInstance):
	if activeState != null:
		activeState.base_node._on_exit(self)
	activeState = next
	if activeState != null:
		activeState.base_node._on_enter(self)
		if frame_on_transition:
			activeState.base_node._on_frame(self)


func _get_output_type(output) -> OutputType:
	if output == null or not output is int:
		return OutputType.INVALID
	if output < 0 or output >= activeState.connected_nodes.size():
		return OutputType.NULL
	return OutputType.VALID
