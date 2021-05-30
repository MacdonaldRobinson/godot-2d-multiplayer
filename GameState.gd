extends Node

sync var players:Dictionary = {}
sync var world_data_sync = { time_left=20, has_game_ended=false }

var self_data = {name="", position=Vector2(0, 0), flip_h=false, animation="idle", health=100, score=0}

var world = preload("res://components/worlds/world1/World1.tscn").instance();
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
		
	rpc("add_player_to_world", self_data);
	
	print("server created: ", port_number, " | Max clients allowed: ", max_clients)

func server_disconnected():
	print("server_disconnected")	

	
func join_server(server_address, port_number, player_name):
	self_data.name = player_name;
	
	var network = NetworkedMultiplayerENet.new()
	network.create_client(server_address, int(port_number));			
	get_tree().network_peer = network
	
	print("SERVER_IP: ", server_address, " | PORT: ", port_number, " | ", self_data)
	
func connection_failed():
	print("connection_failed")	
	
func start_game():
	get_tree().root.remove_child(get_tree().current_scene)
	get_tree().root.add_child(world)	
	pass

func connected_to_server():	
	rpc("add_player_to_world", self_data);
	
	print("connected_to_server")	
	
func network_peer_connected(id):	
	print("network_peer_connected: ", id)	

func network_peer_disconnected(id):
	rpc("remove_player_from_world", id)
	print("network_peer_disconnected: ", id)		

func _process(delta):		
	var id = get_tree().get_rpc_sender_id()
	
	var players_scene = world.get_node("Players");
	
	
	if players_scene == null:
		return				
		
	for player in players:		
		rpc("add_player_to_world", self_data);
		rpc("update_player_data", self_data)

	handle_fireballs()
	
func get_nodes_in_player_group(player_id):
	get_tree().get_nodes_in_group(get_player_group_name(player_id))	
	
func get_player_group_name(player_id):
	return "player_"+str(player_id);
	
func add_to_player_group(player_id, node):
	node.add_to_group(get_player_group_name(player_id))

remotesync func reset_players():
	for player_id in GameState.players:
		var player_data = GameState.players[player_id]
		player_data.score = 0
		player_data.health = 100

remotesync func update_world_sync(world_data):
	print("update_world_sync", world_data)
	GameState.world_data_sync = world_data	
	rset("world_data_sync", GameState.world_data_sync)

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
		players[id]	= player_data
		
		var player_scene = players_scene.get_node(str(id))
		
		if player_scene != null:
			var player_sprite = player_scene.get_node("Animations");
			var health_bar = player_scene.get_node("HealthBar") as ProgressBar;
			
			player_scene.position = player_data.position
			player_sprite.flip_h = player_data.flip_h
			player_sprite.animation = player_data.animation
			health_bar.value = player_data.health
			
			
	
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
