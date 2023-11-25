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


var distanceToTravel : Vector2 = Vector2(0,0)
var distanceToLeap: Vector2 = Vector2(0,0)
var queued_actions: Array = []
var actionTimer: int = 0
var actionTime: bool = false
var action: String

func _physics_process(delta):
	input()
	inMotion()
	floorCheck()
#	ledgeCheck()
	move_and_slide()
	
# Connect the signal to the crouching function
#Handles key inputs
func input():
#	if Input.is_action_just_pressed("move_up"):
#		move(Vector2(0, -1))
#	elif Input.is_action_just_pressed("move_down"):
#		move(Vector2(0, 1))
		
	if Input.is_action_pressed("move_leap"):
		leap()
		moving = true
	elif Input.is_action_pressed("move_right") && Input.is_action_pressed("move_left"):
		moving = false
	elif Input.is_action_pressed("move_down"):
		pass
	elif Input.is_action_pressed("move_right"):
		move(Vector2(1, 0))
		moving = true
	elif Input.is_action_pressed("move_left"):
		move(Vector2(-1, 0))
		moving = true
	elif Input.is_action_pressed("move_up"):
		pass
	
	else:
		moving = false
#	if Input.is_action_pressed("sprint_key"):
#		sprintMode = true
#	else:
#		sprintMode = false
		
#Remember. Move * Time = 64 or 128
var movement = 4
var movementSprint = movement * 2
var movementTime = 16

func move(direction):
	if !movement_status :
		if direction.x:
			if sign(headray.target_position.x) != direction.x:
				turning = true
				queued_actions.append("turn_action")
			else:
				queued_actions.append("move_action")
			if sprintMode:
				distanceToTravel = direction * movementSprint
			else:
				distanceToTravel = direction * movement
		elif direction.y:
			if !ledge_status:
				jump_status = true
				moving = true
				print('going up or down')
				distanceToTravel = direction * movementSprint
			if ledge_status:
				print('climbing')
				climbing_status = true

func leap():
	if !movement_status :
		distanceToLeap = Vector2(sign(headray.target_position.x),sign(headray.target_position.x)) * 8
		queued_actions.append("leap_action")
		leaping = true

func inMotion():
	if queued_actions.size() > 0:
		movement_status = true
	if movement_status:
		if actionTimer == 16:
			if turning:
				#Flip to new direction raycast Arrows
				headray.target_position = headray.target_position * -1
				legray.target_position = legray.target_position * -1
				#Check which way
				if sign(headray.target_position.x) == -1:
					$Player.flip_h = true
				else:
					$Player.flip_h = false
			
			emit_signal("movement_completed")
		else:
			if actionTimer == 0:
				action = queued_actions.pop_front()
				print("Current Action:", action)
			if action == "turn_action":
				pass
			if action == "move_action":
				if headray.is_colliding():
					print('ouch')
					position = Vector2(round(position.x / 64) * 64, round(position.y / 64) * 64)
				else:
					position += distanceToTravel
			if action == "leap_action":
				jump_status = true
				if headray.is_colliding() && actionTimer <= 15:
					print('ouch')
					position = Vector2(round(position.x / 64) * 64, round(position.y / 64) * 64)
				elif actionTimer >= 8:
					position.x += distanceToLeap.x * 1.5
					position.y += abs(distanceToLeap.y)
				else:
					position.x += distanceToLeap.x * 1.5
					position.y -= abs(distanceToLeap.y)
			actionTimer += 1
#	# Check if user is in motion and if movement is already occuring.
#	# If player holds button, first value will always be true
#	# Second value must be false in order to maintain order.
#	if climb_reach.is_colliding() && jump_status && !ledge_status:
#		print('ledged')
#		ledge_status = true
#
#	if climbing_status:
#		position +=  direction * grid_size * 2
#		climbing_status = false
#		ledge_status = false

func _on_movement_completed():
	movement_status = false
	turning = false
	jump_status = false
	actionTimer = 0

#func ledgeCheck():
#	if climb_reach.is_colliding() && jump_status && !ledge_status && leaping:
#		ledge_status = true
#		jump_status = false
#		var ledge_object = climb_reach.get_collider()
#		position.y = ledge_object.position.y
#		print('lathcing')

func floorCheck():
	if !ledge_status && !jump_status && !leap_status:
		if ground_check.is_colliding():
			fall_status = false
		else:
			fall_status = true
		if crouch_status && fall_status:
			emit_signal("stance_standing")
		velocity.y += 64

#Use this func to ensure the character waits before each step
#func _on_stance_crouch():
#	collision.scale = Vector2(1, 0.5)
#	collision.position += Vector2(0, 1) * (grid_size / 2)
#	crouch_status = true
#	moving = false
#	print("Add Timer to delay this for animation")

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



