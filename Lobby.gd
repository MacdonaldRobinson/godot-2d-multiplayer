extends Control

onready var player_name_field = $CenterContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/VBoxContainer/PlayerNameField
onready var players_connected_list = $CenterContainer/VBoxContainer/HBoxContainer2/VBoxContainer/PlayersConnectedList
onready var join_button = $CenterContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/HBoxContainer/Join
onready var host_button = $CenterContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/HBoxContainer/Host
onready var server_address_field = $CenterContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/HBoxContainer2/VBoxContainer/ServerAddressField
onready var port_number_field = $CenterContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/HBoxContainer2/VBoxContainer2/PortNumberField
onready var max_clients_field = $CenterContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/HBoxContainer2/VBoxContainer3/MaxClientsField

func _process(delta):	
	players_connected_list.clear();
	
	for player in GameState.players:			
		var name = GameState.players[player].name
		players_connected_list.add_item(name)
		
func _on_Host_pressed():
	GameState.create_server(port_number_field.text, max_clients_field.text, player_name_field.text)

func _on_Join_pressed():
	GameState.join_server(server_address_field.text, port_number_field.text, player_name_field.text)

func disable_buttons():
	join_button.disabled = true
	host_button.disabled = true
	
func enable_buttons():
	join_button.disabled = true
	host_button.disabled = true	

func _on_StartGameButton_pressed():
	GameState.start_game()
