extends HBoxContainer


const KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN := "KANA-ModLoaderPatcher:PatchBtn"


# Copies a file from a given src to the specified dst path.
# src = path/to/file.extension
# dst = other/path/to/file.extension
func file_copy(src: String, dst: String) -> void:
	var dir := Directory.new()
	var dst_dir := dst.get_base_dir()

	if not dir.dir_exists(dst_dir):
		dir.make_dir_recursive(dst_dir)

	dir.copy(src, dst)


func extract_pck_tool() -> void:
	file_copy("res://mods-unpacked/KANA-ModLoaderPatcher/vendor/godotpcktool/godotpcktool.exe", _ModLoaderPath.get_local_folder_dir("godotpcktool.exe"))


func extract_patch_dir() -> void:
	for path in KANA_get_all_file_paths():
		file_copy(path, _ModLoaderPath.get_local_folder_dir(path.trim_prefix("res://mods-unpacked/KANA-ModLoaderPatcher/")))
		yield(get_tree().create_timer(1.0), "timeout")


func KANA_get_all_file_paths() -> PoolStringArray:
	var file_paths := _ModLoaderPath.get_flat_view_dict("res://mods-unpacked/KANA-ModLoaderPatcher/patch/")
	var global_file_paths := []

#	for file_path in file_paths:
#		global_file_paths.push_back(ProjectSettings.globalize_path(file_path))

	return file_paths


func KANA_get_all_file_paths_as_string() -> String:
	var global_file_paths := KANA_get_all_file_paths()
	return ",".join(global_file_paths)


func KANA_list_pck_content() -> void:
	var path := {
		"pck_tool": ProjectSettings.globalize_path(_ModLoaderPath.get_local_folder_dir("mods-unpacked/KANA-ModLoaderPatcher/vendor/godotpcktool/godotpcktool.exe")),
		"brotato_pck": ProjectSettings.globalize_path(_ModLoaderPath.get_local_folder_dir("Brotato.pck")),
		"patch_dir": ProjectSettings.globalize_path(_ModLoaderPath.get_local_folder_dir("mods-unpacked/KANA-ModLoaderPatcher/patch/"))
	}

	ModLoaderLog.debug_json_print("Paths", path, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)

	var output_add_project_binary := []
	var _exit_code_add_project_binary := OS.execute(path.pck_tool, ["--pack", path.brotato_pck , "--action", "list"], true, output_add_project_binary)
	ModLoaderLog.debug_json_print("PCK Tool Output" , output_add_project_binary, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)


func KANA_patch_modloader() -> void:
	var path := {
		"pck_tool": ProjectSettings.globalize_path("res://mods-unpacked/KANA-ModLoaderPatcher/vendor/godotpcktool/godotpcktool.exe"),
		"brotato_pck": ProjectSettings.globalize_path(_ModLoaderPath.get_local_folder_dir("Brotato.pck")),
		"patch_dir": ProjectSettings.globalize_path(_ModLoaderPath.get_local_folder_dir("mods-unpacked/KANA-ModLoaderPatcher/patch/"))
	}

	ModLoaderLog.debug_json_print("Paths", path, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)

	var output_patch_modloader := []
	var _exit_code_add_project_binary := OS.execute(path.pck_tool, ["--pack", path.brotato_pck , "--action", "add", "--file", KANA_get_all_file_paths(), "--remove-prefix", path.patch_dir ], true, output_patch_modloader)
	ModLoaderLog.debug_json_print("PCK Tool Output" , output_patch_modloader, KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)


func _on_Btn_Patch_ModLoader_pressed() -> void:
	ModLoaderLog.debug("Executing ModLoader Patch", KANA_MODLOADERPATCHER_LOG_NAME_PATCH_BTN)
	extract_pck_tool()
	extract_patch_dir()
	KANA_list_pck_content()



