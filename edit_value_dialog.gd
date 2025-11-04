extends ConfirmationDialog

@onready var line_edit: LineEdit = $VBoxContainer/LineEdit

func _on_line_edit_text_submitted(new_text: String) -> void:
	#self._ok_pressed()
	get_ok_button().pressed.emit()
	pass

func _on_line_edit_editing_toggled(toggled_on: bool) -> void:
	line_edit.select_all()
	line_edit.grab_focus()
	pass # Replace with function body.
