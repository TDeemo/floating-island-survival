extends Node2D

func _ready():
	var sprite = $TestSprite
	if sprite.texture:
		print("Square.png successfully loaded: ", sprite.texture.resource_path)
	else:
		print("ERROR: Failed to load texture")
	print("Texture test complete.")