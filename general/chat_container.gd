extends Control

@export var chat_input: LineEdit
@export var chat_text: RichTextLabel
@export var logs: Label
@export var server_event_color: Color
@export var command_error_color: Color
@export var chat_msg_sfx: AudioStreamPlayer
@export var click_sfx: AudioStreamPlayer
@export var word_is_set_sfx: AudioStreamPlayer
@export var emoji_button: CustomButton
@export var emoji_panel: PanelContainer

var just_sent_msg: bool
var config: ConfigFile
var server_event_color_hex: String
var command_error_color_hex: String

const HISTORY_SIZE: int = 16
var history: PackedStringArray
var last_msg_idx: int = -1
var msg_idx: int = -1
var is_history_full: bool = false
var saved_text: String


func _ready() -> void:
	config = ConfigFile.new()
	config.load("user://blazium.cfg")
	var font_color := ThemeDB.get_default_theme().get_color("font_color", "Colors")
	server_event_color_hex = font_color.blend(server_event_color).to_html(false)
	command_error_color_hex = font_color.blend(command_error_color).to_html(false)
	GlobalLobbyClient.peer_messaged.connect(_peer_messaged)
	GlobalLobbyClient.peer_joined.connect(_peer_joined)
	GlobalLobbyClient.peer_left.connect(_peer_left)
	GlobalLobbyClient.peer_disconnected.connect(_peer_disconnected)
	GlobalLobbyClient.peer_reconnected.connect(_peer_reconnected)

	if not (OS.get_name() in ["Android", "iOS"]):
		chat_input.keep_editing_on_text_submit = true
		chat_input.grab_focus()

	history.resize(HISTORY_SIZE)

	append_message_to_chat(null, "Use /help to list all commands")


func _input(_event: InputEvent) -> void:
	if not chat_input.has_focus():
		return
	if last_msg_idx == -1:
		return

	if Input.is_action_pressed("ui_up"):
		if msg_idx == -1:
			msg_idx = last_msg_idx
			saved_text = chat_input.text
		else:
			msg_idx -= 1
		set_chat_text_from_history()
	elif Input.is_action_pressed("ui_down"):
		if msg_idx == -1:
			return
		if msg_idx == last_msg_idx:
			chat_input.text = saved_text
			msg_idx = -1
			return
		msg_idx += 1
		set_chat_text_from_history()


func set_chat_text_from_history():
	msg_idx = wrapi(msg_idx, 0, HISTORY_SIZE - 1 if is_history_full else last_msg_idx + 1)
	chat_input.text = history[msg_idx]


func append_message_to_chat(peer: LobbyPeer, chat_message: String, is_player: bool = false):
	if just_sent_msg:
		just_sent_msg = false
	else:
		chat_msg_sfx.play()

	var message: String = ""
	if is_player:
		var is_self: bool = peer.id == GlobalLobbyClient.peer.id
		# /help command
		if chat_message == "/help":
			message = help_command() if is_self else ""
		# /discord command
		elif chat_message == "/discord":
			message = (
					"[color=#%s][i][url=https://chat.blazium.app]Click to Join Blazium's Discord server[/url][/i][/color]\n" %
					server_event_color_hex
			) if is_self else ""
		# /score command
		elif chat_message == "/score":
			message = score_command() if is_self else ""
		# /skip command
		elif chat_message == "/skip":
			message = await skip_command() if is_self else ""
		# /code command
		elif chat_message == "/code":
			message = (
					"[color=#%s][i]Lobby code: %s[/i][/color]\n" %
					[server_event_color_hex,
					GlobalLobbyClient.lobby.id]
			) if is_self else ""
		# /me command
		elif chat_message.substr(0, 4) == "/me ":
			message = (
					"[color=#%s][i]* %s %s[/i][/color]\n" %
					[server_event_color_hex,
					peer.user_data.get("name", ""),
					chat_message.substr(4)]
			)
		# /kick command
		elif chat_message.substr(0, 6) == "/kick ":
			message = (await kick_command(chat_message.substr(6))) if is_self else ""
		# /guess command
		elif chat_message.substr(0, 7) == "/guess ":
			# Allow either full word or 1 letter
			if len(chat_message.substr(7)) != len(GlobalLobbyClient.lobby.data["guessed"]) && is_self && len(chat_message.substr(7)) != 1:
				message = (
					"[color=#%s][i]%s[/i][/color]\n" %
					[command_error_color_hex,
					"Word length is wrong."]
				)
			else:
				for letter in chat_message.substr(7):
					var letter_pressed = {}
					if is_self:
						var guessed_word : String = GlobalLobbyClient.lobby.data.get("guessed", "")
						letter = letter.to_upper()
						if !guessed_word.contains(letter) && !letter_pressed.has(letter) && letter >= "A" && letter <= "Z":
							letter_pressed[letter] = true
							var msg = (await guess_command(letter))
							if msg == "<error>":
								break
				if !is_self:
					message = ""
		# /setword command
		elif chat_message.substr(0, 9) == "/setword ":
			message = (await setword_command(chat_message.substr(9))) if is_self else ""
		# user message
		else:
			message = "[b]%s[/b]: %s\n" % [peer.user_data.get("name", ""), chat_message]
	else: # server event
		message = (
				"[color=#%s][i]%s%s[/i][/color]\n" %
				[server_event_color_hex,
				peer.user_data.get("name", "") + " " if peer else "",
				chat_message]
		)

	chat_text.text += emoji_panel.get_final_text(message)
	print(message)


func kick_command(peer_name: String) -> String:
	if not GlobalLobbyClient.is_host():
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[command_error_color_hex,
				"You need to be the lobby host to be able to kick players."]
		)

	if peer_name.is_empty():
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[command_error_color_hex,
				"Empty player name."]
		)

	var peer_to_kick: Array[LobbyPeer] = GlobalLobbyClient.peers.filter(func(p: LobbyPeer):
			if p.user_data.get("name", "") == peer_name: return p
	)

	if peer_to_kick.is_empty():
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[command_error_color_hex,
				"Player not found in lobby."]
		)

	if peer_to_kick[0].id == GlobalLobbyClient.peer.id:
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[command_error_color_hex,
				"You cannot kick yourself."]
		)

	var result: LobbyResult = await GlobalLobbyClient.kick_peer(peer_to_kick[0].id).finished
	logs.visible = GlobalLobbyClient.show_debug
	logs.text = result.error

	# Return an empty string because the _peer_left
	# function appends the kick message
	return ""


func score_command() -> String:
	if GlobalLobbyClient.lobby.data.get("game_state", "setup") == "setup":
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[command_error_color_hex,
				"Game has not started, no scoreboard to show."]
		)

	var scorelist: String = ""
	for peer: LobbyPeer in GlobalLobbyClient.peers:
		scorelist += "- %s: %d\n" % [peer.user_data.get("name", ""), peer.data.get("total_points", 0)]

	return "[color=#%s][i]=== Scoreboard ===\n%s[/i][/color]" % [server_event_color_hex, scorelist]


func skip_command() -> String:
	if GlobalLobbyClient.lobby.data.get("game_state", "setup") == "setup":
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[server_event_color_hex,
				"Game has not started, cannot skip turn."]
		)
	if !GlobalLobbyClient.is_dealer():
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[server_event_color_hex,
				"Not your turn, cannot skip turn."]
		)
	var result: ScriptedLobbyResult = await GlobalLobbyClient.lobby_call("skip").finished
	logs.visible = GlobalLobbyClient.show_debug
	logs.text = result.error
	if result.has_error():
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[server_event_color_hex,
				result.error]
		)
	if word_is_set_sfx:
		word_is_set_sfx.play()
	return "You have skipped your turn"

func guess_command(letter: String) -> String:
	if GlobalLobbyClient.lobby.data.get("game_state", "setup") != "playing":
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[server_event_color_hex,
				"Nothing to guess."]
		)

	if letter.length() != 1:
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[command_error_color_hex,
				"Too many letters." if letter.length() > 1 else "Need one letter."]
		)

	letter = letter.to_upper()
	if not (letter >= "A" and letter <= "Z"):
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[command_error_color_hex,
				"Not a letter."]
		)

	if GlobalLobbyClient.lobby.data["pressed"].get(letter, false):
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[command_error_color_hex,
				"Letter was already pressed."]
		)

	var result: ScriptedLobbyResult = await GlobalLobbyClient.lobby_call("guess_letter", [letter]).finished
	logs.visible = GlobalLobbyClient.show_debug
	logs.text = result.error

	if result.has_error():
		return "<error>"
	# The message is appended in hang_man.gd
	return ""


func setword_command(word: String) -> String:
	if GlobalLobbyClient.lobby.data.get("game_state", "setup") != "setting_word":
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[command_error_color_hex,
				"Can't set the word now."]
		)

	if not GlobalLobbyClient.is_dealer():
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[command_error_color_hex,
				"Only the dealer can set the word."]
		)

	if word.is_empty():
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[command_error_color_hex,
				"Can't set an empty word."]
		)

	if word.length() > 20:
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[command_error_color_hex,
				"Word too long, max 20 letters."]
		)

	if word[0] == " " or word[-1] == " ":
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[command_error_color_hex,
				"Word can't start or end with a space."]
		)

	word = word.to_upper()
	for letter: String in word:
		if not ((letter >= "A" and letter <= "Z") or letter == " "):
			return (
					"[color=#%s][i]%s[/i][/color]\n" %
					[command_error_color_hex,
					"Only alphabetic characters are allowed."]
			)

	var result: ScriptedLobbyResult = await GlobalLobbyClient.lobby_call("set_word", [word]).finished
	if result.has_error():
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[command_error_color_hex,
				result.error]
		)
	if word_is_set_sfx:
		word_is_set_sfx.play()
	return "You have set the word to %s.\n" % word


func help_command() -> String:
	var command_list: String = ""
	command_list += "/help: Shows this list.\n"
	command_list += "/discord: Gives a link to Blazium's Discord server.\n"
	command_list += "/score: Shows a scoreboard with players scores.\n"
	command_list += "/code: Gives the lobby code.\n"
	command_list += "/skip: Skip your turn.\n"
	command_list += "/kick <player name>: Kick a player from the lobby.\n"
	command_list += "/me <action>: Broadcasts a narrative message in third person.\n"
	command_list += "/guess <letter>: Guess a letter.\n"
	command_list += "/setword <word>: Set the word if you are the dealer.\n"

	return "[color=#%s][i]%s[/i][/color]" % [server_event_color_hex, command_list]


func _peer_joined(peer: LobbyPeer):
	append_message_to_chat(peer, "Joined the lobby")


func _peer_left(peer: LobbyPeer, kicked: bool):
	if kicked:
		append_message_to_chat(peer, "Was kicked from the lobby")
	else:
		append_message_to_chat(peer, "Left the lobby")


func _peer_disconnected(peer: LobbyPeer):
	append_message_to_chat(peer, "Disconnected from the lobby")


func _peer_reconnected(peer: LobbyPeer):
	append_message_to_chat(peer, "Reconnected to the lobby")


func _peer_messaged(peer: LobbyPeer, chat_message: String):
	append_message_to_chat(peer, chat_message, true)


func _on_chat_button_pressed() -> void:
	if just_sent_msg or chat_input.text.is_empty():
		return

	_hide_emoji_panel()
	click_sfx.play()
	# Reset user message history
	msg_idx = -1
	saved_text = ""
	last_msg_idx = (last_msg_idx + 1) % HISTORY_SIZE
	if last_msg_idx == HISTORY_SIZE-1 and not is_history_full:
		is_history_full = true
	history[last_msg_idx] = chat_input.text

	just_sent_msg = true
	if len(chat_input.text) != 0:
		var result: LobbyResult = await GlobalLobbyClient.send_chat_message(chat_input.text).finished
		logs.visible = GlobalLobbyClient.show_debug
		logs.text = result.error
		chat_input.clear()


func _on_chat_input_text_submitted(_new_text: String) -> void:
	_on_chat_button_pressed()


func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)


func _on_emoji_button_toggled(toggled_on: bool) -> void:
	emoji_panel.visible = toggled_on


func _on_emoji_pressed(emoji_code: String) -> void:
	var pos = chat_input.caret_column
	chat_input.text = chat_input.text.insert(pos, emoji_code)
	chat_input.caret_column = pos + emoji_code.length()


func _hide_emoji_panel() -> void:
	emoji_button.button_pressed = false
