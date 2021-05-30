extends Node2D

onready var time_left_field = $CanvasLayer/Control/HBoxContainer/TimeLeftField
onready var timer:Timer = $CanvasLayer/Control/Timer
onready var winner_panel = $CanvasLayer/Control/WinnerPopupPanel
onready var winner_name_field = $CanvasLayer/Control/WinnerPopupPanel/VBoxContainer/CenterContainer/HBoxContainer/WinnerNameField
onready var reset_button = $CanvasLayer/Control/WinnerPopupPanel/VBoxContainer/CenterContainer2/HBoxContainer/Reset
onready var lobby_button = $CanvasLayer/Control/WinnerPopupPanel/VBoxContainer/CenterContainer2/HBoxContainer/Lobby

func _ready():
	hide_winner_panel()
	
var ticks = 0
func _process(delta):
	var time_left = GameState.time_left
	
	var alive_players = GameState.get_alive_players()
	
	if time_left <= 0 or (alive_players.size() <= 1 and GameState.players.size() > 1):
		show_winner()
	else:
		hide_winner_panel();
	
	time_left_field.text = str(time_left)
	
	if get_tree().is_network_server():
		reset_button.visible = true	
		lobby_button.visible = true
	else:
		reset_button.visible = false
		lobby_button.visible = false

func show_winner():	
	var sorted_player_data = GameState.get_sorted_player_data_by_score()	
	winner_name_field.text = sorted_player_data[0].name	
	winner_panel.show()	
	
func hide_winner_panel():
	winner_panel.hide()
	
func _on_Timer_timeout():
	
	if get_tree().is_network_server():
		var time_left = GameState.time_left
		time_left-= 1		
		
		time_left_field.text = str(time_left)	
		
		if time_left <= 0:
			time_left = 0
		
		GameState.time_left = time_left

func _on_Reset_pressed():			
	GameState.reset_players()

func _on_Lobby_pressed():
	GameState.show_lobby()
