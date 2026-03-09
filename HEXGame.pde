final int HEX_MENU = 0;
final int HEX_PLAYING = 1;
final int HEX_GAMEOVER = 2;
final int HEX_HOWTO = 3;
final int HEX_LOBBY = 4;

final int HEX_TWO_PLAYER = 0;
final int HEX_AI_MODE = 1;
final int HEX_ONLINE = 2;

final int HEX_BOARD_SIZE = 11;

class HEXGame extends GameBase {
  int state;
  int mode;
  int currentPlayer;
  int winner;
  HEXBoard board;
  HEXRenderer renderer;
  ArrayList<Particle> particles;

  int howToPage;

  int lastRow, lastCol;
  int[] winPath;

  // AI
  int[] aiMove;
  int aiMoveTime;
  boolean aiThinking;

  int gameOverTime;

  // Online
  GameNetwork network;
  int lobbyState;
  int playerRole;
  String roomCode = "";
  String disconnectMessage = "";
  int disconnectMessageTime = 0;

  HEXGame() {
    particles = new ArrayList<Particle>();
    renderer = new HEXRenderer(this);
    network = new GameNetwork();
  }

  String getName() { return "Hex"; }
  color getColor() { return color(140, 80, 200); }

  void init() {
    state = HEX_MENU;
    particles.clear();
    aiThinking = false;
    disconnectMessage = "";
  }

  void startPlay(int m) {
    mode = m;
    board = new HEXBoard();
    currentPlayer = 1;
    winner = 0;
    state = HEX_PLAYING;
    particles.clear();
    lastRow = -1;
    lastCol = -1;
    winPath = null;
    aiThinking = false;
  }

  void render() {
    updateParticles(particles);

    switch (state) {
      case HEX_MENU:
        renderer.drawMenu();
        break;
      case HEX_LOBBY:
        if (network.connected && !network.isHost) {
          playerRole = 2;
          startPlay(HEX_ONLINE);
        } else {
          renderer.drawLobby();
        }
        break;
      case HEX_HOWTO:
        renderer.drawHowTo(howToPage);
        break;
      case HEX_PLAYING:
        if (mode == HEX_AI_MODE && currentPlayer == 2 && !aiThinking) {
          startAIMove();
        }
        if (aiThinking) updateAI();
        if (mode == HEX_ONLINE) hexReceive();
        renderer.drawGame();
        break;
      case HEX_GAMEOVER:
        if (mode == HEX_ONLINE) hexReceive();
        renderer.drawGame();
        break;
    }
  }

  void executeMove(int row, int col) {
    board.placeStone(row, col, currentPlayer);
    lastRow = row;
    lastCol = col;

    if (board.checkWin(currentPlayer)) {
      winner = currentPlayer;
      winPath = board.getWinPath(currentPlayer);
      state = HEX_GAMEOVER;
      gameOverTime = millis();
      spawnWinParticles();
      return;
    }

    currentPlayer = (currentPlayer == 1) ? 2 : 1;
  }

  // Input

  void onMousePressed() {
    switch (state) {
      case HEX_MENU:
        handleMenuClick();
        break;
      case HEX_LOBBY:
        handleLobbyClick();
        break;
      case HEX_HOWTO:
        int nav = handleHowToNav(howToPage, 2);
        if (nav == -1) state = HEX_MENU;
        else howToPage = nav;
        break;
      case HEX_PLAYING:
        handlePlayClick();
        break;
      case HEX_GAMEOVER:
        handleGameOverClick();
        break;
    }
  }

  void onKeyPressed() {
    if (state == HEX_LOBBY && lobbyState == LOBBY_JOINING) {
      if (key == ENTER || key == RETURN) {
        if (roomCode.length() == 8) network.joinGame(roomCode);
        return;
      }
      roomCode = lobbyHandleKey(roomCode);
    }
  }

  void onEscape() {
    switch (state) {
      case HEX_MENU:
        returnToLauncher();
        break;
      case HEX_HOWTO:
        state = HEX_MENU;
        break;
      case HEX_LOBBY:
        network.stop();
        state = HEX_MENU;
        break;
      case HEX_PLAYING:
      case HEX_GAMEOVER:
        if (mode == HEX_ONLINE) network.stop();
        state = HEX_MENU;
        particles.clear();
        break;
    }
  }

  void handleMenuClick() {
    float bw = 200, bh = 50;
    if (mouseX > CANVAS_W/2 - bw/2 && mouseX < CANVAS_W/2 + bw/2) {
      if (mouseY > 310 - bh/2 && mouseY < 310 + bh/2) startPlay(HEX_TWO_PLAYER);
      if (mouseY > 375 - bh/2 && mouseY < 375 + bh/2) startPlay(HEX_AI_MODE);
      if (mouseY > 440 - bh/2 && mouseY < 440 + bh/2) { state = HEX_LOBBY; lobbyState = LOBBY_CHOOSE; roomCode = ""; }
      if (mouseY > 505 - bh/2 && mouseY < 505 + bh/2) { state = HEX_HOWTO; howToPage = 0; }
      if (mouseY > 570 - bh/2 && mouseY < 570 + bh/2) returnToLauncher();
    }
  }

  void handlePlayClick() {
    if (mode == HEX_AI_MODE && currentPlayer == 2) return;
    if (mode == HEX_ONLINE && currentPlayer != playerRole) return;

    int[] cell = renderer.pixelToHex(mouseX, mouseY);
    if (cell == null) return;
    if (!board.isOnBoard(cell[0], cell[1])) return;
    if (board.grid[cell[0]][cell[1]] != 0) return;

    if (mode == HEX_ONLINE) network.send("MOVE:" + cell[0] + ":" + cell[1]);
    executeMove(cell[0], cell[1]);
  }

  void handleGameOverClick() {
    float elapsed = (millis() - gameOverTime) / 1000.0;
    if (elapsed < 1.0) return;

    float bw = 200, bh = 50;
    float rx = CANVAS_W/2 - 110;
    float ry = 45;
    if (mouseX > rx - bw/2 && mouseX < rx + bw/2 && mouseY > ry - bh/2 && mouseY < ry + bh/2) {
      if (mode == HEX_ONLINE) network.send("REMATCH");
      startPlay(mode);
    }
    float mx = CANVAS_W/2 + 110;
    float my = 45;
    if (mouseX > mx - bw/2 && mouseX < mx + bw/2 && mouseY > my - bh/2 && mouseY < my + bh/2) {
      if (mode == HEX_ONLINE) network.stop();
      state = HEX_MENU;
      particles.clear();
    }
  }

  // AI

  void startAIMove() {
    aiThinking = true;
    aiMoveTime = millis();
    aiMove = hexFindBestMove(board, 2);
  }

  void updateAI() {
    if (!aiThinking) return;
    if (millis() - aiMoveTime < 600) return;
    if (aiMove != null) {
      executeMove(aiMove[0], aiMove[1]);
    }
    aiThinking = false;
  }

  // Network

  void hexReceive() {
    if (!network.isPeerConnected()) {
      network.stop();
      disconnectMessage = "Opponent disconnected";
      disconnectMessageTime = millis();
      state = HEX_MENU;
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
            if (board.isOnBoard(r, c) && board.grid[r][c] == 0) {
              executeMove(r, c);
            }
          } catch (Exception e) {}
        }
      } else if (data.equals("REMATCH")) {
        startPlay(HEX_ONLINE);
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
        state = HEX_MENU;
        break;
    }
  }

  void onServerEvent(Server s, Client c) {
    network.onServerEvent(s, c);
    playerRole = 1;
    startPlay(HEX_ONLINE);
  }

  void onDisconnectEvent(Client c) {
    network.onDisconnectEvent(c);
    state = HEX_MENU;
    particles.clear();
  }

  // Particles

  void spawnWinParticles() {
    color c = (winner == 1) ? HEX_COLOR_P1 : HEX_COLOR_P2;
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
