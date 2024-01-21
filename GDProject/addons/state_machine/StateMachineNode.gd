@tool
class_name StateMachineNode extends Node
## A node used to store and execute State Machines
##
## The State Machine Node is used to manage a State Machine. To create these just add a [StateNode]
## to it and populate the list of custom states (For information about how to do it see [State]).
## [br][br]
## When an instance of this node is selected a dock will appear at the bottom. Through this dock you
## can edit the state machine.

## Called when [member stateMachine] is changed. This is used mainly for internal
## detection, but is available externally too if needed. The signal will [b]not[/b] be called
## when the resource is changed internally, only when the variable is set.
signal state_machine_assigned

## Enumerator used to set [member step_rate]
enum RateType {
	## Evaluate the currently active node automatically on every frame.
	PROCESS, 
	## Evaluate the currently active node automatically on every physics frame.
	PHYSICS_PROCESS, 
	## Do not evaluate the currently active node automatically. 
	## [method evaluate] must be called.
	CUSTOM
	}

## For internal use only. Do not use
enum _OutputType {VALID, INVALID, NULL}

class StateInstance:
	var node_data: StateMachine.NodeData
	var base_node: State
	var connected_nodes: Array[StateInstance] = []

	func _to_string():
		return str(base_node) + " -> " + str(connected_nodes)

## The [Resource] that contains all the relevant data of your State Machine.
@export var stateMachine: StateMachine:
	set(value):
		if stateMachine == value: return
		stateMachine = value
		state_machine_assigned.emit()

## Determines execution rate.
@export var step_rate: RateType = RateType.PROCESS
## When true, the State Machine will begin execution automatically on [method Node._ready].
## [br] See also [method start_or_resume].
@export var auto_start: bool = true
## When true, the State Machine will automatically reset and start whenever a node requests 
## a transition to [code]null[/code]. [br] See also [method start_or_resume] and [method reset].
@export var auto_restart: bool = false
## When true, the State Machine will call [method State._on_frame] right after it calls 
## [method State._on_enter]. When false, the State Machine will start calling 
## [method State._on_frame] in the next evaluation.
@export var frame_on_transition: bool = false
## Export variable to attach a desired custom Node to the State Machine. This is useful to have 
## access to any node of choice inside the states.
@export var customTarget: Node

## The state machine will only execute when [code]true[/code]. Setting this value to 
## [code]false[/code] will freeze the state machine 
## until it is set to [code]true[/code] again. Manually setting this variable directly has the 
## effect of calling [method start_or_resume] if set to [code]true[/code] and [method pause] if set 
## to [code]false[/code]
var executing: bool = false:
	set(value):
		executing = value
		if executing == true and _pendingOnEnter and _activeState != null:
			_pendingOnEnter = false
			_activeState.base_node._on_enter(self)

var _activeState: StateInstance = null
var _stateInstances: Dictionary = {}
var _jumpInstances: Dictionary = {}

var _pendingOnEnter: bool = false

func _ready():
	if Engine.is_editor_hint(): return
	_stateInstances.clear()
	for node: StateMachine.NodeData in stateMachine._graphData:
		var newStateInst := StateInstance.new()
		newStateInst.base_node = node.state.scriptResource.new()
		newStateInst.node_data = node
		newStateInst.base_node.node_id = node.id
		newStateInst.base_node.state_id = node.state.id
		newStateInst.base_node.state_name = node.state.name
		if node.state.is_jump_state():
			var keyword: String = newStateInst.node_data.exports["keyword"].value
			newStateInst.base_node.set("keyword", keyword)
			if keyword in _jumpInstances:
				push_warning("More than one JUMP node with the keyword '%s'. Repeating keywords will lead to undefined behavior" % keyword)
			_jumpInstances[keyword] = newStateInst
		else:
			_stateInstances[node.id] = newStateInst
	for node: StateMachine.NodeData in stateMachine._graphData:
		if node.state.is_jump_state():
			_jumpInstances[node.exports["keyword"].value].connected_nodes.append(null if node.outputs[0] == -1 else _stateInstances[node.outputs[0]])
		else: for output in node.outputs:
			_stateInstances[node.id].connected_nodes.append(null if output == -1 else _stateInstances[output])
	reset(true)
	if auto_start:
		start_or_resume()


func _process(delta: float):
	if Engine.is_editor_hint() or step_rate != RateType.PROCESS: return
	_evaluate()


func _physics_process(delta: float):
	if Engine.is_editor_hint() or step_rate != RateType.PHYSICS_PROCESS: return
	_evaluate()


## Resumes execution of the State Machine. If it has halted then [method reset] must be called 
## before to restart the machine.
func start_or_resume():
	executing = true


## Pauses the State Machine. 
func pause():
	executing = false


## Stops the State Machine. [member executing] will be set to [code]false[/code] and a 
## [method reset] call will be necessary to turn the State Machine on again.
## When the active node requests a transition to [code]null[/code], this behavior will take place.
func halt():
	executing = false
	_activeState = null


## Resets the State Machine. [member executing] will be set to [code]false[/code] and the active 
## node will be set to the starting node. If [member auto_restart] is set to [code]true[/code], 
## [method start_or_resume] will be called immediately after.
func reset(ignore_auto: bool = false):
	executing = false
	if stateMachine._startingNode.outputs[0] == -1: _activeState = null
	else: _activeState = _stateInstances[stateMachine._startingNode.outputs[0]]
	_pendingOnEnter = true
	for inst in _stateInstances.values():
		for variable in inst.node_data.exports:
			inst.base_node.set(variable, inst.node_data.exports[variable].value)
	if auto_restart and not ignore_auto:
		start_or_resume()


## Manually forces an evaluation in the State Machine. An evaluation has the following steps:[br]
##[br]1. Call [method State._on_check] and retrive the return value.
##[br]2. If the return value is a valid output value and the connected node is valid, execute 
## [method State._on_exit], set the new node to the returned node and call [method Node._on_enter].
##[br]3. If the return value is a valid output value but no valid node is connected to that 
## output, the State Machine halts (see [method halt]).
##[br]4. If the return value is not a valid value or [member frame_on_transition] is true, 
## call [method State._on_frame].
func evaluate():
	_evaluate()


## Given a valid Jump State node with the provided [param keyword], the State Machine will 
## transition directly to the connected node independently to what node is currently active.
## The parameters [param call_on_exit] and [param call_on_enter] will determine if the relevant
## method calls will be called in the transition process.
func jump_to(keyword: String, call_on_exit: bool = true, call_on_enter: bool = true):
	if keyword not in _jumpInstances: 
		push_error("Tried to jump to non-existant keyword jump '", keyword, "'")
		return
	_transition(_jumpInstances[keyword])


func _evaluate():
	if not executing: return
	if _activeState == null:
		executing = false
		if auto_restart:
			reset()
		return
	var ret = _activeState.base_node._on_check(self)
	var ret_type := _get_output_type(ret)
	match ret_type:
		_OutputType.NULL:
			_transition(null)
		_OutputType.INVALID:
			_activeState.base_node._on_frame(self)
		_OutputType.VALID:
			_transition(_activeState.connected_nodes[ret])


func _transition(next: StateInstance, call_on_exit: bool = true, call_on_enter: bool = true):
	if _activeState != null and call_on_exit:
		_activeState.base_node._on_exit(self)
	_activeState = next
	if _activeState != null and call_on_enter:
		_activeState.base_node._on_enter(self)
		if frame_on_transition:
			_activeState.base_node._on_frame(self)


func _get_output_type(output) -> _OutputType:
	if output == null or not output is int:
		return _OutputType.INVALID
	if output < 0 or output >= _activeState.connected_nodes.size():
		return _OutputType.NULL
	return _OutputType.VALID
