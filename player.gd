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
var leaping = false
var grid_size = 64
var moving = false
var movement_status = true
var turning = false
var sprintMode = false
# Status's (Standing, Crouching, Climbing, Falling, Jumping)
var crouch_status = false
var ledge_status = false
var fall_status = true
var jump_status = false

var speed: float = 200.0
var move_distance: float = 64.0  # Set the distance you want the player to move before stopping
var distance_moved: float = 0.0

var cur_move = Vector2(0,0)
var first_step = true
var next_pos = Vector2(0,0)
var current_pos = Vector2(0,0)


func _physics_process(delta):
	input()
	move(delta)
	floorCheck(delta)
	ledgeCheck(delta)
	move_and_slide()
	
# Connect the signal to the crouching function
#Handles key inputs
func input():
	if Input.is_action_just_pressed("move_up"):
		cur_move = (Vector2(0, -1))
	elif Input.is_action_just_pressed("move_down"):
		cur_move = (Vector2(0, 1))
	elif Input.is_action_pressed("move_left"):
		moving = true
		cur_move = (Vector2(-1, 0))
	elif Input.is_action_pressed("move_right"):
		moving = true
		cur_move = (Vector2(1, 0))
	
	if Input.is_action_pressed("sprint_key"):
		sprintMode = true
	else:
		sprintMode = false
		
		
func move(delta):
	if moving:
		movement_status = false
		if sprintMode:
			velocity = cur_move.normalized() * speed
		else:
			velocity = cur_move.normalized() * (speed / 2)
		move_and_slide()
		distance_moved += speed * delta
		if distance_moved >= move_distance:
			emit_signal("movement_completed")
func _on_movement_completed():
	# Handle any additional logic that should occur after movement completes
	
	velocity = Vector2(0,0)
	position = Vector2(round(position.x / 64) * 64, round(position.y / 64) * 64)
	distance_moved = 0.0
	print((round(position.x / 64) * 64))
	print("Movement completed!")
	moving = false
	movement_status = true
		
func _on_action_timer_timeout():
	moving = false
	velocity = Vector2(0,0)
	print("timer end")

func leap():
	if !falling && !moving:
		leaping = true
		var i = 0;
	if headray.is_colliding() or legray.is_colliding():
		print('Wall')
	else:
		print("Jump")
		velocity.x = grid_size * 5
		velocity.y = -grid_size * 5
		print(velocity)
		leaping = false
#		leapCycle(i)
## Handles movement
#
func leapCycle(i):
	var tween
	if i <= 4:
		tween = create_tween()
	#Lets first get the direction
	var vector_pos = headray.target_position
	#This dictates the X direction
	var destination = position + vector_pos
	if headray.is_colliding() or legray.is_colliding():
		print('Wall')
	else:
		print("Jump")
		leaping = false
#	elif i == 0:
#		tween.tween_property(self, "position", destination - Vector2(0, 32), 0.3)
#		i+=1
#		tween.tween_callback(leapCycle.bind(i))
#	elif i == 1:
#		tween.tween_property(self, "position", destination - Vector2(0, 32), 0.3)
#		i+=1
#		tween.tween_callback(leapCycle.bind(i))
#	elif i == 2:
#		tween.tween_property(self, "position", destination - Vector2(0, 32), 0.3)
#		i+=1
#		tween.tween_callback(leapCycle.bind(i))
#	elif i == 3:
#		tween.tween_property(self, "position", destination + Vector2(0, 32), 0.3)
#		i+=1
#		tween.tween_callback(leapCycle.bind(i))
#	elif i == 4:
#		tween.tween_property(self, "position", destination + Vector2(0, 32), 0.3)
#		i+=1
#		tween.tween_callback(leapCycle.bind(i))

#	else:
#		leaping = false
#		print(ledge_status)

func ledgeCheck(delta):

	if climb_reach.is_colliding() && jump_status && !ledge_status && leaping:
		ledge_status = true
		jump_status = false
		var ledge_object = climb_reach.get_collider()
		position.y = ledge_object.position.y
		print('lathcing')
		
func floorCheck(delta):
	if !ledge_status && !leaping:
		if ground_check.is_colliding():
			fall_status = false
		else:
			fall_status = true
		if crouch_status && fall_status:
			emit_signal("stance_standing")
		velocity.y += 64
		

#Handles Tweening
func tweening(position, vector_pos, duration):
	var tween = get_tree().create_tween()
	var destination = position + vector_pos
	if duration:
		tween.tween_property(self, "position", destination, duration)
	else:
		tween.tween_property(self, "position", destination, 0.25)
	tween.tween_callback(resetStep)

#Use this func to ensure the character waits before each step
func resetStep():
	moving = false
func resetClimb():
	ledge_status = false
	jump_status = false
	moving = false

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

func _on_stance_turn(vector_pos, dir):
	await get_tree().create_timer(0.15).timeout
	headray.target_position = headray.target_position * -1
	legray.target_position = legray.target_position * -1
	if dir.x == -1:
		$Player.flip_h = true
	else:
		$Player.flip_h = false
	turning = false
	moving = false


