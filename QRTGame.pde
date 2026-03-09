final int QRT_MENU = 0;
final int QRT_PLAYING = 1;
final int QRT_GAMEOVER = 2;
final int QRT_HOWTO = 3;
final int QRT_LOBBY = 4;

final int QRT_TWO_PLAYER = 0;
final int QRT_AI_MODE = 1;
final int QRT_ONLINE = 2;

final int QRT_PHASE_CHOOSING = 0;
final int QRT_PHASE_PLACING = 1;

class QRTGame extends GameBase {
  int state;
  int mode;
  int currentPlayer;
  int winner;
  int howToPage;
  int turnPhase;
  boolean firstTurn;
  QRTBoard board;
  QRTRenderer renderer;
  ArrayList<Particle> particles;

  // AI
  int[] aiPlacement;
  int aiChosenPiece;
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

  QRTGame() {
    particles = new ArrayList<Particle>();
    renderer = new QRTRenderer(this);
    network = new GameNetwork();
  }

  String getName() { return "Quarto"; }
  color getColor() { return color(140, 70, 180); }

  void init() {
    state = QRT_MENU;
    particles.clear();
    aiThinking = false;
    disconnectMessage = "";
  }

  void startPlay(int m) {
    mode = m;
    board = new QRTBoard();
    currentPlayer = 1;
    winner = 0;
    turnPhase = QRT_PHASE_CHOOSING;
    firstTurn = true;
    state = QRT_PLAYING;
    particles.clear();
    aiThinking = false;
  }

  void render() {
    updateParticles(particles);

    switch (state) {
      case QRT_MENU:
        renderer.drawMenu();
        break;
      case QRT_LOBBY:
        if (network.connected && !network.isHost) {
          playerRole = 2;
          startPlay(QRT_ONLINE);
          break;
        }
        renderer.drawLobby();
        break;
      case QRT_PLAYING:
        if (mode == QRT_AI_MODE && currentPlayer == 2 && !aiThinking) {
          startAIMove();
        }
        if (aiThinking) updateAI();
        if (mode == QRT_ONLINE) qrtReceive();
        renderer.drawGame();
        break;
      case QRT_GAMEOVER:
        if (mode == QRT_ONLINE) qrtReceive();
        renderer.drawGame();
        break;
      case QRT_HOWTO:
        renderer.drawHowTo(howToPage);
        break;
    }
  }

  void executePlacement(int row, int col) {
    int placer = currentPlayer;
    board.placePiece(row, col, placer);
    int w = board.checkWin();
    if (w != 0) {
      winner = w;
      state = QRT_GAMEOVER;
      gameOverTime = millis();
      spawnWinParticles(w);
      return;
    }
    if (board.isFull()) {
      winner = 3;
      state = QRT_GAMEOVER;
      gameOverTime = millis();
      spawnDrawParticles();
      return;
    }
    turnPhase = QRT_PHASE_CHOOSING;
  }

  void executeChoose(int pieceId) {
    board.choosePiece(pieceId);
    currentPlayer = (currentPlayer == 1) ? 2 : 1;
    turnPhase = QRT_PHASE_PLACING;
    firstTurn = false;
  }

  // AI

  void startAIMove() {
    aiThinking = true;
    aiMoveTime = millis();
    if (turnPhase == QRT_PHASE_PLACING) {
      aiPlacement = qrtFindBestPlacement(board, 2);
      aiChosenPiece = -1;
    } else {
      aiPlacement = null;
      aiChosenPiece = qrtFindBestPieceToGive(board, 2);
    }
  }

  void updateAI() {
    if (!aiThinking) return;
    if (millis() - aiMoveTime < 400) return;
    aiThinking = false;

    if (turnPhase == QRT_PHASE_PLACING && aiPlacement != null) {
      executePlacement(aiPlacement[0], aiPlacement[1]);
      if (state == QRT_PLAYING && !board.isFull()) {
        // AI now needs to choose a piece to give
        aiThinking = true;
        aiMoveTime = millis();
        aiChosenPiece = qrtFindBestPieceToGive(board, 2);
        aiPlacement = null;
      }
    } else if (turnPhase == QRT_PHASE_CHOOSING && aiChosenPiece >= 0) {
      executeChoose(aiChosenPiece);
    }
  }

  // Input

  void onMousePressed() {
    switch (state) {
      case QRT_MENU:
        handleMenuClick();
        break;
      case QRT_LOBBY:
        handleLobbyClick();
        break;
      case QRT_PLAYING:
        handlePlayClick();
        break;
      case QRT_GAMEOVER:
        handleGameOverClick();
        break;
      case QRT_HOWTO:
        int nav = handleHowToNav(howToPage, 2);
        if (nav == -1) state = QRT_MENU;
        else howToPage = nav;
        break;
    }
  }

  void onKeyPressed() {
    if (state == QRT_LOBBY && lobbyState == LOBBY_JOINING) {
      if (key == ENTER || key == RETURN) {
        if (roomCode.length() == 8) network.joinGame(roomCode);
        return;
      }
      roomCode = lobbyHandleKey(roomCode);
    }
  }

  void onEscape() {
    switch (state) {
      case QRT_MENU:
        returnToLauncher();
        break;
      case QRT_LOBBY:
        network.stop();
        state = QRT_MENU;
        break;
      case QRT_PLAYING:
      case QRT_GAMEOVER:
        if (mode == QRT_ONLINE) network.stop();
        state = QRT_MENU;
        particles.clear();
        break;
      case QRT_HOWTO:
        state = QRT_MENU;
        break;
    }
  }

  void handleMenuClick() {
    float bw = 200, bh = 50;
    float cx = CANVAS_W / 2;
    if (mouseX > cx - bw/2 && mouseX < cx + bw/2) {
      if (mouseY > 310 - bh/2 && mouseY < 310 + bh/2) {
        startPlay(QRT_TWO_PLAYER);
      } else if (mouseY > 375 - bh/2 && mouseY < 375 + bh/2) {
        startPlay(QRT_AI_MODE);
      } else if (mouseY > 440 - bh/2 && mouseY < 440 + bh/2) {
        state = QRT_LOBBY;
        lobbyState = LOBBY_CHOOSE;
        roomCode = "";
      } else if (mouseY > 505 - bh/2 && mouseY < 505 + bh/2) {
        state = QRT_HOWTO;
        howToPage = 0;
      } else if (mouseY > 570 - bh/2 && mouseY < 570 + bh/2) {
        returnToLauncher();
      }
    }
  }

  void handlePlayClick() {
    if (mode == QRT_AI_MODE && currentPlayer == 2) return;
    if (mode == QRT_ONLINE && currentPlayer != playerRole) return;

    if (turnPhase == QRT_PHASE_PLACING) {
      int[] cell = renderer.getCellAtMouse();
      if (cell == null) return;
      if (board.grid[cell[0]][cell[1]] != -1) return;
      if (board.selectedPiece < 0) return;

      if (mode == QRT_ONLINE) network.send("PLACE:" + cell[0] + ":" + cell[1]);
      executePlacement(cell[0], cell[1]);
    } else {
      int pieceId = renderer.getPaletteAtMouse();
      if (pieceId < 0) return;
      if (!board.available[pieceId]) return;

      if (mode == QRT_ONLINE) network.send("CHOOSE:" + pieceId);
      executeChoose(pieceId);
    }
  }

  void handleGameOverClick() {
    float elapsed = (millis() - gameOverTime) / 1000.0;
    if (elapsed < 1.0) return;

    float bw = 200, bh = 50;
    float rx = CANVAS_W / 2 - 110;
    float ry = 60;
    if (mouseX > rx - bw/2 && mouseX < rx + bw/2 && mouseY > ry - bh/2 && mouseY < ry + bh/2) {
      if (mode == QRT_ONLINE) network.send("REMATCH");
      startPlay(mode);
    }
    float mx = CANVAS_W / 2 + 110;
    if (mouseX > mx - bw/2 && mouseX < mx + bw/2 && mouseY > ry - bh/2 && mouseY < ry + bh/2) {
      if (mode == QRT_ONLINE) network.stop();
      state = QRT_MENU;
      particles.clear();
    }
  }

  // Network

  void qrtReceive() {
    if (!network.isPeerConnected()) {
      network.stop();
      disconnectMessage = "Opponent disconnected";
      disconnectMessageTime = millis();
      state = QRT_MENU;
      particles.clear();
      return;
    }
    String data = network.receiveNext();
    while (data != null) {
      if (data.startsWith("PLACE:")) {
        String[] parts = data.split(":");
        if (parts.length == 3) {
          try {
            int row = Integer.parseInt(parts[1]);
            int col = Integer.parseInt(parts[2]);
            executePlacement(row, col);
          } catch (Exception e) {}
        }
      } else if (data.startsWith("CHOOSE:")) {
        String[] parts = data.split(":");
        if (parts.length == 2) {
          try {
            int pieceId = Integer.parseInt(parts[1]);
            executeChoose(pieceId);
          } catch (Exception e) {}
        }
      } else if (data.equals("REMATCH")) {
        startPlay(QRT_ONLINE);
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
        state = QRT_MENU;
        break;
    }
  }

  void onServerEvent(Server s, Client c) {
    network.onServerEvent(s, c);
    playerRole = 1;
    startPlay(QRT_ONLINE);
  }

  void onDisconnectEvent(Client c) {
    network.onDisconnectEvent(c);
    state = QRT_MENU;
    particles.clear();
  }

  // Particles

  void spawnWinParticles(int w) {
    color c = (w == 1) ? QRT_COLOR_P1 : QRT_COLOR_P2;
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
