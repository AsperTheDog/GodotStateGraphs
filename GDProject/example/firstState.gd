extends State

enum ExitEvents {
	First,
	Second
}

@export var customText: String

var counter := 0.0

func _on_enter(_stateMachine: StateMachineNode):
	counter = 0


func _on_exit(_stateMachine: StateMachineNode):
	print("Exiting node said the following: ", customText)


func _on_check(_stateMachine: StateMachineNode):
	if counter >= 1:
		return ExitEvents.First if randf() > 0.5 else ExitEvents.Second


func _on_frame(stateMachine: StateMachineNode):
	counter += stateMachine.get_process_delta_time()
