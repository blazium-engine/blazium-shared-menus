extends Node

var filter_enabled := false

func set_filter_enabled(p_filter_enabled: bool):
	SettingsAutoload.config.set_value("Settings", "word_filter", p_filter_enabled)
	SettingsAutoload.save_config()
	filter_enabled = p_filter_enabled

var CHAR_SUBSTITUTIONS: Dictionary = {
	"a": ["a", "A", "4", "@", "á", "à", "â", "ã", "ä", "å", "æ", "∀", "∂", "α"],
	"b": ["b", "B", "8", "6", "|3", "ß", "þ", "β"],
	"c": ["c", "C", "<", "(", "[", "¢", "©", "ç"],
	"d": ["d", "D", "|)", "|]", "Ð", "ð"],
	"e": ["e", "E", "3", "€", "£", "ë", "ê", "è", "é", "ē", "Σ", "ε"],
	"f": ["f", "F", "ƒ", "ʃ", "⨎"],
	"g": ["g", "G", "9", "6", "&", "(_+"],
	"h": ["h", "H", "#", "|-|", "}{", "]-[", "ħ", "η"],
	"i": ["i", "I", "1", "!", "|", "][", "î", "ï", "ì", "í", "ī", "ι"],
	"j": ["j", "J", "_|", "_/", "¿"],
	"k": ["k", "K", "|<", "|{", "ɮ"],
	"l": ["l", "L", "1", "|_", "£", "][_", "ł", "λ"],
	"m": ["m", "M", "|\\/|", "/\\/\\", "^^", "µ"],
	"n": ["n", "N", "|\\|", "/\\/", "И", "и", "η", "π"],
	"o": ["o", "O", "0", "()", "[]", "°", "ö", "ô", "ò", "ó", "ø", "Ω", "θ", "σ"],
	"p": ["p", "P", "|°", "|>", "|*", "þ", "ρ"],
	"q": ["q", "Q", "9", "0_", "¶"],
	"r": ["r", "R", "|2", "|?", "®", "Я", "я", "ʁ"],
	"s": ["s", "S", "5", "$", "§", "š", "ß", "∫"],
	"t": ["t", "T", "7", "+", "†", "ț", "τ"],
	"u": ["u", "U", "|_|", "(_)", "µ", "û", "ü", "ù", "ú", "ū", "*"],
	"v": ["v", "V", "\\/", "√", "ν"],
	"w": ["w", "W", "\\/\\/", "vv", "Ш", "ш", "ω", "ψ"],
	"x": ["x", "X", "><", "}{", "×", "Ж", "ж", "χ"],
	"y": ["y", "Y", "`/", "¥", "ÿ", "ý", "γ"],
	"z": ["z", "Z", "2", "~/_", "ʒ", "ζ"]
}


func escape_regex(input:String) -> String:
	input = input.replace("\\", "\\\\")
	input = input.replace(".", "\\.")
	input = input.replace("^", "\\^")
	input = input.replace("$", "\\$")
	input = input.replace("*", "\\*")
	input = input.replace("+", "\\+")
	input = input.replace("?", "\\?")
	input = input.replace("(", "\\(")
	input = input.replace(")", "\\)")
	input = input.replace("[", "\\[")
	input = input.replace("]", "\\]")
	input = input.replace("{", "\\{")
	input = input.replace("}", "\\}")
	input = input.replace("|", "\\|")
	input = input.replace("-", "\\-")
	return input

var filter_dict: Dictionary = {
	# English
	"en": ["fuck", "shit", "cunt", "nigger", "bitch", "asshole", "whore", "slut", "dick", "pussy", "motherfucker", "retard", "faggot"],
	
	# Chinese (Simplified & Traditional)
	"zh_CN": ["操你妈", "傻逼", "混蛋", "狗日的", "他妈的"],
	"zh_TW": ["幹你娘", "白痴", "王八蛋", "靠北", "三小"],
	
	# Japanese
	"ja": ["くそ", "バカ", "チンカス", "死ね", "ファック", "クソ野郎"],
	
	# Korean
	"ko": ["씨발", "개새끼", "병신", "좆", "미친놈", "지랄"],
	
	# Russian
	"ru": ["блядь", "сука", "хуй", "пизда", "ебать", "гандон"],
	
	# Spanish (Spain & Latin America)
	"es": ["joder", "puta", "mierda", "cabrón", "pendejo", "hijo de puta", "coño", "verga", "maricón", "chinga", "pinche", "puto", "culero", "no mames"],
	
	# French
	"fr": ["putain", "merde", "connard", "enculé", "salope", "bite", "nique ta mère"],
	
	# German
	"de": ["scheiße", "arschloch", "hurensohn", "fick dich", "wichser", "schlampe"],
	
	# Portuguese (Portugal & Brazil)
	"pt": ["porra", "merda", "caralho", "puta", "foda-se", "viado"],
	"pt-BR": ["cu", "buceta", "arrombado", "filho da puta", "vai se fuder"],
	
	# Arabic
	"ar": ["كس", "كلب", "عاهر", "ابن الكلب", "شرموط"],
	
	# Turkish
	"tr": ["siktir", "orospu", "amk", "piç", "göt", "ananı sikeyim"],
	
	# Italian
	"it": ["cazzo", "merda", "stronzo", "puttana", "vaffanculo", "figlio di puttana"],
	
	# Dutch
	"nl": ["kut", "klootzak", "hoer", "tyfuslijer", "godverdomme"],
	
	# Polish
	"pl": ["kurwa", "pierdolić", "chuj", "jebać", "suka", "skurwysyn"],
	
	# Swedish
	"sv": ["fan", "helvete", "jävla", "skit", "kuk", "fitta"],
	
	# Finnish
	"fi": ["vittu", "perkele", "saatana", "paska", "mulukku", "huora"],
	
	# Other European Languages
	"hu": ["fasz", "buzi", "picsa", "köcsög", "geci"], # Hungarian
	"cs": ["kurva", "hovno", "piča", "zmrd", "sráč"], # Czech
	"da": ["lort", "røv", "fisse", "kraftedme", "pis"], # Danish
	"no": ["faen", "helvete", "kuk", "fitte", "jævel"], # Norwegian
	"ro": ["pula", "căcat", "pizdă", "mă-să", "futu-te"], # Romanian
	"el": ["μαλάκας", "σκατά", "πουτάνα", "αρχίδι", "γαμώτο"], # Greek
	"he": ["זין", "חארות", "בן זונה", "תחת", "לך תזדיין"], # Hebrew
	"th": ["เหี้ย", "ควย", "สัตว์", "เย็ด", "มึง"], # Thai
	"vi": ["đụ", "đĩ", "cặc", "lồn", "chó đẻ"], # Vietnamese
	"id": ["bangsat", "anjing", "kontol", "memek", "bajingan"], # Indonesian
	"uk": ["йоб", "сука", "пізда", "хуй", "блядь"], # Ukrainian
	"bg": ["майка ти", "кур", "гъз", "шибана", "мърда"], # Bulgarian
}


# Caches compiled regex patterns for better performance
var _regex_cache: Dictionary = {}

func filter_message(message: String) -> String:
	if !filter_enabled:
		return message
	var filter_array = filter_dict.get(SettingsAutoload.user_locale, [])
	var filtered_message = message
	
	for word in filter_array:
		# Get or compile the regex pattern for this word
		var regex = _get_regex_for_word(word)
		
		# Find all matches
		var results = regex.search_all(filtered_message)
		
		# Replace each match with censored version
		for result in results:
			var matched_word = result.get_string()
			var censor = ""
			for _i in matched_word.length():
				censor += "*"
			filtered_message = filtered_message.replace(matched_word, censor)
	
	return filtered_message

# Compiles (or retrieves from cache) a regex pattern for a given word
func _get_regex_for_word(word: String) -> RegEx:
	if _regex_cache.has(word):
		return _regex_cache[word]
	
	var regex_pattern := ""
	
	for i in range(word.length()):
		var char = word[i].to_lower()
		
		# Add optional separator characters (like spaces, underscores, etc.)
		if i > 0:
			regex_pattern += "[\\s\\-_]*"  # Matches 0 or more separators
		
		# Add all possible substitutions for this character
		if CHAR_SUBSTITUTIONS.has(char):
			var substitutions = CHAR_SUBSTITUTIONS[char]
			regex_pattern += "(?:"
			for sub in substitutions:
				regex_pattern += "(" + escape_regex(sub) + ")" + "+|"  # "+" allows repeated chars
			regex_pattern = regex_pattern.trim_suffix("|")  # Remove last "|"
			regex_pattern += ")"
		else:
			regex_pattern += "(" + escape_regex(char) +")" + "+"  # Default if no substitutions
	
	# Compile the regex (case-insensitive)
	var regex := RegEx.new()
	regex.compile("(?i)" + regex_pattern)  # "(?i)" makes it case-insensitive
	
	# Cache for future use
	_regex_cache[word] = regex
	
	return regex

func _ready():
	# On iOS, enable filter by default
	var word_filter_default := false
	if OS.get_name() == "iOS":
		word_filter_default = true
	filter_enabled = SettingsAutoload.config.get_value("Settings", "word_filter", word_filter_default)
