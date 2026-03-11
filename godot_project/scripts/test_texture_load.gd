extends SceneTree

func _initialize():
	var texture = load("res://assets/sprites/Square.png")
	if texture:
		print("Square.png successfully loaded: ", texture.resource_path)
	else:
		print("ERROR: Failed to load texture")
	quit()