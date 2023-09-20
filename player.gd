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
var moving = false
var valid_spacing = [16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176, 192, 208, 224, 240, 256, 272, 288, 304, 320]
#func _process(delta):
#	if !fallTime.is_stopped():
#		print(fallTime.get_time_left())
#Handles key inputs
func _physics_process(delta):
	
	if Input.is_action_pressed("ui_up"):
		move(Vector2(0, -2))
	elif Input.is_action_pressed("ui_down"):
		move(Vector2(0, 2))
	elif Input.is_action_pressed("ui_left"):
		move(Vector2(-1, 0))
	elif Input.is_action_pressed("ui_right"):
		move(Vector2(1, 0))

#Handles movement
func move(dir):
	if dir && !falling && !moving:
		moving = true
		var vector_pos = dir * grid_size
		ray.target_position = vector_pos
		ray.force_raycast_update()
		if climb_up.is_colliding():
			print(climb_up.get_collision_point().y)
			print(position.y)
		if dir.x:
			if !ray.is_colliding():
				tweening(position, vector_pos, 0.25)
			else:
				print("Can't go here")
				moving = false
		elif dir.y and climb_up.is_colliding() && dir.y == -2:
			
			vector_pos.y = climb_up.get_collision_point().y
			print(vector_pos)
			
			tweening(position.round(), vector_pos , 0.25)
		elif dir.y:
			if !ray.is_colliding():
				tweening(position, vector_pos, 0.25)
			else:
				print("Can't go here")
				moving = false
		
#Handles Tweening
func tweening(position, vector_pos, duration):
	var tween = get_tree().create_tween()
	var destination = position + vector_pos
	if duration:
		tween.tween_property(self, "position", destination, duration)
	else:
		tween.tween_property(self, "position", destination, 0.25)
	position = destination
	tween.tween_callback(shuffleStep)
	
#Callback for if moving
func shuffleStep():
	floorCheck()
	moving = false
#Handles Falling
func floorCheck():
	ground.force_raycast_update()
	if !ground.is_colliding():
		falling = true
		var vector_pos = Vector2(0, 1) * grid_size
		tweening(position, vector_pos, 0.1)
	else:
		falling = false
		jumping = false
#Timer for falling
func _on_fall_time_timeout():
	floorCheck()
