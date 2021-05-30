extends Control

onready var player_name_field = $CenterContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/HBoxContainer3/VBoxContainer/PlayerNameField
onready var players_connected_list = $CenterContainer/VBoxContainer/HBoxContainer2/VBoxContainer/PlayersConnectedList
onready var join_button = $CenterContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/HBoxContainer/Join
onready var host_button = $CenterContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/HBoxContainer/Host
onready var server_address_field = $CenterContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/HBoxContainer2/VBoxContainer/ServerAddressField
onready var port_number_field = $CenterContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/HBoxContainer2/VBoxContainer2/PortNumberField
onready var max_clients_field = $CenterContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/HBoxContainer2/VBoxContainer3/MaxClientsField
onready var start_game_button = $CenterContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/StartGameButton
onready var game_time_field = $CenterContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/HBoxContainer3/VBoxContainer2/GameTimeField

func _ready():
	start_game_button.visible = false

func _process(delta):	
	players_connected_list.clear();
	
	for player in GameState.players:			
		var name = GameState.players[player].name
		players_connected_list.add_item(name)
	
	if get_tree().network_peer != null:
		if get_tree().is_network_server():
			server_config()
		else:
			client_config()
	else:
		reset_buttons()
		
func reset_buttons():
	start_game_button.visible = false
	host_button.visible = true
	join_button.visible = true

func server_config():
	start_game_button.visible = true
	host_button.visible = false
	join_button.visible = false
		
func client_config():
	start_game_button.visible = true
	host_button.visible = false
	join_button.visible = false

func _on_Host_pressed():
	GameState.create_server(port_number_field.text, max_clients_field.text, player_name_field.text)	
	GameState.time_left = int(game_time_field.text)
	
func _on_Join_pressed():
	GameState.join_server(server_address_field.text, port_number_field.text, player_name_field.text)	
	
func disable_buttons():
	join_button.disabled = true
	host_button.disabled = true
	
func enable_buttons():
	join_button.disabled = true
	host_button.disabled = true	

func _on_StartGameButton_pressed():
	GameState.self_data.name = player_name_field.text
	GameState.lobby_game_time = int(game_time_field.text)
	
	if get_tree().is_network_server():
		GameState.start_game()
	else:
		GameState._start_game()
		
