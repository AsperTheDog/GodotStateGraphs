extends State

enum ExitEvents { Finished }

@export var targetAxis: int

var tween: Tween


func _on_enter(stateMachine: StateMachineNode):
	tween = stateMachine.create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(stateMachine.customTarget.mesh, "rotation", deg_to_rad(targetAxis * 10), 0.1)


func _on_check(_stateMachine: StateMachineNode):
	if not tween.is_running():
		return ExitEvents.Finished
