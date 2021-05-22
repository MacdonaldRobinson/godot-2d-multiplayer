extends Node2D

onready var player = $".";
onready var player_animations = $Animations;
onready var player_name_label = $Name

var player_velocity = Vector2(0, 0);

func _ready():	
	player_animations.play("idle")	
	
func _physics_process(delta):
	if is_network_master():
		player_velocity.y += 10;

		if !player.is_on_floor():
			if player_velocity.y < 0:
				player_animations.play("jump")	
			elif player_velocity.y > 0:
				player_animations.play("fall")
			
		if Input.is_action_pressed("ui_left"):		
			player_animations.flip_h = true
			player_velocity.x -= 10		
			player_animations.play("walk")
		elif Input.is_action_pressed("ui_right"):		
			player_animations.flip_h = false
			player_velocity.x += 10
			player_animations.play("walk")
		elif Input.is_action_pressed("ui_up"):		
			player_velocity.y -= 30
			player_animations.play("jump")
		elif Input.is_action_pressed("ui_down"):		
			player_velocity.y += 20	
			player_animations.play("fall")
		else:
			player_velocity.x = lerp(player_velocity.x, 0, 0.1)
			if player.is_on_floor():
				player_animations.play("idle")
		
		player_velocity = player.move_and_slide(player_velocity, Vector2.UP);	
		GameState.self_data.position = player.position
		GameState.self_data.flip_h = player_animations.flip_h;
		GameState.self_data.animation = player_animations.animation
		
