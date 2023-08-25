extends HBoxContainer


signal download_modloader_completed
signal download_pck_tool_completed
signal downloads_completed
signal unziped

const KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN := "KANA-ModLoaderPatcher:PatchBtn"
const KANA_GITHUB_MODLOADER_MAIN_DOWNLOAD_LINK := "https://github.com/GodotModding/godot-mod-loader/releases/download/v6.2.0/ModLoderCompiled.zip"
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
var downloads_completed := false

onready var btn_patch_mod_loader: Button = $"%Btn_Patch_ModLoader"


func KANA_create_temp_dir() -> void:
	var dir := Directory.new()
	dir.make_dir(TEMP_DIR_GLOBAL_PATH)


func KANA_download_pck_tool() -> void:
	var request := HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_download_pck_tool_completed")

	var error = request.request(KANA_GITHUB_PCKTOOL_DOWNLOAD_LINK)
	if error != OK:
		push_error("An error occurred in the HTTP request.")


func KANA_download_latest_release() -> void:
	var request := HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_download_modloader_completed")

	var error = request.request(KANA_GITHUB_MODLOADER_MAIN_DOWNLOAD_LINK)
	if error != OK:
		push_error("An error occurred in the HTTP request.")


func KANA_unzip_mod_loader() -> void:
	var output := []
	var command: String = "Expand-Archive '%s' '%s'" % [MODLOADER_GLOBAL_ZIP_PATH, MODLOADER_GLOBAL_UNZIP_PATH]

	ModLoaderLog.debug("Unzip command: %s" % command, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)

	var _exit_code := OS.execute("powershell.exe", ["-Command", command], true, output)

	ModLoaderLog.debug_json_print("Ouput Unzip:", output, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)

	ModLoaderLog.debug("Unziped ModLoader - path: %s" % MODLOADER_GLOBAL_UNZIP_PATH, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)

	emit_signal("unziped")


func KANA_replace_options_resource() -> void:
	var dir := Directory.new()
	dir.copy(GLOBAL_CUSTOM_OPTIONS_RESOURCE, GLOBAL_VANILLA_OPTIONS_RESOURCE)


func KANA_get_all_file_paths_as_string() -> String:
	var file_paths := _ModLoaderPath.get_flat_view_dict(MODLOADER_GLOBAL_UNZIP_PATH)
	var global_file_paths := []

	for path in file_paths:
		global_file_paths.push_back(ProjectSettings.globalize_path(path))

	return ",".join(global_file_paths)


func KANA_list_pck_content() -> void:
	ModLoaderLog.debug("Listing pck content", KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)

	var output := []
	var _exit_code_add_project_binary := OS.execute(PCK_TOOL_GLOBAL_PATH, ["--pack", BROTATO_PCK_GLOBAL_PATH, "--action", "list"], true, output)
	ModLoaderLog.debug_json_print("PCK Tool Output" , output, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)


func KANA_patch_modloader() -> void:
	var file_paths := KANA_get_all_file_paths_as_string()

	var output_patch_modloader := []
	var _exit_code_add_project_binary := OS.execute(PCK_TOOL_GLOBAL_PATH, ["--pack", BROTATO_PCK_GLOBAL_PATH , "--action", "add", "--file", file_paths, "--remove-prefix", MODLOADER_GLOBAL_UNZIP_PATH ], true, output_patch_modloader)
	ModLoaderLog.debug_json_print("PCK Tool Output" , output_patch_modloader, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)


func KANA_clean_up_temp_dir() -> void:
	OS.move_to_trash(TEMP_DIR_GLOBAL_PATH)


func KANA_restart_game() -> void:
	# run the game again
	var _exit_code_game_start = OS.execute(BROTATO_EXE_GLOBAL_PATH, [], false)
	# quit the current execution
	get_tree().quit()


func KANA_backup_original_pck() -> void:
	var dir := Directory.new()
	dir.copy(BROTATO_PCK_GLOBAL_PATH, BROTATO_PCK_BACKUP_GLOBAL_PATH)


func _on_Btn_Patch_ModLoader_pressed() -> void:
	if _ModLoaderFile.dir_exists(MODLOADER_GLOBAL_UNZIP_PATH):
		KANA_clean_up_temp_dir()

	ModLoaderLog.debug("Executing ModLoader Patch", KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)
	KANA_create_temp_dir()
	KANA_download_latest_release()
	yield(self, "download_modloader_completed")
	KANA_download_pck_tool()
	yield(self, "download_pck_tool_completed")
	KANA_unzip_mod_loader()
	KANA_replace_options_resource()
	KANA_backup_original_pck()
	KANA_patch_modloader()
	call_deferred("KANA_restart_game")


func _download_modloader_completed(result, response_code, headers, body) -> void:
	var file := File.new()
	file.open(MODLOADER_GLOBAL_ZIP_PATH, File.WRITE)
	file.store_buffer(body)
	file.close()

	ModLoaderLog.debug("download ModLoader completed - path: %s" % MODLOADER_GLOBAL_ZIP_PATH, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)
	emit_signal("download_modloader_completed")

	if pck_tool_download_completed:
		downloads_completed = true
		emit_signal("downloads_completed")


func _download_pck_tool_completed(result, response_code, headers, body) -> void:
	var file := File.new()
	file.open(PCK_TOOL_GLOBAL_PATH, File.WRITE)
	file.store_buffer(body)
	file.close()

	ModLoaderLog.debug("download pcktool completed - path: %s" % PCK_TOOL_GLOBAL_PATH, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)
	emit_signal("download_pck_tool_completed")

	pck_tool_download_completed = true

	if modloader_download_completed:
		downloads_completed = true
		emit_signal("downloads_completed")
