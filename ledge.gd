extends StaticBody2D


func _ready():
	# Make sure the climbable objects are in the "climbable" group
	add_to_group("climbable")
