extends HBoxContainer


signal download_completed
signal unziped

const KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN := "KANA-ModLoaderPatcher:PatchBtn"
const KANA_GITHUB_MODLOADER_MAIN_DOWNLOAD_LINK := "https://github.com/GodotModding/godot-mod-loader/archive/refs/heads/main.zip"


func _ready() -> void:
	connect("download_completed", self, "_on_download_completed")
	connect("unziped", self, "_on_unziped")


func KANA_download_latest_release() -> void:
	var request := HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_http_request_completed")

	var error = request.request(KANA_GITHUB_MODLOADER_MAIN_DOWNLOAD_LINK)
	if error != OK:
		push_error("An error occurred in the HTTP request.")


func _http_request_completed(result, response_code, headers, body) -> void:
	var file := File.new()
	file.open("res://mods-unpacked/KANA-ModLoaderPatcher/patch/godot-mod-loader-main.zip", File.WRITE)
	file.store_buffer(body)
	file.close()

	emit_signal("download_completed")


func _on_download_completed() -> void:
	KANA_test_unziping()


func KANA_test_unziping() -> void:
	var zip_file_path = ProjectSettings.globalize_path("res://mods-unpacked/KANA-ModLoaderPatcher/patch/godot-mod-loader-main.zip")
	var destination_folder := ProjectSettings.globalize_path("res://mods-unpacked/KANA-ModLoaderPatcher/patch")
	var command: String = "Expand-Archive " + zip_file_path + " " + destination_folder
	var _exit_code := OS.execute("powershell.exe", ["-Command", command])

	ModLoaderLog.debug(zip_file_path, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)
	ModLoaderLog.debug(destination_folder, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)

	emit_signal("unziped")


func KANA_get_all_file_paths_as_string() -> String:
	var file_paths := _ModLoaderPath.get_flat_view_dict("res://mods-unpacked/KANA-ModLoaderPatcher/patch/godot-mod-loader-main")
	var global_file_paths := []

	for path in file_paths:
		global_file_paths.push_back(ProjectSettings.globalize_path(path))

	return ",".join(global_file_paths)


func KANA_list_pck_content() -> void:
#		"pck_tool": ProjectSettings.globalize_path(_ModLoaderPath.get_local_folder_dir("mods-unpacked/KANA-ModLoaderPatcher/vendor/godotpcktool/godotpcktool.exe")),
#		"brotato_pck": ProjectSettings.globalize_path(_ModLoaderPath.get_local_folder_dir("Brotato.pck")),
	var path := {
		"pck_tool": ProjectSettings.globalize_path("res://mods-unpacked/KANA-ModLoaderPatcher/vendor/godotpcktool/godotpcktool.exe"),
		"brotato_pck": "C:/Program Files (x86)/Steam/steamapps/common/Brotato/Brotato.pck",
	}

	ModLoaderLog.debug_json_print("Paths", path, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)

	var output_add_project_binary := []
	var _exit_code_add_project_binary := OS.execute(path.pck_tool, ["--pack", path.brotato_pck , "--action", "list"], true, output_add_project_binary)
	ModLoaderLog.debug_json_print("PCK Tool Output" , output_add_project_binary, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)


func KANA_patch_modloader() -> void:
	var path := {
		"pck_tool": ProjectSettings.globalize_path("res://mods-unpacked/KANA-ModLoaderPatcher/vendor/godotpcktool/godotpcktool.exe"),
		"brotato_pck": ProjectSettings.globalize_path(_ModLoaderPath.get_local_folder_dir("Brotato.pck")),
		"patch_dir": ProjectSettings.globalize_path(_ModLoaderPath.get_local_folder_dir("mods-unpacked/KANA-ModLoaderPatcher/patch/godot-mod-loader-main"))
	}

	ModLoaderLog.debug_json_print("Paths", path, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)

	var file_paths := KANA_get_all_file_paths_as_string()

	var output_patch_modloader := []
	var _exit_code_add_project_binary := OS.execute(path.pck_tool, ["--pack", path.brotato_pck , "--action", "add", "--file", file_paths, "--remove-prefix", path.patch_dir ], true, output_patch_modloader)
	ModLoaderLog.debug_json_print("PCK Tool Output" , output_patch_modloader, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)


func _on_Btn_Patch_ModLoader_pressed() -> void:
	ModLoaderLog.debug("Executing ModLoader Patch", KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)
	KANA_download_latest_release()


func _on_unziped() -> void:
	KANA_patch_modloader()
