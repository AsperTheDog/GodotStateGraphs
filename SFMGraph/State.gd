
class_name State extends RefCounted
## Base class for custom States for the State Machine
## 
## This class is made to be overriden by your custom scripts. All custom states must, at minimum,
## fulfill the following requirements:
## [br] - The script must contain an Enumerator with the name [code]ExitEvents[/code]. This
## enumerator must [b]not[/b] be empty and custom values must [b]not[/b] be set for the elements.
## [br] - The script must override [method _on_check].
## [br][br]
## Every element in [code]ExitEvents[/code] will be shown as an output when a node is instantiated.
## By connecting other nodes to said outputs transitions can be configured.
## The State Machine will transition from this state when [method _on_check] returns any value of
## type ExitEvents.
## [br][br]
## Any variable marked with the property [constant @GlobalScope.PROPERTY_USAGE_STORAGE]
## (can be done by simply setting it as [code]@export[/code]) will be exposed in a per-node basis in the State
## Machine, the behavior being similar to that of the inspector in the Godot Editor. Currently,
## only variables of types [String], [int], [float] and [bool] are supported
## @tutorial (Overview): https://github.com/AsperTheDog/GodotStateGraphs/wiki/Components

## Name of the state. Set automatically by the State Machine at runtime.
var state_name: String
## ID of the state. Set automatically by the State Machine at runtime.
var state_id: int
## ID of the node. Set automatically by the State Machine at runtime.
var node_id: int


## Override this method to create custom behavior when the State Machine sets this node as active.
## The variable receives the StateMachineNode currently executing the State Machine as argument
func _on_enter(_stateMachine: StateMachineNode):
	pass


## Override this method to create custom behavior when this node stops being the active node in a 
## State Machine. The variable receives the StateMachineNode currently executing the State Machine 
## as argument
func _on_exit(_stateMachine: StateMachineNode):
	pass


## This method must be overriden to let the State Machine know when to transition and to what node.
## The variable receives the StateMachineNode currently executing the State Machine as argument
func _on_check(_stateMachine: StateMachineNode):
	pass


## Override this method to create custom behavior that will be executed on every evaluation while 
## this node is active. The variable receives the StateMachineNode currently executing the State 
## Machine as argument
func _on_eval(_stateMachine: StateMachineNode):
	pass
