extends CharacterBody2D
class_name PlayerController

@onready var climb_reach = $ClimbReach
@onready var crouch_climb = $CrouchClimb
@onready var headray = $HeadCheck
@onready var legray = $LegCheck
@onready var ground = $GroundCheck
@onready var collision = $playerCollision

signal stance_turn
signal stance_crouch
signal stance_standing

var time = 0
var falling = false
var jumping = false
var grid_size = 64
var moving = false
var turning = false
var crouching = false
var crouchHandling = false
var ledge_status = false
var valid_spacing = [16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176, 192, 208, 224, 240, 256, 272, 288, 304, 320]

func _physics_process(delta):
	input()
	climbCheck()

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
	if !falling && !moving && !jumping:
		jumping = true
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
		floorCheck()
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
		jumping = false
		floorCheck()

func move(dir):
	if dir && !falling && !moving :
		moving = true
		
		var vector_pos = dir * grid_size
		# If input is Left or Right
		if dir.x && !ledge_status:
			# Make the raycast arrow follow where player is facing
			if headray.target_position != vector_pos :
				turning = true
				_on_stance_turn(vector_pos, dir)
				return
			## Check for what is coliding
			headray.force_raycast_update()
			legray.force_raycast_update()
			# Basic movement
			if !headray.is_colliding() && !legray.is_colliding()  && !turning && !ledge_status:
				tweening(position, vector_pos, 0.25)
				
				$Player/PlayerAnim.play("walk")
				
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
			if dir.y == -1:
				tweening(position.round(), vector_pos , 0.15)
				moving = false
				climbCheck()
#			# Climbing
			if dir.y == -1 && ledge_status:
				tweening(position.round(), vector_pos * 3 , 0.15)
				moving = false
				ledge_status = false
				print("stop climbing")
#			# Crouching
#			if dir.y == 1 && !crouching && !ledge_status && !falling:
#				emit_signal("stance_crouch")
#			elif dir.y == -1 && crouching && !crouch_climb.is_colliding():
#				emit_signal("stance_standing")
#			elif dir.y == -1 && !crouching:
#				if !climb_up_short.is_colliding() && !climb_up.is_colliding():
#					vector_pos.y -= grid_size
#					tweening(position, vector_pos, 0.25)
#			else:
#				moving = false
		else:
			moving = false

func climbCheck():
	if climb_reach.is_colliding() && !ledge_status:
		print("we hit")
		ledge_status = true
		var testNode = climb_reach.get_collider()
		var a = Vector2(0,0)
#		a.y += testNode.get_position().y + (64 * 3)
#		position.y += a.y
		
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
		climb_reach.force_raycast_update()
		if !climb_reach.is_colliding:
			print('headbang')
		if crouching:
#			emit_signal("stance_standing")
			if !climb_reach.is_colliding():
				emit_signal("stance_standing")
		falling = true
		var vector_pos = Vector2(0, 1) * (grid_size)
		var tween = create_tween()
		var destination = position + vector_pos
		tweening(position, vector_pos, 0.15)
	else:
		falling = false
		jumping = false
#Timer for falling
func _on_fall_time_timeout():
	floorCheck()

func _on_stance_crouch():
	collision.scale = Vector2(1, 0.5)
	collision.position += Vector2(0, 1) * (grid_size / 2)
	moving = false
	crouching = true

func _on_stance_standing():
	collision.scale = Vector2(1, 1)
	collision.position -= Vector2(0, 1) * (grid_size / 2)
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
	position = Vector2(32, 80)
	collision.scale = Vector2(1, 1)

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
