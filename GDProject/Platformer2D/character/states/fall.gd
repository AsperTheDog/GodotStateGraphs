extends State

enum ExitEvents { terminado }

@export var soyInt: int
@export var soyFloat: float
@export var soyString: String
@export var soyBool: bool


func _on_enter(_stateMachine: StateMachineNode):
	print("fall")


func _on_check(stateMachine: StateMachineNode):
	if stateMachine.customTarget.is_on_floor():
		return ExitEvents.terminado


func _on_frame(stateMachine: StateMachineNode):
	stateMachine.customTarget.velocity.y += (stateMachine.customTarget.gravity * Vector2.DOWN).y * stateMachine.get_physics_process_delta_time()
