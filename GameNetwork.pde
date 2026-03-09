final int NET_PORT = 12345;

class GameNetwork {
  Server server;
  Client client;
  Client remoteClient;
  volatile boolean isHost = false;
  volatile boolean connected = false;
  volatile boolean joining = false;
  volatile String joinError = "";
  String hostRoomCode = "";

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
      server = new Server(VSGames.this, NET_PORT);
      String localIP = getLocalIP();
      hostRoomCode = ipToRoomCode(localIP);
      isHost = true;
    } catch (Exception e) {
      hostRoomCode = "ERROR";
    }
  }

  void joinGame(String code) {
    String ip = roomCodeToIP(code);
    if (ip == null) return;
    joining = true;
    joinError = "";
    final String targetIP = ip;
    final GameNetwork self = this;
    new Thread(new Runnable() {
      public void run() {
        try {
          java.net.InetAddress addr = java.net.InetAddress.getByName(targetIP);
          if (!addr.isReachable(2000)) {
            joinError = "Host not reachable";
            joining = false;
            return;
          }
          Client c = new Client(VSGames.this, targetIP, NET_PORT);
          if (c.active()) {
            client = c;
            connected = true;
            isHost = false;
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

  void send(String msg) {
    if (!msg.endsWith("\n")) msg += "\n";
    if (isHost && remoteClient != null) {
      remoteClient.write(msg);
    } else if (!isHost && client != null) {
      client.write(msg);
    }
  }

  String receiveNext() {
    Client source = null;
    if (isHost) {
      source = server != null ? server.available() : null;
    } else {
      if (client != null && client.available() > 0) {
        source = client;
      }
    }
    if (source == null) return null;
    String data = source.readStringUntil('\n');
    if (data != null) data = data.trim();
    return data;
  }

  boolean isPeerConnected() {
    if (isHost) {
      return remoteClient != null && remoteClient.active();
    } else {
      return client != null && client.active();
    }
  }

  void stop() {
    if (server != null) { server.stop(); server = null; }
    if (client != null) { client.stop(); client = null; }
    remoteClient = null;
    connected = false;
    isHost = false;
    joining = false;
    joinError = "";
    hostRoomCode = "";
  }

  void onServerEvent(Server s, Client c) {
    remoteClient = c;
    connected = true;
  }

  void onDisconnectEvent(Client c) {
    connected = false;
    stop();
  }
}
