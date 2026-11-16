class_name NetTransport
extends RefCounted

## Çok oyunculu taşıma katmanı soyut arayüzü (ENet, WebRTC veya Relay için).


## Sunucu (Host) eşini oluşturur.
func create_host(_port: int, _max_clients: int) -> MultiplayerPeer:
	push_error("NetTransport.create_host alt sınıfta uygulanmalı.")
	return null


## İstemci (Client) eşini oluşturur.
func create_client(_address: String, _port: int) -> MultiplayerPeer:
	push_error("NetTransport.create_client alt sınıfta uygulanmalı.")
	return null
