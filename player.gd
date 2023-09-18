extends CharacterBody2D

@onready var ray = $RayCast2D
@onready var ground = $GroundCheck
@onready var fallTime = $FallTime
@onready var climb_up = $ClimbCheck
@onready var climb_down = $ClimbDownCheck
var time = 0
var falling = false
var jumping = false
var grid_size = 16
var inputs = {
	'ui_up': Vector2.UP,
	'ui_down': Vector2.DOWN,
	'ui_left': Vector2.LEFT,
	'ui_right': Vector2.RIGHT,
}
func _process(delta):
	if !fallTime.is_stopped():
		print(fallTime.get_time_left())
	
func _unhandled_input(event):
	for dir in inputs.keys():
		if event.is_action_pressed(dir):
			move(dir)
			fallCheck()
		

			
func fallCheck():
	if !jumping:
		ground.force_raycast_update()
		if !ground.is_colliding():
			falling = true
			fallTime.start()
			position.y += grid_size
		else:
			falling = false

# Have we touched the floor?
func _on_fall_time_timeout():
	jumping = false
	fallCheck()

func jumpFunc():
	print("Jhumping")
	if climb_up.is_colliding():
		position.y -= grid_size + grid_size + grid_size
	else:
		jumping = true
		position.y -= grid_size + grid_size
		fallTime.start()

func crouchFunc():
	print("Crouching")
	if climb_down.is_colliding():
		position.y += grid_size
	
func move(dir):
	if inputs[dir].x && !falling:
		print("shuffle")
		var vector_pos = inputs[dir] * grid_size
		ray.target_position = vector_pos
		ray.force_raycast_update()
		if !ray.is_colliding():
			position += vector_pos
	print(inputs[dir].y)
	if inputs[dir].y == -1:
		jumpFunc()
	if inputs[dir].y == 1:
		crouchFunc()



