extends Node


const KANA_MODLOADERPATCHER_DIR := "KANA-ModLoaderPatcher"
const KANA_MODLOADERPATCHER_LOG_NAME_MAIN := "KANA-ModLoaderPatcher:Main"

var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""


func _init(modloader = ModLoader) -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().plus_file(KANA_MODLOADERPATCHER_DIR)
	# Add extensions
	install_script_extensions()
	# Add translations
	add_translations()


func install_script_extensions() -> void:
	extensions_dir_path = mod_dir_path.plus_file("extensions")


func add_translations() -> void:
	translations_dir_path = mod_dir_path.plus_file("translations")

	ModLoaderMod.add_translation("res://mods-unpacked/KANA-ModLoaderPatcher/translations/translation.de.translation")
	ModLoaderMod.add_translation("res://mods-unpacked/KANA-ModLoaderPatcher/translations/translation.en.translation")


func _ready() -> void:
	var menu_mods_scene: Control = load("res://mods-unpacked/otDan-BetterModList/ui/menus/pages/mods/menu_mods.tscn").instance()
	var btn_patch_modloader_scene: Control = load("res://mods-unpacked/KANA-ModLoaderPatcher/ui/menus/pages/mods/parts/Btn_Patch_ModLoader.tscn").instance()

	var button_container: VBoxContainer = menu_mods_scene.get_node("VBoxContainer/Buttons")
	var workshop_btn: Button = button_container.get_node('WorkshopButton')


	# Add the Patch Button
	button_container.add_child(btn_patch_modloader_scene)
	button_container.move_child(btn_patch_modloader_scene, 1)
	btn_patch_modloader_scene.set_owner(menu_mods_scene)

	# Remove the Workshop Button
	button_container.remove_child(workshop_btn)

	# Add the Workshop Button to the Patch Button HBoxContainer
	btn_patch_modloader_scene.add_child(workshop_btn)
	workshop_btn.set_owner(menu_mods_scene)

	ModLoaderMod.save_scene(menu_mods_scene, "res://mods-unpacked/otDan-BetterModList/ui/menus/pages/mods/menu_mods.tscn")
