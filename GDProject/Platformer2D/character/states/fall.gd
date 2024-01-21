extends State

enum ExitEvents { landed }


func _on_enter(_stateMachine: StateMachineNode):
	print("fall")


func _on_check(stateMachine: StateMachineNode):
	if stateMachine.customTarget.is_on_floor():
		return ExitEvents.landed


func _on_frame(stateMachine: StateMachineNode):
	stateMachine.customTarget.velocity.y += (stateMachine.customTarget.gravity * Vector2.DOWN).y * stateMachine.get_physics_process_delta_time()
