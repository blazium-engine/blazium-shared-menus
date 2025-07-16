@tool
class_name LanguageButton
extends CustomOptionButton

var locales: PackedStringArray = [
	"en"
]

var locale_names: PackedStringArray = [
	"English"
]

func _ready():
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	if Engine.is_editor_hint():
		return
	
	var last_full_locale: String = TranslationServer.get_locale()
	var last_locale: String = last_full_locale.split("_")[0]
	var selected_language: int = -1
	if locales.size() != locale_names.size():
		return;

	# First select full locale, if present
	for i in locales.size():
		if locales[i] == last_full_locale:
			selected_language = i
			break;
	# If not, select root locale
	if selected_language == -1:
		for i in locales.size():
			if locales[i] == last_locale:
				selected_language = i
				break;
	# If nothing, select English
	if selected_language == -1:
		selected_language = 6
	
	for locale_name in locale_names:
		add_icon_item(icon, locale_name)
	selected = selected_language
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
	SettingsAutoload.user_locale = locales[index]
	SettingsAutoload.config.set_value("Settings", "lang", locales[index])
	SettingsAutoload.config.save("user://blazium.cfg")
