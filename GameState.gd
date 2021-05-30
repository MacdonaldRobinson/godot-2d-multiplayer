extends Node

sync var players:Dictionary = {}
sync var world_data_sync = { }
var lobby_game_time = 60
sync var time_left = 60

var self_data = {name="", position=Vector2(0, 0), flip_h=false, animation="idle", health=100, score=0}

var world_scene:String= "res://components/worlds/world1/World1.tscn"
var lobby_scene = "res://Lobby.tscn"
var world = null
var lobby = null;

var player_scene_preload = preload("res://components/players/player1/Player.tscn");
var fireball_scene = preload("res://components/players/player1/Fireball.tscn")

func _ready():
	get_tree().connect("network_peer_connected", self, "network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "network_peer_disconnected")		
	get_tree().connect("server_disconnected", self, "server_disconnected")	
	
	get_tree().connect("connected_to_server", self, "connected_to_server")		
	get_tree().connect("connection_failed", self, "connection_failed")
	

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

func create_server(port_number, max_clients, player_name):	
	self_data.name = player_name;

	var network = NetworkedMultiplayerENet.new()
	network.create_server(int(port_number), int(max_clients));		
	get_tree().network_peer = network
	create_world()
	
	rpc("add_player_to_world", self_data);
	
	print("server created: ", port_number, " | Max clients allowed: ", max_clients)

func show_lobby():
	var lobby_instance = load(lobby_scene).instance()
	get_tree().root.remove_child(get_tree().current_scene)
	get_tree().root.add_child(lobby_instance)	
	get_tree().current_scene = lobby_instance
	lobby_instance.player_name_field.text = GameState.self_data.name
	
	if get_tree().network_peer == null:
		lobby_instance.join_button.visibile = true
		lobby_instance.host_button.visibile = true

func server_disconnected():
	print("server_disconnected")
	show_lobby()

	
func join_server(server_address, port_number, player_name):
	self_data.name = player_name;
	
	var network = NetworkedMultiplayerENet.new()
	network.create_client(server_address, int(port_number));			
	get_tree().network_peer = network
	
	print("SERVER_IP: ", server_address, " | PORT: ", port_number, " | ", self_data)
	
func connection_failed():
	print("connection_failed")	
	
func create_world():
	world = load(world_scene).instance()	
	GameState.self_data.health = 100
	GameState.self_data.score = 0
	GameState.self_data.position = Vector2(0, 0)	
	
	
remotesync func start_game():
	rpc("_start_game")
	
remotesync func _start_game():	
	get_tree().root.remove_child(get_tree().current_scene)
	get_tree().root.add_child(world)	
	get_tree().current_scene = world	
	
	if get_tree().is_network_server():
		lobby_game_time = lobby.game_time_field.text
		time_left = lobby_game_time
		
func connected_to_server():	
	create_world()
	GameState.players={}
	rpc("add_player_to_world", self_data);
	
	print("connected_to_server")	
	
func network_peer_connected(id):	
	print("network_peer_connected: ", id)	

func network_peer_disconnected(id):
	rpc("remove_player_from_world", id)
	print("network_peer_disconnected: ", id)		

func _process(delta):		
	var id = get_tree().get_rpc_sender_id()
	
	if world == null:
		return
		
	var players_scene = world.get_node("Players");
	
	if players_scene == null:
		return		
		
	for player in players:		
		rpc("add_player_to_world", self_data)
		rpc("update_player_data", self_data)
		
	if get_tree().is_network_server():
		rpc("update_time_left", time_left)

	handle_fireballs()
	
func get_nodes_in_player_group(player_id):
	get_tree().get_nodes_in_group(get_player_group_name(player_id))	
	
func get_player_group_name(player_id):
	return "player_"+str(player_id);
	
func add_to_player_group(player_id, node):
	node.add_to_group(get_player_group_name(player_id))

func get_alive_players():
	var players_alive = []
	
	for player_id in GameState.players:
		var player_data = GameState.players[player_id]
		if player_data.health > 0:
			players_alive.push_back(player_id)
			
	return players_alive

func get_dead_players():
	var players_alive = []
	
	for player_id in GameState.players:
		var player_data = GameState.players[player_id]
		if player_data.health <= 0:
			players_alive.push_back(player_id)
			
	return players_alive

func get_sorted_player_data_by_score():
	var sorted_player_data:Array = GameState.players.values()		
	sorted_player_data.sort_custom(self, "sorted_player_data_custom_comparison")
	
	return sorted_player_data
	
func sorted_player_data_custom_comparison(a, b):
	if a.score > b.score:
		return true
	else:
		return false

remotesync func update_time_left(time_left):
	GameState.time_left = time_left	
	
remotesync func reset_players():
	print("reset_players", GameState.players)
	
	if get_tree().is_network_server():
		GameState.time_left = lobby_game_time
	
	for player_id in GameState.players:
		rpc("reset_player", player_id);
	
remotesync func reset_player(player_id):
	print("reset_player", player_id)

	var player_data = GameState.players[player_id]

	player_data.position = Vector2(0, 0)
	player_data.health = 100
	player_data.score = 0
	
	var player: KinematicBody2D = GameState.world.get_node("Players").get_node(str(player_id))
	player.position = player_data.position	
	player.set_physics_process(true)
	player.set_process(true)

remotesync func remove_player_from_world(id):
			
	print("remove_player_from_world: ",id, " | current", players.keys())
	players.erase(id)	
	
	var players_scene = world.get_node("Players");
	
	if players_scene == null:
		return
		
	if players_scene.has_node(str(id)):
		var player_scene = players_scene.get_node(str(id))
		player_scene.queue_free()
		
	print("done remove_player_from_world: ",id, " | current", players.keys())


remotesync func update_player_data(player_data):
	var id = get_tree().get_rpc_sender_id()
	
	if !players.has(id):
		return
	
	var players_scene = world.get_node("Players");
	
	if players_scene == null:
		return		
	
	if players_scene.has_node(str(id)):
		
		var player_scene:KinematicBody2D = players_scene.get_node(str(id))
		
		if player_scene != null:
			var player_collider = player_scene.get_node("CollisionShape2D") as CollisionShape2D;
			var player_sprite = player_scene.get_node("Animations");
			var player_name = player_scene.get_node("Name") as Label;
			var health_bar = player_scene.get_node("HealthBar") as ProgressBar;
			
			player_name.text = player_data.name + " - " + str(player_data.score)
			player_scene.position = player_data.position
			player_sprite.flip_h = player_data.flip_h
			player_sprite.animation = player_data.animation
			health_bar.value = player_data.health
			
			if player_data.health <= 0:
				player_collider.disabled = true
			else:
				player_collider.disabled = false

	
remotesync func add_player_to_world(player_data):
	var id = get_tree().get_rpc_sender_id()
	var players_scene = world.get_node("Players");	
	
	if players.has(id) and players_scene.has_node(str(id)):
		return
	
	if players_scene == null:
		return	
	
	print("add_player_to_world: ",id, " | current", players.keys())
	
	if !players_scene.has_node(str(id)):
		players[id]	= player_data
		
		var player_scene = player_scene_preload.instance()
		var player_sprite = player_scene.get_node("Animations");
		var player_name = player_scene.get_node("Name");
		
		player_name.text = player_data.name
		player_scene.name = str(id)
		player_scene.position = player_data.position
		player_sprite.flip_h = player_data.flip_h
		player_scene.set_network_master(id)
		
		world.get_node("Players").add_child(player_scene)


func handle_fireballs():
	var fireball_nodes = get_tree().get_nodes_in_group("fireball")
	
	for fireball in fireball_nodes:		
		var fireball_animations = fireball.get_node("AnimatedSprite");
		
		if fireball_animations.flip_h:		
			fireball.global_position.x -= 20
		else:
			fireball.global_position.x += 20
