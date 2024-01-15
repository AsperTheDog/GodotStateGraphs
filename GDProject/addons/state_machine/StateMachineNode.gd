@tool
class_name StateMachineNode extends Node

signal state_machine_assigned

enum RateType {PROCESS, PHYSICS_PROCESS, CUSTOM}

class StateInstance:
	var id: int
	var baseNode: State
	var connectedNodes: Array[StateInstance] = []

	func _to_string():
		return str(baseNode) + " -> " + str(connectedNodes)

@export var stateMachine: StateMachine:
	set(value):
		if stateMachine == value: return
		stateMachine = value
		state_machine_assigned.emit()

@export var stepRate: RateType = RateType.PROCESS
@export var autostart: bool = true
@export var autoreset: bool = false

var activeState: StateInstance
var _stateInstances: Dictionary = {}


func _ready():
	if Engine.is_editor_hint(): return
	_stateInstances.clear()
	for state in stateMachine._graphData:
		var newStateInst := StateInstance.new()
		newStateInst.baseNode = stateMachine.states[state.type].state.new()
		_stateInstances[state.id] = newStateInst
	for state in stateMachine._graphData:
		for output in state.outputs:
			if output == -1: 
				_stateInstances[state.id].connectedNodes.append(null)
				continue
			_stateInstances[state.id].connectedNodes.append(_stateInstances[output])
	activeState = _stateInstances[stateMachine._graphStartingNode.output]


func _process(delta: float):
	if Engine.is_editor_hint() or stepRate != RateType.PROCESS: return
	_evaluate()


func _physics_process(delta: float):
	if Engine.is_editor_hint() or stepRate != RateType.PHYSICS_PROCESS: return
	_evaluate()


func evaluate():
	if stepRate != RateType.CUSTOM: return
	_evaluate()


func _evaluate():
	pass


func _transition():
	pass
