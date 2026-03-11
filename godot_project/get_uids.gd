extends SceneTree

func _init():
	var script_paths = [
		"res://scripts/island_generation/IslandGenerator.gd",
		"res://scripts/island_generation/BiomeManager.gd",
		"res://scripts/island_generation/ResourceDistributor.gd",
		"res://scripts/island_generation/HarborPlacer.gd",
		"res://scripts/island_generation/TerrainChunk.gd"
	]
	for path in script_paths:
		var script = load(path)
		if script:
			print("UID for ", path, ": ", script.resource_path.get_uid())
		else:
			print("Failed to load: ", path)
	quit()
