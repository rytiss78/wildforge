extends Node
var step=""
var peer
var err
const ERR_OK=0
func _ready():
	print("ENET_TEST_START")
	peer=ENetMultiplayerPeer.new()
	print("ENetMultiplayerPeer created: "+str(peer))
	step="create_server"
	err=peer.create_server(29736,3)
	print("create_server(29736,3) error="+str(err)+" OK="+str(ERR_OK))
	if err!=ERR_OK:
		print("ENET_HOST_CREATE_FAILED error="+str(err))
		peer.close()
		get_tree().quit(1)
	else:
		print("ENET_HOST_CREATED")
		print("connection_status="+str(peer.get_connection_status()))
		step="poll"
		peer.poll()
		print("poll ok, status="+str(peer.get_connection_status()))
		peer.close()
		get_tree().quit(0)