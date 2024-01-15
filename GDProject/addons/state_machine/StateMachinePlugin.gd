@tool
extends EditorPlugin

var smUI: Control = preload("res://addons/state_machine/StateMachineUI.tscn").instantiate()


func _enter_tree():
	smUI.undoRedo = get_undo_redo()
	EditorInterface.get_selection().selection_changed.connect(on_node_selected)
	on_node_selected()


func _exit_tree():
	setDock(false)
	smUI.queue_free()


func on_node_selected():
	var nodes := EditorInterface.get_selection().get_selected_nodes()
	if nodes.size() > 0 and nodes[0] is StateMachineNode:
		smUI.set_target(nodes[0])
		setDock(true)
	else:
		smUI.set_target(null)
		setDock(false)


var dockShown: bool = false
func setDock(show: bool):
	if dockShown and show or not dockShown and not show: return
	if show: 
		add_control_to_bottom_panel(smUI, "State Machine")
		make_bottom_panel_item_visible(smUI)
	else: remove_control_from_bottom_panel(smUI)
	dockShown = show
