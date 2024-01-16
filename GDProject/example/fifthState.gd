extends State

enum ExitEvents {
	Raul,
	Beni,
	Chris
}

var counter := 0.0

func _on_enter(stateMachine: StateMachineNode):
	counter = 0


func _on_exit(stateMachine: StateMachineNode):
	print("FOURTH STATE END COUNTING WITH VALUE ", counter)


func _on_check(stateMachine: StateMachineNode):
	if counter >= 1:
		return ExitEvents.Raul


func _on_frame(stateMachine: StateMachineNode):
	counter += stateMachine.get_process_delta_time()
