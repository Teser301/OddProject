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
var movement_status = false

var turning = false
var sprintMode = false
# Status's (Standing, Crouching, Climbing, Falling, Jumping)
var crouch_status = false
var ledge_status = false
var fall_status = true
var jump_status = false
var leap_status = false
var leaping = false

var distanceToTravel : Vector2 = Vector2(0,0)
var distanceToJump: Vector2 = Vector2(0,0)
var distanceToLeap: Vector2 = Vector2(0,0)
var queued_actions: Array = []
var actionTimer: int = 0
var actionTime: bool = false
var action: String


func _physics_process(delta):
	input()
	inMotion()
	floorCheck()
	move_and_slide()
	
# Connect the signal to the crouching function
#Handles key inputs
func input():
	if Input.is_action_pressed("sprint_key"):
		sprintMode = true
	else:
		sprintMode = false
		
	if Input.is_action_pressed("move_leap"):
		leaping = true
		move(Vector2(0, 0))
	elif Input.is_action_pressed("move_right") && Input.is_action_pressed("move_left"):
		pass
	elif Input.is_action_pressed("move_down"):
		move(Vector2(0, 1))
	elif Input.is_action_pressed("move_right"):
		move(Vector2(1, 0))
	elif Input.is_action_pressed("move_left"):
		move(Vector2(-1, 0))
	elif Input.is_action_pressed("move_up"):
		move(Vector2(0, -1))
		
		
#Remember. Move * Time = 64 or 128
var movement = 4
var movementSprint = movement * 2
var movementTime = 16

func move(direction):
	if !movement_status && !leaping :
		if direction.x && !ledge_status:
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
			if direction.y == -1:
				if !ledge_status && !crouch_status:
					distanceToJump = direction * 16
					queued_actions.append("jump_action")
				elif ledge_status && !crouch_status:
					queued_actions.append("climbing_action")
				elif crouch_status:
					queued_actions.append("stand_action")
			if direction.y == 1:
				queued_actions.append("crouch_action")
	elif !movement_status && leaping:
		distanceToLeap = Vector2(sign(headray.target_position.x),sign(headray.target_position.x)) * 8
		queued_actions.append("leap_action")


func inMotion():
	if queued_actions.size() > 0:
		movement_status = true
	if movement_status:
		# This is where the loop finishes
		if actionTimer == 16:
			#At the moment turning is instant. Will revamp for animation possibly
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
		#Actions based on input
		else:
			#Start with nothing on 0. Add the action into this loop.
			if actionTimer == 0:
				action = queued_actions.pop_front()
			#Based on the input of the code above, activate one of these below
			#Moving
			if action == "move_action":
				if headray.is_colliding():
					print('ouch')
					position = Vector2(round(position.x / 64) * 64, round(position.y / 64) * 64)
				else:
					position += distanceToTravel
			#Turning
			if action == "turning_action":
				pass
			#Jumping
			if action == "jump_action":
				jump_status = true
				if !ledge_status:
					position += distanceToJump
				if climb_reach.is_colliding() && !ledge_status:
					var ledge_object = climb_reach.get_collider()
					if ledge_object.name == "Ledge":
						ledge_status = true
						print(ledge_object)
						position.y = ledge_object.position.y
					
			#Climbing after latching from jump
			if action == "climbing_action":
				var latchTween = get_tree().create_tween()
				var destination = position + Vector2(0, -62)
				latchTween.tween_property(self, "position", destination, 0.3)
				ledge_status = false
			#Leaping
			if action == "leap_action":
				leaping = false
				leap_status = true
				if headray.is_colliding() && actionTimer <= 15:
					position = Vector2(round(position.x / 64) * 64, round(position.y / 64) * 64)
				elif actionTimer >= 8:
					position.x += distanceToLeap.x * 1.5
					position.y += abs(distanceToLeap.y)
				else:
					position.x += distanceToLeap.x * 1.5
					position.y -= abs(distanceToLeap.y)
			#Crouching
			if action == "crouch_action":
				if !crouch_status:
					emit_signal("stance_crouch")

			if action == "stand_action":
				if crouch_status:
					emit_signal("stance_standing")
			actionTimer += 1
			
			
func _on_movement_completed():
	movement_status = false
	turning = false
	leap_status = false
	jump_status = false
	actionTimer = 0
	print("Movement complete")

func floorCheck():
	if !ledge_status && !jump_status && !leap_status:
		if ground_check.is_colliding():
			fall_status = false
			position.y = round(position.y)
		else:
			fall_status = true
		if crouch_status && fall_status:
			emit_signal("stance_standing")
		velocity.y += 64

#Use this func to ensure the character waits before each step
func _on_stance_crouch():
	crouch_status = true
	collision.scale = Vector2(1, 0.5)
	collision.position.y = 96

func _on_stance_standing():
	crouch_status = false
	collision.scale = Vector2(1, 1)
	collision.position.y = 64
	
func _on_debug_pressed():
	falling = false
	leaping = false
	turning = false
	sprintMode = false
	jump_status = false
	fall_status = true
	#Hard set position and scale back to standing
	position = Vector2(576,-320)
	collision.scale = Vector2(1, 1)
	collision.position = Vector2(32,64)



