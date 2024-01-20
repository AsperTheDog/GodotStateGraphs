extends State

enum ExitEvents { zero, plus_one, minus_one }

@export var targetAxis: int

const exitTriggers := {-1: ExitEvents.minus_one, 0: ExitEvents.zero, 1: ExitEvents.plus_one}


func _on_check(stateMachine: StateMachineNode):
	var currentAxis = signi(stateMachine.customTarget.velocity.x)
	if targetAxis != currentAxis:
		return exitTriggers[currentAxis]
