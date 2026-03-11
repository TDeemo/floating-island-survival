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
		var uid = ResourceLoader.get_resource_uid(path)
		print("UID for ", path, ": ", uid)
	quit()
