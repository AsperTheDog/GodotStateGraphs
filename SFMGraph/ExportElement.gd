class_name ExportElement extends RefCounted

var name: String
var type: int
var value

var dirty: bool = false

func _init(name: String, type: int, defaultValue):
	self.name = name
	self.type = type
	self.value = defaultValue

func duplicate() -> ExportElement:
	var newRes := ExportElement.new(name, type, value)
	newRes.dirty = dirty
	return newRes
