extends State

enum ExitEvents {
	Finished
}

var counter := 0.0

func _on_enter(stateMachine: StateMachineNode):
	counter = 0


func _on_exit(stateMachine: StateMachineNode):
	print("THIRD STATE END COUNTING WITH VALUE ", counter)


func _on_check(stateMachine: StateMachineNode):
	if counter >= 1:
		return ExitEvents.Finished


func _on_frame(stateMachine: StateMachineNode):
	counter += stateMachine.get_process_delta_time()
