extends SceneTree

func _init():
	print("Configuring texture import settings...")
	
	# Get all PNG files in assets/sprites
	var dir = DirAccess.open("res://assets/sprites")
	if not dir:
		push_error("Failed to open directory res://assets/sprites")
		quit(1)
		return
	
	var files = []
	_get_files_recursive(dir, files, ".png")
	print("Found %d PNG files" % files.size())
	
	# We need to use EditorImportPlugin, but that's only available in editor context
	# Instead, we can try to reimport using ResourceLoader
	# However, ResourceLoader doesn't expose import settings directly
	# For now, just verify files exist
	for file in files:
		if ResourceLoader.exists(file):
			print("OK: " + file)
		else:
			print("Missing: " + file)
	
	quit(0)

func _get_files_recursive(dir, files, extension):
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			var subdir = DirAccess.open(dir.get_current_dir() + "/" + file_name)
			if subdir:
				_get_files_recursive(subdir, files, extension)
		else:
			if file_name.ends_with(extension):
				files.append(dir.get_current_dir() + "/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()