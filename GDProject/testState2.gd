extends State


enum ExitEvents {
	Pico,
	Pala,
	Azada,
	Hacha
}


func _on_enter(stateMachine: StateMachine):
	pass


func _on_exit(stateMachine: StateMachine):
	pass


func _on_check(stateMachine: StateMachine) -> ExitEvents:
	return ExitEvents.Pico
