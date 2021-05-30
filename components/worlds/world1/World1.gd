extends Node2D

onready var time_left_field = $CanvasLayer/Control/HBoxContainer/TimeLeftField
onready var timer = $CanvasLayer/Control/Timer
onready var winner_panel = $CanvasLayer/Control/CenterContainer/WinnerPopupPanel
onready var winner_name_field = $CanvasLayer/Control/CenterContainer/WinnerPopupPanel/VBoxContainer/HBoxContainer/WinnerNameField

func _ready():
	hide_winner_panel()
	
func _process(delta):
	var time_left = GameState.world_data_sync.time_left
	
	time_left_field.text = str(time_left)

	if time_left <= 0:		
		show_winner();


func get_sorted_player_data():
	var sorted_player_data:Array = GameState.players.values()		
	sorted_player_data.sort_custom(self, "customComparison")
	
	return sorted_player_data
			
func customComparison(a, b):
	if a.score > b.score:
		return true
	else:
		return false

func show_winner():
	var sorted_player_data = get_sorted_player_data()	
	winner_name_field.text = sorted_player_data[0].name
	
	GameState.world_data_sync.has_game_ended = true
	
	winner_panel.show()	
	
	
func hide_winner_panel():
	winner_panel.hide()
	

func _on_Timer_timeout():
	if get_tree().is_network_server():
		var time_left = GameState.world_data_sync.time_left
		time_left-= 1		
		
		time_left_field.text = str(time_left)	
		
		if time_left == 0:
			timer.stop()
			
		GameState.world_data_sync.time_left = time_left
		
		GameState.update_world_sync(GameState.world_data_sync)


func _on_Restart_pressed():
	hide_winner_panel()
	rpc("reset_players")
	
