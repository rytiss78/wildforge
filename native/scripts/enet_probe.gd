extends SceneTree

# Run with: Godot_v4.7.2-stable_win64_console.exe --headless --path native --script res://scripts/enet_probe.gd
# This deliberately avoids Wildforge's game startup, testing whether the bundled Godot supports ENet and IPv4 loopback.
const PORT = 29736
var server: ENetMultiplayerPeer
var client: ENetMultiplayerPeer
var start_ms = 0
var sent = false
var got_pong = false
var host_got_ping = false
var host_accepted = false

func _initialize() -> void:
	start_ms = Time.get_ticks_msec()
	server = ENetMultiplayerPeer.new()
	client = ENetMultiplayerPeer.new()
	server.peer_connected.connect(func(id: int):
		host_accepted = true
		print("ENET_PROBE host_peer_connected=", id)
	)
	var host_error = server.create_server(PORT, 2)
	print("ENET_PROBE host_create=", host_error)
	if host_error != OK:
		print("ENET_PROBE FAIL: cannot bind UDP ", PORT, " (error=", host_error, ")")
		quit(2)
		return
	var client_error = client.create_client("127.0.0.1", PORT)
	print("ENET_PROBE client_create=", client_error)
	if client_error != OK:
		print("ENET_PROBE FAIL: cannot start localhost client (error=", client_error, ")")
		quit(3)

func _process(_delta: float) -> bool:
	if server == null or client == null:
		return false
	server.poll()
	client.poll()
	if client.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and not sent:
		client.set_target_peer(1)
		client.transfer_mode = MultiplayerPeer.TRANSFER_MODE_RELIABLE
		var send_error = client.put_packet("probe_ping".to_utf8_buffer())
		print("ENET_PROBE client_sent=", send_error)
		sent = true
	while server.get_available_packet_count() > 0:
		var source = server.get_packet_peer()
		var message = server.get_packet().get_string_from_utf8()
		print("ENET_PROBE server_received=", message, " from=", source)
		if message == "probe_ping":
			host_got_ping = true
			server.set_target_peer(source)
			server.transfer_mode = MultiplayerPeer.TRANSFER_MODE_RELIABLE
			server.put_packet("probe_pong".to_utf8_buffer())
	while client.get_available_packet_count() > 0:
		var message = client.get_packet().get_string_from_utf8()
		print("ENET_PROBE client_received=", message)
		if message == "probe_pong":
			got_pong = true
	if got_pong and host_got_ping and host_accepted:
		print("ENET_PROBE PASS: local ENet handshake and reliable packets work")
		quit(0)
		return true
	if Time.get_ticks_msec() - start_ms > 12000:
		print("ENET_PROBE FAIL: timeout; server_status=", server.get_connection_status(), " client_status=", client.get_connection_status(), " host_accepted=", host_accepted, " sent=", sent, " host_got_ping=", host_got_ping, " pong=", got_pong)
		quit(4)
		return true
	return false
