final int QRD_MENU = 0;
final int QRD_PLAYING = 1;
final int QRD_GAMEOVER = 2;
final int QRD_HOWTO = 3;
final int QRD_LOBBY = 4;

final int QRD_TWO_PLAYER = 0;
final int QRD_AI_MODE = 1;
final int QRD_ONLINE = 2;

class QRDGame extends GameBase {
  int state;
  int mode;
  int currentPlayer;
  int winner;
  int howToPage;
  QRDBoard board;
  QRDRenderer renderer;
  ArrayList<Particle> particles;

  boolean wallMode;
  int wallOrientation; // 0=horizontal, 1=vertical

  // AI
  int[] aiMove;
  int aiMoveTime;
  boolean aiThinking;

  // Game over
  int gameOverTime;

  // Online
  GameNetwork network;
  int lobbyState;
  int playerRole;
  String roomCode = "";
  String disconnectMessage = "";
  int disconnectMessageTime = 0;

  QRDGame() {
    particles = new ArrayList<Particle>();
    renderer = new QRDRenderer(this);
    network = new GameNetwork();
  }

  String getName() { return "Quoridor"; }
  color getColor() { return color(180, 120, 60); }

  void init() {
    state = QRD_MENU;
    particles.clear();
    aiThinking = false;
    disconnectMessage = "";
  }

  void startPlay(int m) {
    mode = m;
    board = new QRDBoard();
    currentPlayer = 1;
    winner = 0;
    state = QRD_PLAYING;
    particles.clear();
    wallMode = false;
    wallOrientation = 0;
    aiThinking = false;
  }

  void render() {
    updateParticles(particles);

    switch (state) {
      case QRD_MENU:
        renderer.drawMenu();
        break;
      case QRD_LOBBY:
        if (network.connected && !network.isHost) {
          playerRole = 2;
          startPlay(QRD_ONLINE);
          break;
        }
        renderer.drawLobby();
        break;
      case QRD_PLAYING:
        if (mode == QRD_AI_MODE && currentPlayer == 2 && !aiThinking) {
          startAIMove();
        }
        if (aiThinking) updateAI();
        if (mode == QRD_ONLINE) qrdReceive();
        renderer.drawGame();
        break;
      case QRD_GAMEOVER:
        if (mode == QRD_ONLINE) qrdReceive();
        renderer.drawGame();
        break;
      case QRD_HOWTO:
        renderer.drawHowTo(howToPage);
        break;
    }
  }

  void executeMove(int row, int col) {
    board.movePawn(currentPlayer, row, col);
    int w = board.checkWin();
    if (w != 0) {
      winner = w;
      state = QRD_GAMEOVER;
      gameOverTime = millis();
      spawnWinParticles(w);
      return;
    }
    currentPlayer = (currentPlayer == 1) ? 2 : 1;
  }

  void executeWall(int r, int c, int orientation) {
    board.placeWall(r, c, orientation);
    board.wallsLeft[currentPlayer - 1]--;
    currentPlayer = (currentPlayer == 1) ? 2 : 1;
  }

  // AI

  void startAIMove() {
    aiThinking = true;
    aiMoveTime = millis();
    aiMove = qrdFindBestMove(board, 2);
  }

  void updateAI() {
    if (!aiThinking) return;
    if (millis() - aiMoveTime < 400) return;
    aiThinking = false;
    if (aiMove == null) return;
    if (aiMove[0] == 0) {
      executeMove(aiMove[1], aiMove[2]);
    } else {
      if (board.canPlaceWall(aiMove[1], aiMove[2], aiMove[3], 2)) {
        executeWall(aiMove[1], aiMove[2], aiMove[3]);
      }
    }
  }

  // Input

  void onMousePressed() {
    switch (state) {
      case QRD_MENU:
        handleMenuClick();
        break;
      case QRD_LOBBY:
        handleLobbyClick();
        break;
      case QRD_PLAYING:
        handlePlayClick();
        break;
      case QRD_GAMEOVER:
        handleGameOverClick();
        break;
      case QRD_HOWTO:
        int nav = handleHowToNav(howToPage, 2);
        if (nav == -1) state = QRD_MENU;
        else howToPage = nav;
        break;
    }
  }

  void onKeyPressed() {
    if (state == QRD_PLAYING) {
      if (key == 'w' || key == 'W') {
        wallMode = !wallMode;
      } else if (key == 'r' || key == 'R') {
        wallOrientation = (wallOrientation == 0) ? 1 : 0;
      }
    }
    if (state == QRD_LOBBY && lobbyState == LOBBY_JOINING) {
      if (key == ENTER || key == RETURN) {
        if (roomCode.length() == 8) network.joinGame(roomCode);
        return;
      }
      roomCode = lobbyHandleKey(roomCode);
    }
  }

  void onEscape() {
    switch (state) {
      case QRD_MENU:
        returnToLauncher();
        break;
      case QRD_LOBBY:
        network.stop();
        state = QRD_MENU;
        break;
      case QRD_PLAYING:
      case QRD_GAMEOVER:
        if (mode == QRD_ONLINE) network.stop();
        state = QRD_MENU;
        particles.clear();
        break;
      case QRD_HOWTO:
        state = QRD_MENU;
        break;
    }
  }

  void handleMenuClick() {
    float bw = 200, bh = 50;
    float cx = CANVAS_W / 2;
    if (mouseX > cx - bw/2 && mouseX < cx + bw/2) {
      if (mouseY > 310 - bh/2 && mouseY < 310 + bh/2) {
        startPlay(QRD_TWO_PLAYER);
      } else if (mouseY > 375 - bh/2 && mouseY < 375 + bh/2) {
        startPlay(QRD_AI_MODE);
      } else if (mouseY > 440 - bh/2 && mouseY < 440 + bh/2) {
        state = QRD_LOBBY;
        lobbyState = LOBBY_CHOOSE;
        roomCode = "";
      } else if (mouseY > 505 - bh/2 && mouseY < 505 + bh/2) {
        state = QRD_HOWTO;
        howToPage = 0;
      } else if (mouseY > 570 - bh/2 && mouseY < 570 + bh/2) {
        returnToLauncher();
      }
    }
  }

  void handlePlayClick() {
    if (mode == QRD_AI_MODE && currentPlayer == 2) return;
    if (mode == QRD_ONLINE && currentPlayer != playerRole) return;

    if (wallMode) {
      int[] wpos = renderer.getWallAtMouse();
      if (wpos != null) {
        if (board.canPlaceWall(wpos[0], wpos[1], wallOrientation, currentPlayer)) {
          if (mode == QRD_ONLINE) network.send("WALL:" + wpos[0] + ":" + wpos[1] + ":" + wallOrientation);
          executeWall(wpos[0], wpos[1], wallOrientation);
        }
      }
    } else {
      int[] cell = renderer.getCellAtMouse();
      if (cell != null) {
        ArrayList<int[]> valid = board.getValidPawnMoves(currentPlayer);
        for (int[] m : valid) {
          if (m[0] == cell[0] && m[1] == cell[1]) {
            if (mode == QRD_ONLINE) network.send("MOVE:" + cell[0] + ":" + cell[1]);
            executeMove(cell[0], cell[1]);
            return;
          }
        }
      }
    }
  }

  void handleGameOverClick() {
    float elapsed = (millis() - gameOverTime) / 1000.0;
    if (elapsed < 1.0) return;

    float bw = 200, bh = 50;
    float rx = CANVAS_W / 2 - 110;
    float ry = 60;
    if (mouseX > rx - bw/2 && mouseX < rx + bw/2 && mouseY > ry - bh/2 && mouseY < ry + bh/2) {
      if (mode == QRD_ONLINE) network.send("REMATCH");
      startPlay(mode);
    }
    float mx = CANVAS_W / 2 + 110;
    if (mouseX > mx - bw/2 && mouseX < mx + bw/2 && mouseY > ry - bh/2 && mouseY < ry + bh/2) {
      if (mode == QRD_ONLINE) network.stop();
      state = QRD_MENU;
      particles.clear();
    }
  }

  // Network

  void qrdReceive() {
    if (!network.isPeerConnected()) {
      network.stop();
      disconnectMessage = "Opponent disconnected";
      disconnectMessageTime = millis();
      state = QRD_MENU;
      particles.clear();
      return;
    }
    String data = network.receiveNext();
    while (data != null) {
      if (data.startsWith("MOVE:")) {
        String[] parts = data.split(":");
        if (parts.length == 3) {
          try {
            int r = Integer.parseInt(parts[1]);
            int c = Integer.parseInt(parts[2]);
            executeMove(r, c);
          } catch (Exception e) {}
        }
      } else if (data.startsWith("WALL:")) {
        String[] parts = data.split(":");
        if (parts.length == 4) {
          try {
            int r = Integer.parseInt(parts[1]);
            int c = Integer.parseInt(parts[2]);
            int o = Integer.parseInt(parts[3]);
            if (board.canPlaceWall(r, c, o, currentPlayer)) {
              executeWall(r, c, o);
            }
          } catch (Exception e) {}
        }
      } else if (data.equals("REMATCH")) {
        startPlay(QRD_ONLINE);
      }
      data = network.receiveNext();
    }
  }

  void handleLobbyClick() {
    int action = lobbyHandleClick(lobbyState, roomCode, network.joining);
    switch (action) {
      case LOBBY_ACTION_HOST:
        network.startHosting();
        lobbyState = LOBBY_HOSTING;
        break;
      case LOBBY_ACTION_JOIN_SCREEN:
        lobbyState = LOBBY_JOINING;
        roomCode = "";
        break;
      case LOBBY_ACTION_CONNECT:
        network.joinGame(roomCode);
        break;
      case LOBBY_ACTION_BACK:
      case LOBBY_ACTION_CANCEL:
        network.stop();
        state = QRD_MENU;
        break;
    }
  }

  void onServerEvent(Server s, Client c) {
    network.onServerEvent(s, c);
    playerRole = 1;
    startPlay(QRD_ONLINE);
  }

  void onDisconnectEvent(Client c) {
    network.onDisconnectEvent(c);
    state = QRD_MENU;
    particles.clear();
  }

  // Particles

  void spawnWinParticles(int w) {
    color c = (w == 1) ? QRD_COLOR_P1 : QRD_COLOR_P2;
    for (int i = 0; i < 100; i++) {
      Particle p = new Particle(random(CANVAS_W), random(-20, 20), c);
      p.vy = random(1, 4);
      p.vx = random(-2, 2);
      p.sz = random(4, 10);
      p.life = random(80, 150);
      p.maxLife = p.life;
      particles.add(p);
    }
  }
}
