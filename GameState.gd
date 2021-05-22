extends Node

const SERVER_IP = "127.0.0.1"
const PORT = 6969
const MAX_CLIENTS = 5

var network = NetworkedMultiplayerENet.new()

sync var players:Dictionary = {}

var self_data = {is_dead=false, name="", position=Vector2(0, 0), flip_h=false, player_animation="idle", fireballs=[]}

var world = preload("res://components/worlds/world1/World1.tscn").instance();
var player_scene_preload = preload("res://components/players/player1/Player.tscn");

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
	
	print("connected_to_server")	
	
func network_peer_connected(id):	
	print("network_peer_connected: ", id)	

func network_peer_disconnected(id):
	remove_player(id)
	print("network_peer_disconnected: ", id)		

func remove_player(id:int):	
	rpc("remove_player_from_world", id)
	
func _process(delta):	
	var id = get_tree().get_rpc_sender_id()
	
	var players_scene = world.get_node("Players");
	
	if players_scene == null:
		return	
		
	for player_scene in players_scene.get_children():			
		var player_id = int(player_scene.name);		
		if !players.has(player_id):
			players_scene.remove_child(player_scene)#		
			
		if !players.has(player_id):
			players_scene.remove_child(player_scene)
			
	for player in players:
		if id != get_tree().get_network_unique_id():
			rpc("add_player_to_world", self_data);	
			
	if get_tree().network_peer != null and get_tree().is_network_server():
		rset("players", players)		
	
	handle_fireballs()

func get_nodes_in_player_group(player_id):
	get_tree().get_nodes_in_group(get_player_group_name(player_id))	
	
func get_player_group_name(player_id):
	return "player_"+str(player_id);
	
func add_to_player_group(player_id, node):
	node.add_to_group(get_player_group_name(player_id))

remotesync func remove_player_from_world(id):
	print("Ran remove_player_from_world", id)
	players.erase(id)	
	
	var players_scene = world.get_node("Players");
	
	if players_scene == null:
		return
		
	if players_scene.has_node(str(id)):
		var player_scene = players_scene.get_node(str(id))
		player_scene.queue_free()
	
remotesync func add_player_to_world(player_data):	
	var id = get_tree().get_rpc_sender_id()
	
	players[id]	= player_data
	
	var players_scene = world.get_node("Players");
	
	if players_scene == null:
		return	
		
	if !players_scene.has_node(str(id)):
		var player_scene = player_scene_preload.instance()
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
		player_sprite.animation = player_data.player_animation	
			
		print("add_player_to_world ", id)


func handle_fireballs():
	var fireball_nodes = get_tree().get_nodes_in_group("fireball")
	
	for fireball in fireball_nodes:		
		var fireball_animations = fireball.get_node("AnimatedSprite");
		
		if fireball_animations.flip_h:		
			fireball.global_position.x -= 10
		else:
			fireball.global_position.x += 10
