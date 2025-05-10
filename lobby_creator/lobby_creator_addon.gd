class_name LobbyCreatorAddon
extends HBoxContainer
# have this scene path in res://game/lobby_creator_addon/lobby_creator_addon.tscn

func get_addon_tags() -> Array[Dictionary]:
	push_error("not implemented in subclass.")
	return []

###example###
##my_lobby_creator_addon.gd
#extends LobbyCreatorAddon
#
#func _ready() -> void:
	#pass
#func get_addon_tags() -> Array[Dictionary]:
	#var tags: Array[Dictionary] = [
		#{
			#"tag_name": "_tag_name", 
			#"value": _value
		#}
	#]
	#return tags
