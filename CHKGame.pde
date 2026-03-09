final int CHK_MENU = 0;
final int CHK_PLAYING = 1;
final int CHK_GAMEOVER = 2;
final int CHK_HOWTO = 3;
final int CHK_LOBBY = 4;

final int CHK_TWO_PLAYER = 0;
final int CHK_AI_MODE = 1;
final int CHK_ONLINE = 2;

class CHKGame extends GameBase {
  int state;
  int mode;
  int currentPlayer;
  int winner;
  CHKBoard board;
  CHKRenderer renderer;
  ArrayList<Particle> particles;

  int selectedRow, selectedCol;
  ArrayList<int[]> validDestinations;

  int howToPage;

  boolean inMultiJump;
  int multiJumpRow, multiJumpCol;

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

  CHKGame() {
    particles = new ArrayList<Particle>();
    validDestinations = new ArrayList<int[]>();
    renderer = new CHKRenderer(this);
    network = new GameNetwork();
  }

  String getName() { return "Checkers"; }
  color getColor() { return color(180, 50, 50); }

  void init() {
    state = CHK_MENU;
    particles.clear();
    aiThinking = false;
    disconnectMessage = "";
  }

  void startPlay(int m) {
    mode = m;
    board = new CHKBoard();
    currentPlayer = 1;
    winner = 0;
    state = CHK_PLAYING;
    selectedRow = -1;
    selectedCol = -1;
    validDestinations.clear();
    inMultiJump = false;
    aiThinking = false;
    particles.clear();
  }

  void render() {
    updateParticles(particles);
    switch (state) {
      case CHK_MENU:
        renderer.drawMenu();
        break;
      case CHK_HOWTO:
        renderer.drawHowTo(howToPage);
        break;
      case CHK_LOBBY:
        if (network.connected && !network.isHost) {
          playerRole = 2;
          startPlay(CHK_ONLINE);
          break;
        }
        renderer.drawLobby();
        break;
      case CHK_PLAYING:
        if (mode == CHK_AI_MODE && currentPlayer == 2 && !aiThinking) {
          startAIMove();
        }
        if (aiThinking) updateAI();
        if (mode == CHK_ONLINE) chkReceive();
        renderer.drawGame();
        break;
      case CHK_GAMEOVER:
        if (mode == CHK_ONLINE) chkReceive();
        renderer.drawGame();
        break;
    }
  }

  void selectPiece(int row, int col) {
    selectedRow = row;
    selectedCol = col;
    validDestinations.clear();
    boolean jumpsExist = board.hasJumps(currentPlayer);
    if (jumpsExist) {
      ArrayList<int[]> jumps = board.getJumps(row, col);
      for (int[] j : jumps) {
        validDestinations.add(new int[]{j[0], j[1]});
      }
    } else {
      ArrayList<int[]> simple = board.getSimpleMoves(row, col);
      for (int[] s : simple) {
        validDestinations.add(new int[]{s[0], s[1]});
      }
    }
  }

  void executeMove(int fromR, int fromC, int toR, int toC) {
    boolean wasJump = abs(toR - fromR) == 2;
    board.makeMove(fromR, fromC, toR, toC);

    if (wasJump) {
      spawnCaptureParticles(fromR, fromC, toR, toC);
      board.promoteKings();
      ArrayList<int[]> moreJumps = board.getJumps(toR, toC);
      if (moreJumps.size() > 0) {
        inMultiJump = true;
        multiJumpRow = toR;
        multiJumpCol = toC;
        selectedRow = toR;
        selectedCol = toC;
        validDestinations.clear();
        for (int[] j : moreJumps) {
          validDestinations.add(new int[]{j[0], j[1]});
        }
        return;
      }
    }

    board.promoteKings();
    endTurn();
  }

  void endTurn() {
    inMultiJump = false;
    selectedRow = -1;
    selectedCol = -1;
    validDestinations.clear();

    winner = board.getWinner();
    if (winner != 0) {
      state = CHK_GAMEOVER;
      gameOverTime = millis();
      spawnWinParticles(winner);
      return;
    }
    currentPlayer = (currentPlayer == 1) ? 2 : 1;
  }

  void spawnCaptureParticles(int fromR, int fromC, int toR, int toC) {
    int capR = (fromR + toR) / 2;
    int capC = (fromC + toC) / 2;
    float px = CHK_OFFSET_X + capC * CHK_CELL + CHK_CELL / 2;
    float py = CHK_OFFSET_Y + capR * CHK_CELL + CHK_CELL / 2;
    color c = (currentPlayer == 1) ? CHK_COLOR_P2 : CHK_COLOR_P1;
    for (int i = 0; i < 15; i++) {
      particles.add(new Particle(px + random(-5, 5), py + random(-5, 5), c));
    }
  }

  void spawnWinParticles(int w) {
    color c = (w == 1) ? CHK_COLOR_P1 : CHK_COLOR_P2;
    for (int i = 0; i < 80; i++) {
      Particle p = new Particle(random(CANVAS_W), random(-20, 20), c);
      p.vy = random(1, 4);
      p.vx = random(-2, 2);
      p.sz = random(4, 10);
      p.life = random(80, 150);
      p.maxLife = p.life;
      particles.add(p);
    }
  }

  // Input

  void onMousePressed() {
    switch (state) {
      case CHK_MENU:
        handleMenuClick();
        break;
      case CHK_HOWTO:
        int nav = handleHowToNav(howToPage, 3);
        if (nav == -1) state = CHK_MENU;
        else howToPage = nav;
        break;
      case CHK_LOBBY:
        handleLobbyClick();
        break;
      case CHK_PLAYING:
        handlePlayClick();
        break;
      case CHK_GAMEOVER:
        handleGameOverClick();
        break;
    }
  }

  void onKeyPressed() {
    if (state == CHK_LOBBY && lobbyState == LOBBY_JOINING) {
      if (key == ENTER || key == RETURN) {
        if (roomCode.length() == 8) network.joinGame(roomCode);
        return;
      }
      roomCode = lobbyHandleKey(roomCode);
    }
  }

  void onEscape() {
    switch (state) {
      case CHK_MENU:
        returnToLauncher();
        break;
      case CHK_HOWTO:
        state = CHK_MENU;
        break;
      case CHK_LOBBY:
        network.stop();
        state = CHK_MENU;
        break;
      case CHK_PLAYING:
      case CHK_GAMEOVER:
        if (mode == CHK_ONLINE) network.stop();
        state = CHK_MENU;
        particles.clear();
        break;
    }
  }

  void handleMenuClick() {
    float bw = 200, bh = 50;
    if (mouseX > CANVAS_W/2 - bw/2 && mouseX < CANVAS_W/2 + bw/2) {
      if (mouseY > 310 - bh/2 && mouseY < 310 + bh/2) startPlay(CHK_TWO_PLAYER);
      if (mouseY > 375 - bh/2 && mouseY < 375 + bh/2) startPlay(CHK_AI_MODE);
      if (mouseY > 440 - bh/2 && mouseY < 440 + bh/2) {
        state = CHK_LOBBY;
        lobbyState = LOBBY_CHOOSE;
        roomCode = "";
      }
      if (mouseY > 505 - bh/2 && mouseY < 505 + bh/2) { state = CHK_HOWTO; howToPage = 0; }
      if (mouseY > 570 - bh/2 && mouseY < 570 + bh/2) returnToLauncher();
    }
  }

  void handlePlayClick() {
    if (mode == CHK_AI_MODE && currentPlayer == 2) return;
    if (mode == CHK_ONLINE && currentPlayer != playerRole) return;

    int col = (int)((mouseX - CHK_OFFSET_X) / CHK_CELL);
    int row = (int)((mouseY - CHK_OFFSET_Y) / CHK_CELL);
    if (row < 0 || row > 7 || col < 0 || col > 7) return;

    if (inMultiJump) {
      for (int[] dest : validDestinations) {
        if (dest[0] == row && dest[1] == col) {
          if (mode == CHK_ONLINE) network.send("MOVE:" + multiJumpRow + ":" + multiJumpCol + ":" + row + ":" + col);
          executeMove(multiJumpRow, multiJumpCol, row, col);
          return;
        }
      }
      return;
    }

    // Check if clicking a valid destination
    if (selectedRow != -1) {
      for (int[] dest : validDestinations) {
        if (dest[0] == row && dest[1] == col) {
          if (mode == CHK_ONLINE) network.send("MOVE:" + selectedRow + ":" + selectedCol + ":" + row + ":" + col);
          executeMove(selectedRow, selectedCol, row, col);
          return;
        }
      }
    }

    // Select piece
    if (board.isPlayerPiece(row, col, currentPlayer)) {
      boolean jumpsExist = board.hasJumps(currentPlayer);
      if (jumpsExist && board.getJumps(row, col).size() == 0) return;
      selectPiece(row, col);
    }
  }

  void handleGameOverClick() {
    float elapsed = (millis() - gameOverTime) / 1000.0;
    if (elapsed < 1.0) return;
    float bw = 200, bh = 50;
    float rx = CANVAS_W/2 - 110;
    float ry = 55;
    if (mouseX > rx - bw/2 && mouseX < rx + bw/2 && mouseY > ry - bh/2 && mouseY < ry + bh/2) {
      if (mode == CHK_ONLINE) network.send("REMATCH");
      startPlay(mode);
    }
    float mx = CANVAS_W/2 + 110;
    if (mouseX > mx - bw/2 && mouseX < mx + bw/2 && mouseY > ry - bh/2 && mouseY < ry + bh/2) {
      if (mode == CHK_ONLINE) network.stop();
      state = CHK_MENU;
      particles.clear();
    }
  }

  // AI

  void startAIMove() {
    aiThinking = true;
    aiMoveTime = millis();
    aiMove = chkFindBestMove(board, 2);
  }

  void updateAI() {
    if (!aiThinking) return;
    if (millis() - aiMoveTime < 400) return;
    if (aiMove != null) {
      int fr = aiMove[0], fc = aiMove[1], tr = aiMove[2], tc = aiMove[3];
      board.makeMove(fr, fc, tr, tc);
      boolean wasJump = abs(tr - fr) == 2;
      if (wasJump) {
        spawnCaptureParticles(fr, fc, tr, tc);
        board.promoteKings();
        // AI multi-jump
        ArrayList<int[]> moreJumps = board.getJumps(tr, tc);
        while (moreJumps.size() > 0) {
          CHKBoard sim = board.copy();
          int[] best = chkBestJumpFrom(sim, tr, tc, 2);
          if (best == null) break;
          int nr = best[0], nc = best[1];
          board.makeMove(tr, tc, nr, nc);
          spawnCaptureParticles(tr, tc, nr, nc);
          board.promoteKings();
          tr = nr;
          tc = nc;
          moreJumps = board.getJumps(tr, tc);
        }
      }
      board.promoteKings();
      endTurn();
    }
    aiThinking = false;
  }

  // Network

  void chkReceive() {
    if (!network.isPeerConnected()) {
      network.stop();
      disconnectMessage = "Opponent disconnected";
      disconnectMessageTime = millis();
      state = CHK_MENU;
      particles.clear();
      return;
    }
    String data = network.receiveNext();
    while (data != null) {
      if (data.startsWith("MOVE:")) {
        String[] parts = data.split(":");
        if (parts.length == 5) {
          try {
            int fr = Integer.parseInt(parts[1]);
            int fc = Integer.parseInt(parts[2]);
            int tr = Integer.parseInt(parts[3]);
            int tc = Integer.parseInt(parts[4]);
            executeMove(fr, fc, tr, tc);
          } catch (Exception e) {}
        }
      } else if (data.equals("REMATCH")) {
        startPlay(CHK_ONLINE);
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
        state = CHK_MENU;
        break;
    }
  }

  void onServerEvent(Server s, Client c) {
    network.onServerEvent(s, c);
    playerRole = 1;
    startPlay(CHK_ONLINE);
  }

  void onDisconnectEvent(Client c) {
    network.onDisconnectEvent(c);
    state = CHK_MENU;
    particles.clear();
  }
}
