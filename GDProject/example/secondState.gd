extends State

enum ExitEvents {
	Finished22
}

@export var example: String = "que noooo"

var counter := 0.0

func _on_enter(_stateMachine: StateMachineNode):
	counter = 0


func _on_exit(_stateMachine: StateMachineNode):
	print("SECOND STATE END COUNTING WITH VALUE ", counter, ", NODE DATA (%s, %s, %s)" % [node_id, state_id, state_name])


func _on_check(_stateMachine: StateMachineNode):
	if counter >= 1:
		return ExitEvents.Finished22


func _on_frame(stateMachine: StateMachineNode):
	counter += stateMachine.get_process_delta_time()
