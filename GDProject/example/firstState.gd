extends State

enum ExitEvents {
	First,
	Second
}

var counter := 0.0

func _on_enter(stateMachine: StateMachineNode):
	counter = 0


func _on_exit(stateMachine: StateMachineNode):
	print("FIRST STATE END COUNTING WITH VALUE ", counter, ", NODE DATA (%s, %s, %s)" % [node_id, state_id, state_name])


func _on_check(stateMachine: StateMachineNode):
	if counter >= 1:
		return ExitEvents.First if randf() > 0.5 else ExitEvents.Second


func _on_frame(stateMachine: StateMachineNode):
	counter += stateMachine.get_process_delta_time()
