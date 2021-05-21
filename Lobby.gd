extends Control

onready var player_name_textbox = $CenterContainer/VBoxContainer/PlayerNameTextBox
onready var players_connected_list = $CenterContainer/VBoxContainer/PlayersConnectedList
onready var join_button = $CenterContainer/VBoxContainer/HBoxContainer/Join
onready var host_button = $CenterContainer/VBoxContainer/HBoxContainer/Host

func _process(delta):	
	players_connected_list.clear();
	
	for player in GameState.players:			
		var name = GameState.players[player].name
		players_connected_list.add_item(name)
		
func _on_Host_pressed():
	GameState.create_server(player_name_textbox.text)
	disable_buttons()

func _on_Join_pressed():
	GameState.join_server(player_name_textbox.text)
	disable_buttons()

func disable_buttons():
	join_button.disabled = true
	host_button.disabled = true
	
func enable_buttons():
	join_button.disabled = true
	host_button.disabled = true	
