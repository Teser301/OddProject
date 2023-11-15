extends CharacterBody2D
class_name PlayerController

@onready var climb_reach = $ClimbReach
@onready var crouch_climb = $CrouchClimb
@onready var headray = $HeadCheck
@onready var legray = $LegCheck
@onready var ground_check = $GroundCheck
@onready var collision = $playerCollision
@onready var jump_time = $JumpTime

signal stance_turn
signal stance_crouch
signal stance_standing

var falling = false
var leaping = false
var grid_size = 64
var moving = false
var turning = false
var sprintMode = false
# Status's (Standing, Crouching, Climbing, Falling, Jumping)
var crouch_status = false
var ledge_status = false
var fall_status = true
var jump_status = false


func _physics_process(delta):
	input()
	floorCheck(delta)
	ledgeCheck(delta)
# Connect the signal to the crouching function
#Handles key inputs
func input():
	if Input.is_action_just_pressed("move_up"):
		move(Vector2(0, -1))
	elif Input.is_action_just_pressed("move_down"):
		move(Vector2(0, 1))
	elif Input.is_action_pressed("move_left"):
		move(Vector2(-1, 0))
	elif Input.is_action_pressed("move_right"):
		move(Vector2(1, 0))
	elif Input.is_action_just_pressed("move_leap"):
		leap()
	# Check for sprint key
	if Input.is_action_pressed("sprint_key"):
		sprintMode = true
	else:
		sprintMode = false
		
func move(dir):
	if dir &&  !moving && !jump_status:
		moving = true
		var vector_pos = dir * grid_size
		# If input is Left or Right
		if dir.x && !ledge_status && !fall_status :
			# Make the raycast arrow follow where player is facing
			if headray.target_position != vector_pos :
				turning = true
				_on_stance_turn(vector_pos, dir)
				return
			## Check for what is coliding
			headray.force_raycast_update()
			legray.force_raycast_update()
			# Basic movement
			if !headray.is_colliding() && !legray.is_colliding()  && !turning:
				if sprintMode:
					tweening(position, vector_pos, 0.20)
				else:
					tweening(position, vector_pos, 0.30)
				$Player/PlayerAnim.play("walk")
			# Enable Crouch Mode
			elif headray.is_colliding() && !legray.is_colliding():
				print('crotch check')
				if crouch_status:
					tweening(position, vector_pos, 0.25)
				elif !crouch_status:
					emit_signal("stance_crouch")
				
			# In Crouch Mode, move
			elif headray.is_colliding() && !legray.is_colliding():
				tweening(position, vector_pos, 0.25)
			# Vault
			elif !headray.is_colliding() && legray.is_colliding():
				vector_pos.y = -grid_size
				tweening(position, vector_pos, 0.25)
			# If none of them fit, don't move.
			else:
				resetStep()
		# If input is Up or Down
		elif dir.y:
			if dir.y == -1 && crouch_status:
				emit_signal("stance_standing")
			elif dir.y == -1 && !ledge_status:
				print("Jump")
				velocity.y -= grid_size * 15
				move_and_slide()
				moving = false
				jump_status = true
			elif dir.y == -1 && ledge_status:
				print('Climbing')
				velocity = Vector2(0,0)
				var tween = get_tree().create_tween()
				var destination = position + (vector_pos * 3)
				tween.tween_property(self, "position", destination, 0.25)
				tween.tween_callback(resetClimb)	
			elif dir.y == 1 :
				emit_signal("stance_crouch")
				moving = false
			else:
				resetStep()
		else:
			resetStep()
#	else:
#		var notTrue = ""
#		if !dir:
#			notTrue += "dir is false, "
#		if falling:
#			notTrue += "falling is true, "
#		if moving:
#			notTrue += "moving is true, "
#		print("This code wasn't run because " + notTrue)
		
func leap():
	if !falling && !moving && !leaping:
		leaping = true
		var i = 0;
		var tween = create_tween()
		var vector_pos = headray.target_position
		var destination = position + vector_pos
		tween.tween_property(self, "position", position, 0.1)
		leapCycle(i)
# Handles movement

func leapCycle(i):
	var tween
	if i <= 2:
		tween = create_tween()
	var vector_pos = headray.target_position
	var destination = position + vector_pos
	if headray.is_colliding() or legray.is_colliding():
		print('Wall')
	elif i == 0:
		tween.tween_property(self, "position", destination + Vector2(0,-8), 0.1)
		i+=1
		tween.tween_callback(leapCycle.bind(i))
	elif i == 1:
		tween.tween_property(self, "position", destination, 0.1)
		i+=1
		tween.tween_callback(leapCycle.bind(i))
	elif i == 2:
		tween.tween_property(self, "position", destination - Vector2(0,-8), 0.1)
		i+=1
		tween.tween_callback(leapCycle.bind(i))
	else:
		leaping = false
		print(ledge_status)

func ledgeCheck(delta):

	if climb_reach.is_colliding() && jump_status && !ledge_status:
		ledge_status = true
		jump_status = false
		var ledge_object = climb_reach.get_collider()
		position.y = ledge_object.position.y
		print('lathcing')
		
func floorCheck(delta):
	if !ledge_status:
		if ground_check.is_colliding():
			fall_status = false
		else:
			fall_status = true
			print('fallin')
		velocity.y += 64
		move_and_slide()
		

#Handles Tweening
func tweening(position, vector_pos, duration):
	var tween = get_tree().create_tween()
	var destination = position + vector_pos
	if duration:
		tween.tween_property(self, "position", destination, duration)
	else:
		tween.tween_property(self, "position", destination, 0.25)
	position = destination
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
