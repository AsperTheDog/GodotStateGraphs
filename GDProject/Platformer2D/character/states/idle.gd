extends State

enum ExitEvents { jump, run, fall }


func _on_enter(stateMachine: StateMachineNode):
	print("idle")
	stateMachine.customTarget.animTreeManager.travel("idle")


func _on_check(stateMachine: StateMachineNode):
	if Input.is_action_just_pressed("ui_accept"):
		return ExitEvents.jump
	if not stateMachine.customTarget.is_on_floor():
		return ExitEvents.fall
	if absf(stateMachine.customTarget.velocity.x) > 0.1:
		return ExitEvents.run
