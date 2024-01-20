extends State

enum ExitEvents { fall }

@export var jumpStrength: float = 500


func _on_enter(stateMachine: StateMachineNode):
	print("jump")
	stateMachine.customTarget.animTreeManager.travel("jump")
	stateMachine.customTarget.velocity.y = (jumpStrength * Vector2.UP).y


func _on_check(stateMachine: StateMachineNode):
	if stateMachine.customTarget.velocity.y >= 0:
		return ExitEvents.fall


func _on_frame(stateMachine: StateMachineNode):
	stateMachine.customTarget.velocity.y += (stateMachine.customTarget.gravity * Vector2.DOWN).y * stateMachine.get_physics_process_delta_time()
