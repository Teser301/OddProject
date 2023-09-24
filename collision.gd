extends CollisionShape2D


# Called when the node enters the scene tree for the first time.

func _on_character_body_2d_pizza(moving):
	scale = Vector2(1, 0.5)
	position += Vector2(0, 8)
	moving = false
	print("Crouching")
	return moving
