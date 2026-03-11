extends SceneTree

# Force import script for Godot textures
func _initialize():
	print("Starting force import process...")
	
	# Method 1: Try to import textures programmatically
	import_textures()
	
	# Quit after import
	quit()

func import_textures():
	# This method would ideally use EditorImportPlugin API
	# but in headless mode, we rely on --import --quit parameters
	print("Texture import should be triggered via --import --quit flags")
	print("If running this script standalone, ensure Godot is started with:")
	print("  godot --editor --quit --headless --import")
	
	# For now, just verify that import files exist
	var assets_dir = "res://assets/sprites/"
	var dir = DirAccess.open(assets_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var png_count = 0
		var import_count = 0
		
		while file_name != "":
			if file_name.ends_with(".png"):
				png_count += 1
				var import_file = assets_dir + file_name + ".import"
				if FileAccess.file_exists(import_file):
					import_count += 1
				else:
					print("Missing .import file: " + file_name)
			file_name = dir.get_next()
		
		print("PNG files: " + str(png_count))
		print(".import files: " + str(import_count))
	else:
		print("ERROR: Cannot open assets directory")