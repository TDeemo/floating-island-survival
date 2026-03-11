extends SceneTree

func _initialize():
	var img = Image.new()
	var err = img.load("res://assets/sprites/Square.png")
	if err == OK:
		print("Square.png successfully loaded via Image")
		var tex = ImageTexture.create_from_image(img)
		print("ImageTexture created")
	else:
		print("ERROR: Failed to load image, error code: ", err)
	quit()