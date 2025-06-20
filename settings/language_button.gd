@tool
class_name LanguageButton
extends CustomOptionButton

@export var shared_settings: SharedSettings

@export var locales: PackedStringArray = [
	"en"
]

@export var locale_names: PackedStringArray = [
	"English"
]

func _ready():
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	if Engine.is_editor_hint():
		return
	
	var last_local: String = TranslationServer.get_locale()
	var selected_language: int = 0
	if locales.size() != locale_names.size():
		return;

	for i in locales.size():
		if locales[i] == locale_names[i]:
			selected_language = i;
			break;
	
	for locale_name in locale_names:
		add_item(locale_name);
	selected = selected_language;
	item_selected.connect(_set_language)
	
	super._ready()

func _get_configuration_warnings():
	var warnings: PackedStringArray = []
	if locales.size() != locale_names.size():
		warnings.append("locales and localeNames lengths must match")
	return warnings

func _set_language(index: int) -> void:
	if index < 0 || index >= locales.size():
		return;
	TranslationServer.set_locale(locales[index])
	if is_instance_valid(shared_settings) && is_instance_valid(shared_settings.config):
		shared_settings.config.set_value("Settings", "lang", locales[index])
		shared_settings.config.save("user://blazium.cfg")
