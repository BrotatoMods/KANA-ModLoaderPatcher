extends Panel


signal download_modloader_completed
signal download_modloader_option_completed
signal download_pck_tool_completed
signal unziped

const KANA_ERROR_COLOR := "#ff9090"
const KANA_SUCCESS_COLOR := "00ba03"
const KANA_MODLOADERPATCHER_LOG_NAME_PATCH_PANEL := "KANA-ModLoaderPatcher:ModLoader_Patch_Panel"
const KANA_GITHUB_MODLOADER_MAIN_DOWNLOAD_LINK := "https://github.com/GodotModding/godot-mod-loader/releases/download/v6.2.0/ModLoderCompiled.zip"
const KANA_GITHUB_MODLOADER_OPTION_DOWNLOAD_LINK := "https://github.com/BrotatoMods/KANA-ModLoaderPatcher/releases/download/v1.0.0/options.tres"
const KANA_GITHUB_PCKTOOL_DOWNLOAD_LINK := "https://github.com/hhyyrylainen/GodotPckTool/releases/download/v1.9/godotpcktool.exe"

var TEMP_DIR_GLOBAL_PATH := ProjectSettings.globalize_path(_ModLoaderPath.get_local_folder_dir("ModLoaderPatcher/"))
var PCK_TOOL_GLOBAL_PATH := TEMP_DIR_GLOBAL_PATH.plus_file("godotpcktool.exe")
var MODLOADER_GLOBAL_ZIP_PATH := TEMP_DIR_GLOBAL_PATH.plus_file("ModLoderCompiled.zip")
var MODLOADER_GLOBAL_UNZIP_PATH := TEMP_DIR_GLOBAL_PATH.plus_file("ModLoderCompiled")
var BROTATO_PCK_GLOBAL_PATH := ProjectSettings.globalize_path(_ModLoaderPath.get_local_folder_dir("Brotato.pck"))
var BROTATO_PCK_BACKUP_GLOBAL_PATH := ProjectSettings.globalize_path(_ModLoaderPath.get_local_folder_dir("Brotato_original.pck"))
var BROTATO_EXE_GLOBAL_PATH := ProjectSettings.globalize_path(_ModLoaderPath.get_local_folder_dir("Brotato.exe"))
var GLOBAL_CUSTOM_OPTIONS_RESOURCE := "res://mods-unpacked/KANA-ModLoaderPatcher/patch/options.tres"
var GLOBAL_VANILLA_OPTIONS_RESOURCE := MODLOADER_GLOBAL_UNZIP_PATH.plus_file("addons/mod_loader/options/options.tres")

var pck_tool_download_completed := false
var modloader_download_completed := false
var modloader_option_download_completed := false
var timer_restart_counter := 3

onready var label_mod_loader_version_number: Label = $"%Label_ModLoader_Version_Number"
onready var rich_info: RichTextLabel = $"%Rich_Info"
onready var button_download_mod_loader: Button = $MarginContainer/VBoxContainer/GridContainer/Button_Download_ModLoader
onready var button_download_mod_loader_option: Button = $MarginContainer/VBoxContainer/GridContainer/Button_Download_ModLoader_Option
onready var button_download_pck_tool: Button = $MarginContainer/VBoxContainer/GridContainer/Button_Download_PckTool
onready var button_start_patch: Button = $MarginContainer/VBoxContainer/HBoxContainer2/Button_Start_Patch
onready var animation_player: AnimationPlayer = $"%AnimationPlayer"
onready var timer_restart: Timer = $"%Timer_restart"


func _ready() -> void:
	label_mod_loader_version_number.text = "- %s" % ModLoaderStore.MODLOADER_VERSION


func KANA_is_ready_for_patching() -> bool:
	if(
		pck_tool_download_completed and
		modloader_download_completed and
		modloader_option_download_completed
	):
		return true

	return false


func KANA_add_info(text: String) -> void:
	rich_info.append_bbcode("%s \n" % text)


func KANA_add_error(text: String) -> void:
	rich_info.append_bbcode("[color=%s]%s[/color] \n" % [KANA_ERROR_COLOR, text])


func KANA_add_success(text: String) -> void:
	rich_info.append_bbcode("[color=%s]%s[/color] \n" % [KANA_SUCCESS_COLOR, text])


func KANA_temp_dir_exists() -> bool:
	return _ModLoaderFile.dir_exists(TEMP_DIR_GLOBAL_PATH)


func KANA_create_temp_dir() -> void:
	KANA_add_info("Created temp dir at %s" % TEMP_DIR_GLOBAL_PATH)
	var dir := Directory.new()
	dir.make_dir(TEMP_DIR_GLOBAL_PATH)


func KANA_unzip_mod_loader() -> void:
	var output := []
	var command: String = "Expand-Archive '%s' '%s'" % [MODLOADER_GLOBAL_ZIP_PATH, MODLOADER_GLOBAL_UNZIP_PATH]

	ModLoaderLog.debug("Unzip command: %s" % command, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_PANEL)

	var _exit_code := OS.execute("powershell.exe", ["-Command", command], true, output)

	ModLoaderLog.debug_json_print("Ouput Unzip:", output, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_PANEL)

	ModLoaderLog.debug("Unziped ModLoader - path: %s" % MODLOADER_GLOBAL_UNZIP_PATH, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_PANEL)
	KANA_add_info("Unziped ModLoader - path: %s" % MODLOADER_GLOBAL_UNZIP_PATH)

	emit_signal("unziped")


func KANA_get_all_file_paths_as_string() -> String:
	var file_paths := _ModLoaderPath.get_flat_view_dict(MODLOADER_GLOBAL_UNZIP_PATH)
	var global_file_paths := []

	for path in file_paths:
		global_file_paths.push_back(ProjectSettings.globalize_path(path))

	return ",".join(global_file_paths)


func KANA_patch_modloader() -> void:
	var file_paths := KANA_get_all_file_paths_as_string()

	var output_patch_modloader := []
	var _exit_code_add_project_binary := OS.execute(PCK_TOOL_GLOBAL_PATH, ["--pack", BROTATO_PCK_GLOBAL_PATH , "--action", "add", "--file", file_paths, "--remove-prefix", MODLOADER_GLOBAL_UNZIP_PATH ], true, output_patch_modloader)
	ModLoaderLog.debug_json_print("PCK Tool Output" , output_patch_modloader, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_PANEL)
	KANA_add_info("ModLoader Patch completed")


func KANA_clean_up_temp_dir() -> void:
	KANA_add_info("Cleaning Temp dir \"%s\"" % TEMP_DIR_GLOBAL_PATH)
	OS.move_to_trash(TEMP_DIR_GLOBAL_PATH)


func KANA_restart_game() -> void:
	# run the game again
	var _exit_code_game_start = OS.execute(BROTATO_EXE_GLOBAL_PATH, [], false)
	# quit the current execution
	get_tree().quit()


func KANA_backup_original_pck() -> bool:
	KANA_add_info("Created backup at \"%s\"" % BROTATO_PCK_BACKUP_GLOBAL_PATH)
	var dir := Directory.new()
	var error_copy := dir.copy(BROTATO_PCK_GLOBAL_PATH, BROTATO_PCK_BACKUP_GLOBAL_PATH)
	if not error_copy == OK:
		KANA_add_error("Error creating .pck backup at path \"%s\"" % BROTATO_PCK_BACKUP_GLOBAL_PATH)
		return false

	return true


func _download_file(link: String, callback_function_name: String, download_button: Button, info_message: String, error_message: String) -> bool:
	KANA_add_info(info_message)

	var request := HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, callback_function_name)

	var error = request.request(link)
	if not error == OK:
		push_error(error_message)
		KANA_add_error(error_message)
		download_button.disabled = false
		return false

	return true


func _download_modloader_completed(result, response_code, headers, body) -> void:
	if not KANA_temp_dir_exists():
		KANA_create_temp_dir()

	var file := File.new()
	var error_open := file.open(MODLOADER_GLOBAL_ZIP_PATH, File.WRITE)

	if not error_open == OK:
		KANA_add_error("Error accessing the download path \"%s\"" % PCK_TOOL_GLOBAL_PATH)
		file.close()
		return

	file.store_buffer(body)
	file.close()

	ModLoaderLog.debug("ModLoader download completed - path: %s" % MODLOADER_GLOBAL_ZIP_PATH, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_PANEL)
	KANA_add_info("ModLoader download completed - path: %s" % MODLOADER_GLOBAL_ZIP_PATH)
	emit_signal("download_modloader_completed")

	modloader_download_completed = true
	# Enable the ModLoader Options resource file download button
	button_download_mod_loader_option.disabled = false


func _download_options_resource_file_completed(result, response_code, headers, body) -> void:
	if not KANA_temp_dir_exists():
		KANA_create_temp_dir()

	var file := File.new()
	var error_open := file.open(GLOBAL_VANILLA_OPTIONS_RESOURCE, File.WRITE)

	if not error_open == OK:
		KANA_add_error("Error accessing the download path \"%s\"" % GLOBAL_VANILLA_OPTIONS_RESOURCE)
		file.close()
		return

	file.store_buffer(body)
	file.close()

	ModLoaderLog.debug("download ModLoader Options file completed - path: %s" % MODLOADER_GLOBAL_ZIP_PATH, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_PANEL)
	KANA_add_info("ModLoader options file download completed - path: %s" % MODLOADER_GLOBAL_ZIP_PATH)
	emit_signal("download_modloader_option_completed")

	modloader_option_download_completed = true
	animation_player.play("label_download_modloader_green")

	if KANA_is_ready_for_patching():
		button_start_patch.disabled = false


func _download_pck_tool_completed(result, response_code, headers, body) -> void:
	if not KANA_temp_dir_exists():
		KANA_create_temp_dir()

	var file := File.new()
	var error_open := file.open(PCK_TOOL_GLOBAL_PATH, File.WRITE)

	if not error_open == OK:
		KANA_add_error("Error accessing the download path \"%s\"" % PCK_TOOL_GLOBAL_PATH)
		file.close()
		return

	file.store_buffer(body)
	file.close()

	ModLoaderLog.debug("PckTool download completed - path: %s" % PCK_TOOL_GLOBAL_PATH, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_PANEL)
	KANA_add_info("PckTool download completed - path: %s" % PCK_TOOL_GLOBAL_PATH)
	emit_signal("download_pck_tool_completed")

	pck_tool_download_completed = true
	animation_player.play("label_download_pcktool_green")

	if KANA_is_ready_for_patching():
		button_start_patch.disabled = false


func _on_Button_Back_pressed() -> void:
	hide()


func _on_Button_Download_ModLoader_pressed() -> void:
	button_download_mod_loader.disabled = true

	# Try to download the latest ModLoader release
	var success_download_modloader := _download_file(
		KANA_GITHUB_MODLOADER_MAIN_DOWNLOAD_LINK,
		"_download_modloader_completed",
		button_download_mod_loader,
		"ModLoader download started",
		"ModLoader download failed"
	)

	yield(self, "download_modloader_completed")

	# Return if the download failed
	if not success_download_modloader:
		return

	# Unzip the download
	KANA_unzip_mod_loader()


func _on_Button_Download_ModLoader_Option_pressed() -> void:
	button_download_mod_loader_option.disabled = true
	var _success_download_modloader_option_file := _download_file(
		KANA_GITHUB_MODLOADER_OPTION_DOWNLOAD_LINK,
		"_download_options_resource_file_completed",
		button_download_mod_loader_option,
		"ModLoader options file download started",
		"ModLoader options file download failed"
	)


func _on_Button_Download_PckTool_pressed() -> void:
	button_download_pck_tool.disabled = true
	var _success_download_pcktool := _download_file(
		KANA_GITHUB_PCKTOOL_DOWNLOAD_LINK,
		"_download_pck_tool_completed",
		button_download_pck_tool,
		"PckTool download started",
		"PckTool download failed"
	)


func _on_Button_Start_Patch_pressed() -> void:
	button_start_patch.disabled = true
	var success_backup_original_pck := KANA_backup_original_pck()
	KANA_patch_modloader()
	timer_restart.start()


func _on_Timer_restart_timeout() -> void:
	KANA_add_success("Restarting in %s" % timer_restart_counter)
	timer_restart_counter = timer_restart_counter - 1

	if timer_restart_counter == 0:
		call_deferred("KANA_restart_game")
