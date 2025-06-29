extends Control

@export var languages_hbox: HBoxContainer
@export var message_line_edit: LineEdit
@export var word_line_edit: LineEdit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for locale in TranslationServer.get_loaded_locales():
		var language_vbox:= VBoxContainer.new()
		language_vbox.custom_minimum_size.x = 400
		languages_hbox.add_child.call_deferred(language_vbox)
		var translation := TranslationServer.get_translation_object(locale)
		var lang_label := Label.new()
		lang_label.text = locale
		lang_label.custom_minimum_size.x = 400
		lang_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		language_vbox.add_child.call_deferred(lang_label)
		for message in translation.get_message_list():
			var message_line := LineEdit.new()
			message_line.editable = false
			var translation_message = translation.get_message(message)
			message_line.text = translation_message
			message_line.focus_entered.connect(_focus_entered.bind(message, translation_message))
			language_vbox.add_child.call_deferred(message_line)

func _focus_entered(message: String, translation_message: String):
	message_line_edit.text = message
	word_line_edit.text = translation_message


func _on_remove_pressed() -> void:
	for locale in TranslationServer.get_loaded_locales():
		var translation :Translation= TranslationServer.get_translation_object(locale)
		for message in translation.get_message_list():
			if message == message_line_edit.text:
				translation.erase_message(message)
		
		var err = ResourceSaver.save(translation, translation.resource_path +".res", ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
		if err != OK:
			print(err)


func _on_add_pressed() -> void:
	pass # Replace with function body.
