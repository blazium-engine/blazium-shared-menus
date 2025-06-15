class_name CustomSteamClient
extends Node

signal ticket_received(ticket: String)
@export var login_timeout:= 10

func login_steam() -> bool:
	var steam:= Engine.get_singleton("Steam")
	if steam == null:
		return false
	get_tree().create_timer(login_timeout).timeout.connect(_fail_login_if_timeout)
	var result_init :Dictionary= steam.steamInit(true, 3418850, true)
	if result_init["status"] != 1:
		print("[SteamLogin]: ", result_init["verbal"])
		return false
	steam.get_ticket_for_web_api.connect(_get_ticket_for_web_api)
	steam.getAuthTicketForWebApi("blazium")
	return true

func get_dlcs() -> Array[String]:
	var steam:= Engine.get_singleton("Steam")
	var dlc_array = steam.getDLCData()
	var owned :Array[String]= []
	for dlc_data in dlc_array:
		if steam.isDLCInstalled(dlc_data["id"]):
			owned.push_back(dlc_data["name"])
	return owned


func _fail_login_if_timeout():
	# Error case will be null ticket
	ticket_received.emit("")

func _get_ticket_for_web_api(auth_ticket: int, result: int, ticket_size: int, ticket_buffer: PackedByteArray):
	ticket_received.emit(ticket_buffer.hex_encode())
