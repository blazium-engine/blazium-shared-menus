@tool
class_name LanguageButton
extends CustomOptionButton

@export var shared_settings: SharedSettings

var locales: PackedStringArray = [
	"ar",  # Arabic
	"bg",  # Bulgarian
	"cs",  # Czech
	"da",  # Danish
	"de",  # German
	"el",  # Greek
	"en",  # English
	"es_ES",  # Spanish - Spain
	"es",  # Spanish - Latin America
	"fi",  # Finnish
	"fr",  # French
	"hu",  # Hungarian
	"id",  # Indonesian
	"it",  # Italian
	"ja",  # Japanese
	"ko",  # Korean
	"nl",  # Dutch
	"no",  # Norwegian
	"pl",  # Polish
	"pt",  # Portuguese - Portugal
	"pt_BR",  # Portuguese - Brazil
	"ro",  # Romanian
	"ru",  # Russian
	"sv",  # Swedish
	"th",  # Thai
	"tr",  # Turkish
	"uk",  # Ukrainian
	"vi",  # Vietnamese
	"zh_CN",  # Chinese - Simplified
	"zh_TW"   # Chinese - Traditional
]

var locale_names: PackedStringArray = [
	"العربية",                # Arabic
	"български език",       # Bulgarian
	"čeština",              # Czech
	"Dansk",                # Danish
	"Deutsch",              # German
	"Ελληνικά",             # Greek
	"English",              # English
	"Español (España)",     # Spanish - Spain
	"Español (Latinoamérica)",  # Spanish - Latin America
	"suomi",                # Finnish
	"Français",             # French
	"magyar",               # Hungarian
	"Bahasa Indonesia",     # Indonesian
	"Italiano",             # Italian
	"日本語",                 # Japanese
	"한국어",                 # Korean
	"Nederlands",           # Dutch
	"Norsk",                # Norwegian
	"Polski",               # Polish
	"Português",            # Portuguese - Portugal
	"Português do Brasil",  # Portuguese - Brazil
	"Română",               # Romanian
	"Русский",              # Russian
	"Svenska",              # Swedish
	"ไทย",                  # Thai
	"Türkçe",               # Turkish
	"Українська",           # Ukrainian
	"Tiếng Việt",           # Vietnamese
	"简体中文",              # Chinese - Simplified
	"繁體中文"               # Chinese - Traditional
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
	shared_settings.config.set_value("Settings", "lang", locales[index])
	shared_settings.config.save("user://blazium.cfg")
