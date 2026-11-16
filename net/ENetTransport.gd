class_name ENetTransport
extends NetTransport

## ENetMultiplayerPeer tabanlı yerel ağ (LAN) taşıma uygulaması.


func create_host(port: int, max_clients: int) -> MultiplayerPeer:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_server(port, max_clients)
	if err != OK:
		push_error("ENet sunucu başlatılamadı (hata %d)" % err)
		return null
	return peer


func create_client(address: String, port: int) -> MultiplayerPeer:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_client(address, port)
	if err != OK:
		push_error("ENet istemci bağlanamadı (hata %d)" % err)
		return null
	return peer
