extends State

enum ExitEvents { Jump }

@export var keyword: String

func _on_check(_stateMachine: StateMachineNode):
	return ExitEvents.Jump
