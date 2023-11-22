extends CharacterBody2D
class_name PlayerController


@onready var climb_reach = $ClimbReach
@onready var crouch_climb = $CrouchClimb
@onready var headray = $HeadCheck
@onready var legray = $LegCheck
@onready var ground_check = $GroundCheck
@onready var collision = $playerCollision
@onready var action_time = $ActionTimer

signal stance_turn
signal stance_crouch
signal stance_standing
signal movement_completed

var falling = false
var grid_size = 64
var moving = false
var movement_status = false

var turn_status = false
var turning = false

var jumping = false
var sprintMode = false
# Status's (Standing, Crouching, Climbing, Falling, Jumping)
var crouch_status = false
var ledge_status = false
var fall_status = true
var jump_status = false
var leap_status = false
var leaping = false
var climbing_status = false

var cur_move = Vector2(0,0)
var first_step = true
var next_pos = Vector2(0,0)
var current_pos = Vector2(0,0)

var status_check = false

var direction = Vector2(0,0)
var distanceToTravel = Vector2(0,0)
var travelDestination = 0
var travelCounter = 0

var distanceToLeap = Vector2(0,0)


func _physics_process(delta):
	input()
	inMotion(delta)
	floorCheck(delta)
	ledgeCheck(delta)
	move_and_slide()
	
# Connect the signal to the crouching function
#Handles key inputs
func input():
	if Input.is_action_just_pressed("move_up"):
		move(Vector2(0, -1))
	elif Input.is_action_just_pressed("move_down"):
		move(Vector2(0, 1))

	if Input.is_action_pressed("sprint_key"):
		sprintMode = true
	else:
		sprintMode = false
	if Input.is_action_just_pressed("move_leap"):
		leap()
		
	if Input.is_action_just_pressed("move_right"):
		move(Vector2(1, 0))
		moving = true
	elif Input.is_action_just_pressed("move_left"):
		move(Vector2(-1, 0))
		moving = true
	if Input.is_action_just_released("move_right") or Input.is_action_just_released("move_left"):
		moving = false
		
#Remember. Move * Time = 64 or 128
var movement = 4
var movementSprint = movement * 2
var movementTime = 16

func move(dir):
	print(dir)
	if !movement_status :
		if dir.x:
			direction = dir
			if sign(headray.target_position.x) != direction.x:
				turning = true
				print(turning)
			else:
#				moving = true
				if sprintMode:
					distanceToTravel = direction * movementSprint
				else:
					distanceToTravel = direction * movement
		elif dir.y:
			if !ledge_status:
				jump_status = true
				moving = true
				print('going up or down')
				direction = dir
				distanceToTravel = direction * movementSprint
			if ledge_status:
				print('climbing')
				climbing_status = true

func leap():
	leaping = true
	distanceToLeap = Vector2(sign(headray.target_position.x),sign(headray.target_position.x)) * 8
func inMotion(delta):
	# Check if user is in motion and if movement is already occuring.
	# If player holds button, first value will always be true
	# Second value must be false in order to maintain order.
	#Moving
	if moving && !movement_status && !turn_status:
		movement_status = true
	#Leaping
	if leaping && !moving && !leap_status && !turn_status && !movement_status:
		leap_status = true
	else:
		leaping = false
		
	if leap_status:
		leaping = false
		if headray.is_colliding() && leap_status && travelCounter <= 15:
			print('ouch')
			position = Vector2(round(position.x / 64) * 64, round(position.y / 64) * 64)
			travelCounter = 16
		elif travelCounter == 16:
			emit_signal("movement_completed")
			emit_signal("the_signal")
		elif travelCounter >= 8:
			travelCounter +=1
			position.x += distanceToLeap.x * 1.5
			position.y += abs(distanceToLeap.y) 
		else:
			travelCounter +=1
			position.x += distanceToLeap.x * 1.5
			position.y -= abs(distanceToLeap.y) 
	# While its true, check the steps
		
	if movement_status:
		# Orientate the player if facing wrong direction. Takes a turn
		if turning:
			print('Turn')
			
			if travelCounter == 8:
				headray.target_position = headray.target_position * -1
				legray.target_position = legray.target_position * -1
				if direction.x == -1:
					$Player.flip_h = true
				else:
					$Player.flip_h = false
				print('turning')
				emit_signal("movement_completed")
			else:
				travelCounter += 1
		#If player is not facing wrong way, begin travel to move
		else:
#			print("Move")
			if travelCounter == 16:
				# Ensuring that if player collides with an object. They are re-centered incase of discrepency
				if headray.is_colliding() && (headray.target_position / 64) == direction:
					position = Vector2(round(position.x / 64) * 64, round(position.y / 64) * 64)
				emit_signal("movement_completed")
			else: 
				travelCounter += 1
				if sprintMode:
					print('rin')
					if leaping:
						print('sprint leap')
				#if colliding with wall or direction is Y. Skip walk animation/Prevent walking into wall
				if !headray.is_colliding() && !direction.y:
					position += distanceToTravel
					$Player/PlayerAnim.play("walk")
				elif direction.y:
					position += distanceToTravel
				
		
	if climb_reach.is_colliding() && jump_status && !ledge_status:
		print('ledged')
		ledge_status = true
			
	if climbing_status:
		position +=  direction * grid_size * 2
		climbing_status = false
		ledge_status = false

func _on_movement_completed():
	# Handle any additional logic that should occur after movement completes
	movement_status = false
	turning = false
	turn_status = false
	travelCounter = 0
	leap_status = false
	jump_status = false

func ledgeCheck(delta):
	if climb_reach.is_colliding() && jump_status && !ledge_status && leaping:
		ledge_status = true
		jump_status = false
		var ledge_object = climb_reach.get_collider()
		position.y = ledge_object.position.y
		print('lathcing')

func floorCheck(delta):
	if !ledge_status && !jump_status && !leap_status:
		if ground_check.is_colliding():
			fall_status = false
		else:
			fall_status = true
		if crouch_status && fall_status:
			emit_signal("stance_standing")
		velocity.y += 64

#Use this func to ensure the character waits before each step
func _on_stance_crouch():
	collision.scale = Vector2(1, 0.5)
	collision.position += Vector2(0, 1) * (grid_size / 2)
	crouch_status = true
	moving = false
	print("Add Timer to delay this for animation")

func _on_stance_standing():
	collision.scale = Vector2(1, 1)
	collision.position -= Vector2(0, 1) * (grid_size / 2)
	crouch_status = false
	moving = false
	print("standing")
	
func _on_debug_pressed():
	falling = false
	leaping = false
	moving = false
	turning = false
	sprintMode = false
	jump_status = false
	fall_status = true
	#Hard set position and scale back to standing
	position = Vector2(576,-320)
	collision.scale = Vector2(1, 1)
	collision.position = Vector2(32,64)



