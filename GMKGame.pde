final int GMK_MENU = 0;
final int GMK_PLAYING = 1;
final int GMK_GAMEOVER = 2;
final int GMK_HOWTO = 3;
final int GMK_LOBBY = 4;

final int GMK_TWO_PLAYER = 0;
final int GMK_AI_MODE = 1;
final int GMK_ONLINE = 2;

final int GMK_BOARD_SIZE = 15;

class GMKGame extends GameBase {
  int state;
  int mode;
  int currentPlayer;
  int winner;
  GMKBoard board;
  GMKRenderer renderer;
  ArrayList<Particle> particles;

  int lastRow, lastCol;
  int[] winLine;

  int howToPage;

  int[] aiMove;
  int aiMoveTime;
  boolean aiThinking;

  // Online
  GameNetwork network;
  int lobbyState;
  int playerRole;
  String roomCode = "";
  String disconnectMessage = "";
  int disconnectMessageTime = 0;

  GMKGame() {
    particles = new ArrayList<Particle>();
    renderer = new GMKRenderer(this);
    network = new GameNetwork();
  }

  String getName() { return "Gomoku"; }
  color getColor() { return color(210, 180, 140); }

  void init() {
    state = GMK_MENU;
    particles.clear();
    aiThinking = false;
    disconnectMessage = "";
  }

  void startPlay(int gameMode) {
    mode = gameMode;
    board = new GMKBoard();
    currentPlayer = 1;
    winner = 0;
    lastRow = -1;
    lastCol = -1;
    winLine = null;
    aiThinking = false;
    aiMove = null;
    state = GMK_PLAYING;
    particles.clear();
  }

  void render() {
    updateParticles(particles);

    if (state == GMK_LOBBY) {
      if (network.connected && !network.isHost) {
        playerRole = 2;
        startPlay(GMK_ONLINE);
      }
    }

    if (state == GMK_PLAYING) {
      if (aiThinking && aiMove != null && millis() - aiMoveTime > 500) {
        executeAIMove();
      }
      if (mode == GMK_ONLINE) gmkReceive();
    }
    if (state == GMK_GAMEOVER && mode == GMK_ONLINE) gmkReceive();

    renderer.render();
    drawParticles(particles);
  }

  void onMousePressed() {
    if (state == GMK_MENU) {
      handleMenuClick();
    } else if (state == GMK_LOBBY) {
      handleLobbyClick();
    } else if (state == GMK_PLAYING) {
      handlePlayClick();
    } else if (state == GMK_GAMEOVER) {
      handleGameOverClick();
    } else if (state == GMK_HOWTO) {
      int nav = handleHowToNav(howToPage, 2);
      if (nav == -1) state = GMK_MENU;
      else howToPage = nav;
    }
  }

  void onKeyPressed() {
    if (state == GMK_LOBBY && lobbyState == LOBBY_JOINING) {
      if (key == ENTER || key == RETURN) {
        if (roomCode.length() == 8) network.joinGame(roomCode);
        return;
      }
      roomCode = lobbyHandleKey(roomCode);
    }
  }

  void onEscape() {
    if (state == GMK_MENU) {
      returnToLauncher();
    } else if (state == GMK_HOWTO) {
      state = GMK_MENU;
    } else if (state == GMK_LOBBY) {
      network.stop();
      state = GMK_MENU;
    } else if (state == GMK_PLAYING || state == GMK_GAMEOVER) {
      if (mode == GMK_ONLINE) network.stop();
      state = GMK_MENU;
      particles.clear();
    }
  }

  void handleMenuClick() {
    float cx = CANVAS_W / 2;
    float btnW = 200, btnH = 50;

    if (lobbyButtonHit(cx, 310, btnW, btnH)) {
      startPlay(GMK_TWO_PLAYER);
    } else if (lobbyButtonHit(cx, 375, btnW, btnH)) {
      startPlay(GMK_AI_MODE);
    } else if (lobbyButtonHit(cx, 440, btnW, btnH)) {
      state = GMK_LOBBY;
      lobbyState = LOBBY_CHOOSE;
      roomCode = "";
    } else if (lobbyButtonHit(cx, 505, btnW, btnH)) {
      state = GMK_HOWTO;
      howToPage = 0;
    } else if (lobbyButtonHit(cx, 570, btnW, btnH)) {
      returnToLauncher();
    }
  }

  void handlePlayClick() {
    if (aiThinking) return;
    if (mode == GMK_ONLINE && currentPlayer != playerRole) return;

    int[] pos = renderer.getGridPos(mouseX, mouseY);
    if (pos == null) return;

    int row = pos[0];
    int col = pos[1];

    if (!board.placeStone(row, col, currentPlayer)) return;
    lastRow = row;
    lastCol = col;

    if (mode == GMK_ONLINE) network.send("MOVE:" + row + ":" + col);

    int w = board.checkWin(row, col);
    if (w != 0) {
      winner = w;
      winLine = board.getWinLine(row, col);
      state = GMK_GAMEOVER;
      spawnWinParticles();
      return;
    }
    if (board.isFull()) {
      winner = 0;
      state = GMK_GAMEOVER;
      return;
    }

    currentPlayer = (currentPlayer == 1) ? 2 : 1;

    if (mode == GMK_AI_MODE && currentPlayer == 2) {
      triggerAI();
    }
  }

  void triggerAI() {
    aiThinking = true;
    aiMoveTime = millis();
    aiMove = gmkFindBestMove(board, 2);
  }

  void executeAIMove() {
    aiThinking = false;
    if (aiMove == null) return;

    int row = aiMove[0];
    int col = aiMove[1];
    if (!board.placeStone(row, col, 2)) return;
    lastRow = row;
    lastCol = col;

    int w = board.checkWin(row, col);
    if (w != 0) {
      winner = w;
      winLine = board.getWinLine(row, col);
      state = GMK_GAMEOVER;
      spawnWinParticles();
      return;
    }
    if (board.isFull()) {
      winner = 0;
      state = GMK_GAMEOVER;
      return;
    }

    currentPlayer = 1;
    aiMove = null;
  }

  void spawnWinParticles() {
    color pColor = (winner == 1) ? color(50, 50, 50) : color(255, 255, 255);
    for (int i = 0; i < 40; i++) {
      particles.add(new Particle(CANVAS_W / 2 + random(-100, 100), 350 + random(-50, 50), pColor));
    }
  }

  void handleGameOverClick() {
    float cx = CANVAS_W / 2;
    float btnW = 200, btnH = 50;
    if (gmkButtonHit(cx - 110, 420, btnW, btnH)) {
      if (mode == GMK_ONLINE) network.send("REMATCH");
      startPlay(mode);
    } else if (gmkButtonHit(cx + 110, 420, btnW, btnH)) {
      if (mode == GMK_ONLINE) network.stop();
      state = GMK_MENU;
      particles.clear();
    }
  }

  // Network

  void gmkReceive() {
    if (!network.isPeerConnected()) {
      network.stop();
      disconnectMessage = "Opponent disconnected";
      disconnectMessageTime = millis();
      state = GMK_MENU;
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
            if (board.grid[r][c] == 0) {
              board.placeStone(r, c, currentPlayer);
              lastRow = r;
              lastCol = c;
              int w = board.checkWin(r, c);
              if (w != 0) {
                winner = w;
                winLine = board.getWinLine(r, c);
                state = GMK_GAMEOVER;
                spawnWinParticles();
              } else if (board.isFull()) {
                winner = 0;
                state = GMK_GAMEOVER;
              } else {
                currentPlayer = (currentPlayer == 1) ? 2 : 1;
              }
            }
          } catch (Exception e) {}
        }
      } else if (data.equals("REMATCH")) {
        startPlay(GMK_ONLINE);
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
        state = GMK_MENU;
        break;
    }
  }

  void onServerEvent(Server s, Client c) {
    network.onServerEvent(s, c);
    playerRole = 1;
    startPlay(GMK_ONLINE);
  }

  void onDisconnectEvent(Client c) {
    network.onDisconnectEvent(c);
    state = GMK_MENU;
    particles.clear();
  }
  boolean gmkButtonHit(float cx, float cy, float w, float h) {
    return mouseX > cx - w / 2 && mouseX < cx + w / 2 &&
           mouseY > cy - h / 2 && mouseY < cy + h / 2;
  }
}
