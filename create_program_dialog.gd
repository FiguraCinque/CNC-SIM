extends ConfirmationDialog

@onready var program_number_edit: LineEdit = $VBoxContainer/ProgramNumberEdit

func _on_program_number_edit_text_submitted(new_text: String) -> void:
	#self._ok_pressed()
	get_ok_button().pressed.emit()
	pass

func _on_program_number_edit_editing_toggled(toggled_on: bool) -> void:
	program_number_edit.select_all()
	program_number_edit.grab_focus()
	pass # Replace with function body.
