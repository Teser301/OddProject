extends CharacterBody2D

@onready var headray = $HeadCheck
@onready var legray = $LegCheck
@onready var ground = $GroundCheck
@onready var fallTime = $FallTime
@onready var climb_up = $ClimbCheck
@onready var climb_up_short = $ClimbCheck2
@onready var collision = $CollisionShape2D

signal stance_crouch
signal stance_standing

var time = 0
var falling = false
var jumping = false
var grid_size = 16
var moving = false
var crouching = false
var crouchHandling = false
var ledge_status = false
var valid_spacing = [16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176, 192, 208, 224, 240, 256, 272, 288, 304, 320]

# Connect the signal to the crouching function
#Handles key inputs
func _physics_process(delta):
	if Input.is_action_pressed("ui_up"):
		move(Vector2(0, -1))
	elif Input.is_action_pressed("ui_down"):
		move(Vector2(0, 1))
	elif Input.is_action_pressed("ui_left"):
		move(Vector2(-1, 0))
	elif Input.is_action_pressed("ui_right"):
		move(Vector2(1, 0))

#Handles movement
func move(dir):
	if dir && !falling && !moving:
		moving = true
		var vector_pos = dir * grid_size
		if dir.x:
			headray.target_position = vector_pos
			legray.target_position = vector_pos
			headray.force_raycast_update()
			legray.force_raycast_update()
			if !headray.is_colliding() && !legray.is_colliding():
				tweening(position, vector_pos, 0.25)
			elif headray.is_colliding() && !legray.is_colliding() && !crouching:
				crouching = true
				emit_signal("stance_crouch")
			elif !headray.is_colliding() && legray.is_colliding():
				print("Head Free, Leg Blocked. Lets Vault")
				vector_pos.x = grid_size
				vector_pos.y = -grid_size
				print(vector_pos)
				tweening(position, vector_pos, 0.25)
			else:
				print("Can't go herse")
				moving = false
		elif dir.y:
			if ledge_status && dir.y == -1:
				print("Going up")
				ledge_status = false
				vector_pos.y -= grid_size * 2
				print(vector_pos)
				tweening(position.round(), vector_pos , 0.25)
			elif climb_up_short.is_colliding() && dir.y == -1:
				vector_pos.y -= grid_size * 2
				print("short")
				tweening(position.round(), vector_pos , 0.25)
			elif climb_up.is_colliding() && dir.y == -1:
				print("double")
				vector_pos.y -= grid_size * 3
				tweening(position.round(), vector_pos , 0.25)
			elif dir.y:
				if !headray.is_colliding():
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
	if !ledge_status:
		floorCheck()
	moving = false
#Handles Falling
func floorCheck():
	ground.force_raycast_update()
	if !ground.is_colliding():
		if crouching:
			emit_signal("stance_standing")
		falling = true
		var vector_pos = Vector2(0, 1) * grid_size
		
		tweening(position, vector_pos, 0.1)
	else:
		falling = false
		jumping = false
#Timer for falling
func _on_fall_time_timeout():
	floorCheck()

func _on_stance_crouch():
	scale = Vector2(1, 0.5)
	position += Vector2(0, grid_size)
	moving = false
	print("Crooching")

func _on_stance_standing():
	scale = Vector2(1, 1)
	print("standing")
	crouching = false



