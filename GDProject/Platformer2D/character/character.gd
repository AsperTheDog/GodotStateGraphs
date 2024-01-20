extends CharacterBody2D

@export var horizSpeed: float = 100
@export var jumpForce: float = 500
@export var gravity: float = 980

@onready var mesh: MeshInstance2D = $MeshInstance2D
@onready var animTreeManager: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/playback")


func _ready():
	$MovementMachine.start_or_resume()
	$HorizMachine.start_or_resume()


func _process(_delta):
	moveHoriz()
	move_and_slide()


func moveHoriz():
	var axis := Input.get_axis("ui_left", "ui_right")
	velocity.x = axis * horizSpeed
