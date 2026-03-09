final int C4_MENU = 0;
final int C4_PLAYING = 1;
final int C4_GAMEOVER = 2;
final int C4_DROPPING = 3;
final int C4_HOWTO = 4;
final int C4_LOBBY = 5;

final int C4_TWO_PLAYER = 0;
final int C4_AI_MODE = 1;
final int C4_ONLINE = 2;

final int C4_COLS = 7;
final int C4_ROWS = 6;

class C4Game extends GameBase {
  int state;
  int mode;
  int currentPlayer;
  int winner;
  int howToPage;
  C4Board board;
  C4Renderer renderer;
  ArrayList<Particle> particles;

  // Drop animation
  int dropCol;
  int dropTargetRow;
  float dropCurrentY;
  int dropStartTime;
  int dropPlayer;

  // Win line
  int[] winLine;

  // AI
  int aiMoveCol;
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

  C4Game() {
    particles = new ArrayList<Particle>();
    renderer = new C4Renderer(this);
    network = new GameNetwork();
  }

  String getName() { return "Connect Four"; }
  color getColor() { return color(30, 100, 200); }

  void init() {
    state = C4_MENU;
    particles.clear();
    aiThinking = false;
    disconnectMessage = "";
  }

  void startPlay(int m) {
    mode = m;
    board = new C4Board();
    currentPlayer = 1;
    winner = 0;
    state = C4_PLAYING;
    particles.clear();
    winLine = null;
    aiThinking = false;
  }

  void render() {
    updateParticles(particles);

    switch (state) {
      case C4_MENU:
        renderer.drawMenu();
        break;
      case C4_LOBBY:
        if (network.connected && !network.isHost) {
          playerRole = 2;
          startPlay(C4_ONLINE);
          break;
        }
        renderer.drawLobby();
        break;
      case C4_PLAYING:
        if (mode == C4_AI_MODE && currentPlayer == 2 && !aiThinking) {
          startAIMove();
        }
        if (aiThinking) updateAI();
        if (mode == C4_ONLINE) c4Receive();
        renderer.drawGame();
        break;
      case C4_DROPPING:
        updateDropAnimation();
        if (mode == C4_ONLINE) c4Receive();
        renderer.drawGame();
        break;
      case C4_GAMEOVER:
        if (mode == C4_ONLINE) c4Receive();
        renderer.drawGame();
        break;
      case C4_HOWTO:
        renderer.drawHowTo(howToPage);
        break;
    }
  }

  void executeDrop(int col) {
    int targetRow = -1;
    for (int r = C4_ROWS - 1; r >= 0; r--) {
      if (board.grid[r][col] == 0) {
        targetRow = r;
        break;
      }
    }
    if (targetRow == -1) return;

    dropCol = col;
    dropTargetRow = targetRow;
    dropCurrentY = renderer.offsetY - renderer.cellSize;
    dropStartTime = millis();
    dropPlayer = currentPlayer;
    state = C4_DROPPING;
  }

  void updateDropAnimation() {
    float targetY = renderer.offsetY + dropTargetRow * renderer.cellSize + renderer.cellSize / 2.0;
    float startY = renderer.offsetY - renderer.cellSize;
    float totalDist = targetY - startY;
    float duration = 80 + (dropTargetRow + 1) * 50;
    float elapsed = millis() - dropStartTime;
    float t = constrain(elapsed / duration, 0, 1);
    // Ease-in (accelerating fall)
    t = t * t;
    dropCurrentY = lerp(startY, targetY, t);

    if (elapsed >= duration) {
      finishDrop();
    }
  }

  void finishDrop() {
    board.dropPiece(dropCol, dropPlayer);
    int w = board.checkWin();
    if (w != 0) {
      winner = w;
      winLine = board.getWinLine();
      state = C4_GAMEOVER;
      gameOverTime = millis();
      spawnWinParticles(w);
      return;
    }
    if (board.isFull()) {
      winner = 3;
      state = C4_GAMEOVER;
      gameOverTime = millis();
      spawnDrawParticles();
      return;
    }
    currentPlayer = (currentPlayer == 1) ? 2 : 1;
    state = C4_PLAYING;
  }

  // AI

  void startAIMove() {
    aiThinking = true;
    aiMoveTime = millis();
    aiMoveCol = c4FindBestMove(board, 2);
  }

  void updateAI() {
    if (!aiThinking) return;
    if (millis() - aiMoveTime < 300) return;
    aiThinking = false;
    if (aiMoveCol >= 0 && board.isValidDrop(aiMoveCol)) {
      executeDrop(aiMoveCol);
    }
  }

  // Input

  void onMousePressed() {
    switch (state) {
      case C4_MENU:
        handleMenuClick();
        break;
      case C4_LOBBY:
        handleLobbyClick();
        break;
      case C4_PLAYING:
        handlePlayClick();
        break;
      case C4_DROPPING:
        break;
      case C4_GAMEOVER:
        handleGameOverClick();
        break;
      case C4_HOWTO:
        int nav = handleHowToNav(howToPage, 2);
        if (nav == -1) state = C4_MENU;
        else howToPage = nav;
        break;
    }
  }

  void onKeyPressed() {
    if (state == C4_LOBBY && lobbyState == LOBBY_JOINING) {
      if (key == ENTER || key == RETURN) {
        if (roomCode.length() == 8) network.joinGame(roomCode);
        return;
      }
      roomCode = lobbyHandleKey(roomCode);
    }
  }

  void onEscape() {
    switch (state) {
      case C4_MENU:
        returnToLauncher();
        break;
      case C4_LOBBY:
        network.stop();
        state = C4_MENU;
        break;
      case C4_PLAYING:
      case C4_DROPPING:
      case C4_GAMEOVER:
        if (mode == C4_ONLINE) network.stop();
        state = C4_MENU;
        particles.clear();
        break;
      case C4_HOWTO:
        state = C4_MENU;
        break;
    }
  }

  void handleMenuClick() {
    float bw = 200, bh = 50;
    float cx = CANVAS_W / 2;
    if (mouseX > cx - bw/2 && mouseX < cx + bw/2) {
      if (mouseY > 310 - bh/2 && mouseY < 310 + bh/2) {
        startPlay(C4_TWO_PLAYER);
      } else if (mouseY > 375 - bh/2 && mouseY < 375 + bh/2) {
        startPlay(C4_AI_MODE);
      } else if (mouseY > 440 - bh/2 && mouseY < 440 + bh/2) {
        state = C4_LOBBY;
        lobbyState = LOBBY_CHOOSE;
        roomCode = "";
      } else if (mouseY > 505 - bh/2 && mouseY < 505 + bh/2) {
        state = C4_HOWTO;
        howToPage = 0;
      } else if (mouseY > 570 - bh/2 && mouseY < 570 + bh/2) {
        returnToLauncher();
      }
    }
  }

  void handlePlayClick() {
    if (mode == C4_AI_MODE && currentPlayer == 2) return;
    if (mode == C4_ONLINE && currentPlayer != playerRole) return;

    int col = renderer.getColumnAtMouse();
    if (col < 0 || col >= C4_COLS) return;
    if (!board.isValidDrop(col)) return;

    if (mode == C4_ONLINE) network.send("MOVE:" + col);
    executeDrop(col);
  }

  void handleGameOverClick() {
    float elapsed = (millis() - gameOverTime) / 1000.0;
    if (elapsed < 1.0) return;

    float bw = 200, bh = 50;
    float rx = CANVAS_W / 2 - 110;
    float ry = 60;
    if (mouseX > rx - bw/2 && mouseX < rx + bw/2 && mouseY > ry - bh/2 && mouseY < ry + bh/2) {
      if (mode == C4_ONLINE) network.send("REMATCH");
      startPlay(mode);
    }
    float mx = CANVAS_W / 2 + 110;
    if (mouseX > mx - bw/2 && mouseX < mx + bw/2 && mouseY > ry - bh/2 && mouseY < ry + bh/2) {
      if (mode == C4_ONLINE) network.stop();
      state = C4_MENU;
      particles.clear();
    }
  }

  // Network

  void c4Receive() {
    if (!network.isPeerConnected()) {
      network.stop();
      disconnectMessage = "Opponent disconnected";
      disconnectMessageTime = millis();
      state = C4_MENU;
      particles.clear();
      return;
    }
    String data = network.receiveNext();
    while (data != null) {
      if (data.startsWith("MOVE:")) {
        String[] parts = data.split(":");
        if (parts.length == 2) {
          try {
            int col = Integer.parseInt(parts[1]);
            if (board.isValidDrop(col)) {
              executeDrop(col);
            }
          } catch (Exception e) {}
        }
      } else if (data.equals("REMATCH")) {
        startPlay(C4_ONLINE);
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
        state = C4_MENU;
        break;
    }
  }

  void onServerEvent(Server s, Client c) {
    network.onServerEvent(s, c);
    playerRole = 1;
    startPlay(C4_ONLINE);
  }

  void onDisconnectEvent(Client c) {
    network.onDisconnectEvent(c);
    state = C4_MENU;
    particles.clear();
  }

  // Particles

  void spawnWinParticles(int w) {
    color c = (w == 1) ? C4_COLOR_P1 : C4_COLOR_P2;
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

  void spawnDrawParticles() {
    for (int i = 0; i < 40; i++) {
      particles.add(new Particle(random(CANVAS_W), random(100, CANVAS_H), color(150)));
    }
  }
}
