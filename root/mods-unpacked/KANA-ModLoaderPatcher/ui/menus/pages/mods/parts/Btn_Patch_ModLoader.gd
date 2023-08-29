extends HBoxContainer


const KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN = "KANA-ModLoaderPatcher:Btn_Patch_ModLoader"


func _on_Btn_Patch_ModLoader_pressed() -> void:
	# I did not manage to retrive a signal when I extended the menu_mods.gd init() function.
	# I know this is really ugly but I can fix this later.
	var patch_panel := get_parent().get_parent().get_parent().get_node("ModLoader_Patch_Panel")
	patch_panel.show()
