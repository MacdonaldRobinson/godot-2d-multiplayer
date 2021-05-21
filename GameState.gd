extends Node

const SERVER_IP = "127.0.0.1"
const PORT = 6969
const MAX_CLIENTS = 5

var network = NetworkedMultiplayerENet.new()

sync var players:Dictionary = {}

var self_data = { name="", position=Vector2(0, 0), flip_h=false, player_animation="idle"}

var world = preload("res://World.tscn").instance();

func _ready():
	get_tree().connect("network_peer_connected", self, "network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "network_peer_disconnected")		
	get_tree().connect("server_disconnected", self, "server_disconnected")	
	
	get_tree().connect("connected_to_server", self, "connected_to_server")		
	get_tree().connect("connection_failed", self, "connection_failed")
	

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

func create_server(player_name):
	self_data.name = player_name;
		
	network.create_server(PORT, MAX_CLIENTS);		
	get_tree().network_peer = network
		
	rpc("add_player_to_world", self_data);
	
	start_game()
	
	print("server created: ", PORT, " | Max clients allowed: ", MAX_CLIENTS)

func server_disconnected():
	print("server_disconnected")	

	
func join_server(player_name):
	self_data.name = player_name;
	
	network.create_client(SERVER_IP, PORT);			
	get_tree().network_peer = network
	
	print("SERVER_IP: ", SERVER_IP, " | PORT: ", PORT, " | ", self_data)
	
func connection_failed():
	print("connection_failed")	
	
func start_game():
	get_tree().root.remove_child(get_tree().current_scene)
	get_tree().root.add_child(world)	
	pass

func connected_to_server():	
	rpc("add_player_to_world", self_data);
	start_game()
	
	print("connected_to_server | current players: ", players)	
	
func network_peer_connected(id):	
	print("network_peer_connected: ", id, " | current players: ", players)	

func network_peer_disconnected(id):
	remove_player(id)
	print("network_peer_disconnected: ", id, " | current players: ", players)		

func remove_player(id):
	players.erase(id);	
	print("remove_player: ", id, " | current players: ", players)
	
func _process(delta):
	var players_scene = world.get_node("Players");
	
	if players_scene == null:
		return	
	
	for player_scene in players_scene.get_children():		
		if(!players.has(int(player_scene.name))):
			players_scene.remove_child(player_scene)

	for id in players:
		if id != get_tree().get_network_unique_id():
			rpc_unreliable("add_player_to_world", self_data);
			
	if get_tree().network_peer != null and get_tree().is_network_server():
		rset_unreliable("players", players)		
		

remotesync func add_player_to_world(player_data):	
	var id = get_tree().get_rpc_sender_id()
	
	#print("add_player_to_world ", id, " | ", player_data," | players ", players)	
	players[id]	= player_data
	
	var players_scene = world.get_node("Players");
	
	if players_scene == null:
		return	
		
	if !players_scene.has_node(str(id)):
		var player_scene = preload("res://Player.tscn").instance()
		var player_sprite = player_scene.get_node("Animations");
		var player_name = player_scene.get_node("Name");
		
		player_name.text = player_data.name
		player_scene.name = str(id)
		player_scene.position = player_data.position
		player_sprite.flip_h = player_data.flip_h
		player_scene.set_network_master(id)
		
		world.get_node("Players").add_child(player_scene)
	else:
		var player_scene = players_scene.get_node(str(id))
		var player_sprite = player_scene.get_node("Animations");
		
		player_scene.position = player_data.position
		player_sprite.flip_h = player_data.flip_h
		player_sprite.animation = player_data.animation
