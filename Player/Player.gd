extends KinematicBody2D

const PlayHurtSound = preload("res://Player/PlayerHurtSound.tscn")

# Deklarations
export var MAX_SPEED    = 80
export var ROLL_SPEED   = 110
export var ACCELERATION = 500
export var FRICTION     = 500

enum{
	MOVE,
	ROLL,
	ATTACK
}

var state = MOVE
var velocity = Vector2.ZERO
var roll_vector = Vector2.DOWN
var stats = PlayerStats


onready var animationPlayer = $AnimationPlayer
onready var animationTree   = $AnimationTree 
onready var animationState  = animationTree.get("parameters/playback")
onready var swordHitbox     = $HitboxPivot/SwordHitbox
onready var hurtbox = $Hurtbox
onready var blinkAnimationPlayer = $BlinkAnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	stats.connect("no_health", self, "queue_free")
	animationTree.active = true
	swordHitbox.knockback_vector = roll_vector


func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta)
			
		ROLL:
			roll_state()
			
		ATTACK:
			attack_state()


func move_state(delta):
	var input_vector = Vector2.DOWN
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	#print(velocity)
	
	if input_vector != Vector2.ZERO:
		roll_vector = input_vector
		swordHitbox.knockback_vector = input_vector
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		animationTree.set("parameters/Attack/blend_position", input_vector)
		animationTree.set("parameters/Roll/blend_position", input_vector)
		animationState.travel("Run")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
		#velocity += input_vector * ACCELERATION * delta
		#velocity = velocity.clamped(MAX_SPEED * delta)
	else:
		animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		
	velocity = move_and_slide(velocity)
	
	if Input.is_action_just_released("roll"):
		state = ROLL
	
	if Input.is_action_just_released("attack"):
		state = ATTACK
	
	
func roll_state():
	velocity = roll_vector * ROLL_SPEED
	animationState.travel("Roll")
	velocity = move_and_slide(velocity)
	
func attack_state():
	velocity = Vector2.ZERO
	animationState.travel("Attack")


func roll_animation_finished():
	velocity = velocity * 0.8
	state = MOVE


func attack_animation_finisched():
	state = MOVE


func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	hurtbox.start_invinciblitiy(0.5)
	hurtbox.create_hit_effect()
	var playerHurtSound = PlayHurtSound.instance()
	get_tree().current_scene.add_child(playerHurtSound)


func _on_Hurtbox_invincibility_started():
	blinkAnimationPlayer.play("Start")


func _on_Hurtbox_invincibility_ended():
	blinkAnimationPlayer.play("Stop")
