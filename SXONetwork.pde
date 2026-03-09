class SXONetwork {
  SXOGame game;
  Server server;
  Client client;
  Client remoteClient;
  boolean isHost = false;
  boolean connected = false;

  SXONetwork(SXOGame game) {
    this.game = game;
  }

  String getLocalIP() {
    try {
      java.net.DatagramSocket socket = new java.net.DatagramSocket();
      socket.connect(java.net.InetAddress.getByName("8.8.8.8"), 10002);
      String ip = socket.getLocalAddress().getHostAddress();
      socket.close();
      return ip;
    } catch (Exception e) {
      return "127.0.0.1";
    }
  }

  String ipToRoomCode(String ip) {
    String[] parts = ip.split("\\.");
    String code = "";
    for (String p : parts) {
      int val = Integer.parseInt(p);
      code += String.format("%02X", val);
    }
    return code;
  }

  String roomCodeToIP(String code) {
    if (code.length() != 8) return null;
    try {
      String ip = "";
      for (int i = 0; i < 8; i += 2) {
        int val = Integer.parseInt(code.substring(i, i + 2), 16);
        if (val < 0 || val > 255) return null;
        if (ip.length() > 0) ip += ".";
        ip += val;
      }
      return ip;
    } catch (Exception e) {
      return null;
    }
  }

  void startHosting() {
    try {
      server = new Server(VSGames.this, SXO_NET_PORT);
      String localIP = getLocalIP();
      game.hostRoomCode = ipToRoomCode(localIP);
      game.lobbyState = SXO_LOBBY_HOSTING;
      isHost = true;
    } catch (Exception e) {
      game.hostRoomCode = "ERROR";
    }
  }

  boolean joining = false;
  String joinError = "";

  void joinGame(String code) {
    String ip = roomCodeToIP(code);
    if (ip == null) return;
    joining = true;
    joinError = "";
    final String targetIP = ip;
    new Thread(new Runnable() {
      public void run() {
        try {
          // Test reachability first (2 second timeout)
          java.net.InetAddress addr = java.net.InetAddress.getByName(targetIP);
          if (!addr.isReachable(2000)) {
            joinError = "Host not reachable";
            joining = false;
            return;
          }
          Client c = new Client(VSGames.this, targetIP, SXO_NET_PORT);
          if (c.active()) {
            client = c;
            connected = true;
            isHost = false;
            game.playerRole = 2;
            game.startPlay(SXO_ONLINE);
          } else {
            joinError = "Connection failed";
          }
        } catch (Exception e) {
          joinError = "Connection failed";
          if (client != null) {
            client.stop();
            client = null;
          }
        }
        joining = false;
      }
    }).start();
  }

  void sendMove(int gridIdx, int cellIdx) {
    String msg = "MOVE:" + gridIdx + ":" + cellIdx + "\n";
    if (isHost && remoteClient != null) {
      remoteClient.write(msg);
    } else if (!isHost && client != null) {
      client.write(msg);
    }
  }

  void sendRematch() {
    String msg = "REMATCH\n";
    if (isHost && remoteClient != null) {
      remoteClient.write(msg);
    } else if (!isHost && client != null) {
      client.write(msg);
    }
  }

  void receive() {
    if (!isPeerConnected()) {
      onPeerDisconnected();
      return;
    }

    Client source = null;
    if (isHost) {
      source = server.available();
    } else {
      if (client != null && client.available() > 0) {
        source = client;
      }
    }
    if (source == null) return;

    String data = source.readStringUntil('\n');
    while (data != null) {
      data = data.trim();
      if (data.startsWith("MOVE:")) {
        String[] parts = data.split(":");
        if (parts.length == 3) {
          try {
            int g = Integer.parseInt(parts[1]);
            int c = Integer.parseInt(parts[2]);
            if (game.board.isValidMove(g, c)) {
              game.executeMove(g, c);
            }
          } catch (Exception e) {}
        }
      } else if (data.equals("REMATCH")) {
        game.startPlay(SXO_ONLINE);
      }
      data = source.readStringUntil('\n');
    }
  }

  boolean isPeerConnected() {
    if (isHost) {
      return remoteClient != null && remoteClient.active();
    } else {
      return client != null && client.active();
    }
  }

  void onPeerDisconnected() {
    stop();
    game.disconnectMessage = "Opponent disconnected";
    game.disconnectMessageTime = millis();
    game.state = SXO_MENU;
    game.particles.clear();
  }

  void stop() {
    if (server != null) { server.stop(); server = null; }
    if (client != null) { client.stop(); client = null; }
    remoteClient = null;
    connected = false;
    isHost = false;
  }

  void onServerEvent(Server s, Client c) {
    remoteClient = c;
    connected = true;
    game.playerRole = 1;
    game.startPlay(SXO_ONLINE);
  }

  void onDisconnectEvent(Client c) {
    connected = false;
    stop();
    game.state = SXO_MENU;
    game.particles.clear();
  }
}
