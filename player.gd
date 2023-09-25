extends CharacterBody2D

@onready var climb_up_short = $ClimbCheck2
@onready var climb_up = $ClimbCheck
@onready var crouch_climb = $CrouchClimb
@onready var headray = $HeadCheck
@onready var legray = $LegCheck
@onready var ground = $GroundCheck
@onready var fallTime = $FallTime
@onready var collision = $playerCollision

signal stance_turn
signal stance_crouch
signal stance_standing

var time = 0
var falling = false
var jumping = false
var grid_size = 16
var moving = false
var turning = false
var crouching = false
var crouchHandling = false
var ledge_status = false
var valid_spacing = [16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176, 192, 208, 224, 240, 256, 272, 288, 304, 320]

func _physics_process(delta):
	input()


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

		
func leap():
	if !falling && !moving && !jumping :
		jumping = true
		var vector_pos = headray.target_position * 4
		jumpTween(position, vector_pos, headray.target_position)
		
#Handles movement
func move(dir):
	if dir && !falling && !moving :
		moving = true
		var vector_pos = dir * grid_size
		# If input is Left or Right
		if dir.x:
			# Make the raycast arrow follow where player is facing
			if headray.target_position != vector_pos:
				turning = true
				_on_stance_turn(vector_pos)
				return
			## Check for what is coliding
			headray.force_raycast_update()
			legray.force_raycast_update()
			# Basic movement
			if !headray.is_colliding() && !legray.is_colliding()  && !turning:
				tweening(position, vector_pos, 0.25)
			# Enable Crouch Mode
			elif headray.is_colliding() && !legray.is_colliding() && !crouching:
				emit_signal("stance_crouch")
			# In Crouch Mode, move
			elif headray.is_colliding() && !legray.is_colliding() && crouching:
				tweening(position, vector_pos, 0.25)
			# Vault
			elif !headray.is_colliding() && legray.is_colliding():
				vector_pos.y = -grid_size
				tweening(position, vector_pos, 0.25)
			# If none of them fit, don't move.
			else:
				moving = false
			# If input is Up or Down
		elif dir.y:
			# If player is hanging onto ledge and presses up, climb
			if ledge_status && dir.y == -1:
				ledge_status = false
				vector_pos.y -= grid_size * 2
				tweening(position.round(), vector_pos , 0.25)
			elif climb_up_short.is_colliding() && !ledge_status && !crouching && dir.y == -1 :
				ledge_status = true
				moving = false
			elif climb_up.is_colliding() && !ledge_status && !crouching && dir.y == -1:
				ledge_status = true
				print(position.round())
				tweening(position.round(), vector_pos , 0.25)
			# Crouching
			if dir.y == 1 && !crouching:
				emit_signal("stance_crouch")
			elif dir.y == -1 && crouching && !crouch_climb.is_colliding():
				print(crouching)
				emit_signal("stance_standing")
			elif dir.y == -1 && !crouching:
				if !climb_up_short.is_colliding() && !climb_up.is_colliding():
					vector_pos.y -= grid_size
					tweening(position, vector_pos, 0.25)
			else:
				moving = false

func jumpTween(position, vector_pos, direction):
	var tween = get_tree().create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	var destination = position + vector_pos
	var airTime
	
	if direction.x > 0:
		airTime = position + vector_pos + Vector2(-32, -16)
	elif direction.x < 0:
		airTime = position + vector_pos + Vector2(32, -16)
	
	tween.tween_property(self, "position", airTime, 0.25)
	tween.tween_property(self, "position", destination, 0.25)
	if tween.is_running() && headray.is_colliding():
		print("Fuck")
		tween.stop()
	position = destination
	tween.tween_callback(shuffleStep)
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
	jumping = false
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
	collision.scale = Vector2(1, 0.5)
	collision.position += Vector2(0, 8)
	moving = false
	crouching = true

func _on_stance_standing():
	collision.scale = Vector2(1, 1)
	collision.position = Vector2(8, 16)
	print("standing")
	moving = false
	crouching = false
	
func _on_debug_pressed():
	falling = false
	jumping = false
	moving = false
	turning = false
	crouching = false
	crouchHandling = false
	ledge_status = false
	position = Vector2(144, 208)
	collision.scale = Vector2(1, 1)
	collision.position = Vector2(8,16)

func _on_stance_turn(vector_pos):
	await get_tree().create_timer(0.15).timeout
	headray.target_position = vector_pos
	legray.target_position = vector_pos
	turning = false
	moving = false
