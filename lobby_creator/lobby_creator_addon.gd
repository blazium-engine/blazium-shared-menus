class_name LobbyCreatorAddon
extends HBoxContainer

func get_addon_tags() -> Array[Dictionary]:
	push_error("not implemented in subclass.")
	return []

###example###
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
