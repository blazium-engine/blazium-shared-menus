extends Control
class_name ChatContainer
## The chat box for all Blazium games
##
## Has basic command function that all games share.
## To add game specific commands see [method add_game_commands]

@export var chat_input: LineEdit
@export var chat_text: RichTextLabel
@export var logs: Label
@export var server_event_color: Color
@export var command_error_color: Color
@export var chat_msg_sfx: AudioStreamPlayer
@export var click_sfx: AudioStreamPlayer
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

var chat_command_list: Array[ChatCommand] = []


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

	chat_command_list.append_array([
			ChatCommand.create_command("help", help_command, "Shows the command list"),
			ChatCommand.create_command("discord", discord_command, "Gives a link to Blazium's Discord server"),
			ChatCommand.create_command("kick", kick_command, "Kick a player from the lobby", "player name"),
			ChatCommand.create_command("code", code_command, "Gives the lobby code"),
			ChatCommand.create_command("me", me_command, "Broadcasts a narrative message in third person", "action"),
	])
	add_game_commands()
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

	var message: String
	var peer_name: String = peer.user_data.get("name", "") if peer else ""
	if is_player:
		message = await _process_player_message(chat_message, peer_name)
	else: # server event
		message = (
				"[color=#%s][i]%s%s[/i][/color]\n" %
				[server_event_color_hex,
				peer_name + " " if peer else "",
				chat_message]
		)

	chat_text.text += emoji_panel.get_final_text(message)
	print(message)


## Override this method to append game specific commands to the [member chat_command_list] after extending the script.[br]
## To use this, make a script extending [ChatContainer] and link it to the scene's [ChatContainer].
##
## [codeblock]
## extends ChatContainer
##
## # Example adding commands to Project: Hangman
## func add_game_commands() -> void:
##     chat_command_list.append_array([
##             ChatCommand.create_command("score", score_command, "Shows a scoreboard with players scores"),
##             ChatCommand.create_command("guess", guess_command, "Guess a letter", "letter")
##     ])
## [/codeblock]
func add_game_commands() -> void:
	pass


func _process_player_message(chat_message: String, peer_name: String) -> String:
	if not chat_message.begins_with("/"):
		# Normal user message, no need to check for commands
		return "[b]%s[/b]: %s\n" % [peer_name, chat_message]

	# Check command list for the command
	for command: ChatCommand in chat_command_list:
		var command_name: String = "/" + command.command_name

		if command.argument_name.is_empty():
			# Command has no argument
			if chat_message == command_name:
				return await command.callback.call()
		else:
			# Command has argument
			var splitted_command := chat_message.split(" ")
			if splitted_command[0] == command_name:
				if splitted_command.size() < 2:
					return (
							"[color=#%s][i]%s[/i][/color]\n" %
							[command_error_color_hex,
							"Command requires an argument."]
					)
				return await command.callback.call(splitted_command[1])

	# Command is not in list
	return (
			"[color=#%s][i]%s[/i][/color]\n" %
			[command_error_color_hex,
			"Invalid command. Use /help to list all commands."]
	)


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
	var is_player: bool = not peer.id.is_empty()
	append_message_to_chat(peer if is_player else null, chat_message, is_player)


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
	var message := chat_input.text
	chat_input.clear()
	if message.begins_with("/"):
		append_message_to_chat(GlobalLobbyClient.peer, message, true)
	else:
		var result: LobbyResult = await GlobalLobbyClient.send_chat_message(message).finished
		logs.visible = GlobalLobbyClient.show_debug
		logs.text = result.error


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


class ChatCommand extends Object:
	var command_name: String
	var callback: Callable
	var help_description: String
	var argument_name: String

	static func create_command(
			command_name: String,
			callback: Callable,
			help_description: String,
			argument_name: String = ""
	) -> ChatCommand:
		var command: ChatCommand = ChatCommand.new()
		command.command_name = command_name
		command.callback = callback
		command.help_description = help_description
		command.argument_name = argument_name
		return command

# # Basic generic commands # #
func help_command() -> String:
	var help_command_list: String = ""
	for command: ChatCommand in chat_command_list:
		var argument := ""
		if not command.argument_name.is_empty():
			argument = " <%s>" % command.argument_name

		help_command_list += (
				"/%s%s: %s.\n" %
				[command.command_name, argument, command.help_description]
		)

	return "[color=#%s][i]%s[/i][/color]" % [server_event_color_hex, help_command_list]


func kick_command(arg: String) -> String:
	if not GlobalLobbyClient.is_host():
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[command_error_color_hex,
				"You need to be the lobby host to be able to kick players."]
		)

	if arg.is_empty():
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[command_error_color_hex,
				"Empty player name."]
		)

	var peer_to_kick: Array[LobbyPeer] = GlobalLobbyClient.peers.filter(func(p: LobbyPeer):
			if p.user_data.get("name", "") == arg: return p
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
	# function will append the kick message
	return ""


func discord_command() -> String:
	return (
			"[color=#%s][i][url=https://chat.blazium.app]Click to Join Blazium's Discord server[/url][/i][/color]\n" %
			server_event_color_hex
	)


func code_command() -> String:
	return (
			"[color=#%s][i]Lobby code: %s[/i][/color]\n" %
			[server_event_color_hex,
			GlobalLobbyClient.lobby.id]
	)


func me_command(action: String) -> String:
	if action.is_empty():
		return (
				"[color=#%s][i]%s[/i][/color]\n" %
				[command_error_color_hex,
				"Need an action."]
		)
	var result: ScriptedLobbyResult = await GlobalLobbyClient.lobby_call("me_command", [action]).finished
	logs.visible = GlobalLobbyClient.show_debug
	logs.text = result.error
	if result.has_error():
		return (
				"[color=#%s][i]Server Error: %s[/i][/color]\n" %
				[command_error_color_hex,
				result.error]
		)
	# The server will send the broadcast
	return ""
