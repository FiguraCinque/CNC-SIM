extends ConfirmationDialog

@onready var new_program_number_edit: LineEdit = $VBoxContainer/NewProgramNumberEdit

func _on_new_program_number_edit_text_submitted(new_text: String) -> void:
	get_ok_button().pressed.emit()
	pass # Replace with function body.

func _on_new_program_number_edit_editing_toggled(toggled_on: bool) -> void:
	new_program_number_edit.select_all()
	new_program_number_edit.grab_focus()
	pass # Replace with function body.
