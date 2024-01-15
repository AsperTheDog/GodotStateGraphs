extends GraphEdit


var mpos: Vector2
func _gui_input(event: InputEvent):
	if event is InputEventMouseMotion:
		mpos = event.position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$GraphNode.position_offset = (scroll_offset + mpos) / zoom
