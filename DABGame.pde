final int DAB_MENU = 0;
final int DAB_PLAYING = 1;
final int DAB_GAMEOVER = 2;
final int DAB_HOWTO = 3;
final int DAB_LOBBY = 4;

final int DAB_TWO_PLAYER = 0;
final int DAB_AI_MODE = 1;
final int DAB_ONLINE = 2;

final int DAB_GRID_DOTS = 5;
final int DAB_GRID_BOXES = 4;

final int DAB_SPACING = 110;
final int DAB_OFFSET_X = (CANVAS_W - DAB_SPACING * (DAB_GRID_DOTS - 1)) / 2;
final int DAB_OFFSET_Y = 140;
final int DAB_LINE_THRESHOLD = 15;

class DABGame extends GameBase {
  int state;
  int mode;
  int currentPlayer;
  DABBoard board;
  int winner;
  int howToPage;
  ArrayList<Particle> particles;
  DABRenderer renderer;

  // last placed line for highlight
  int lastLineType = -1;
  int lastLineRow = -1;
  int lastLineCol = -1;
  int lastLineTime = 0;

  // AI
  int[] aiMove;
  int aiMoveTime;
  boolean aiThinking;

  // hover detection
  int hoverType = -1;
  int hoverRow = -1;
  int hoverCol = -1;

  int gameOverTime;

  // Online
  GameNetwork network;
  int lobbyState;
  int playerRole;
  String roomCode = "";
  String disconnectMessage = "";
  int disconnectMessageTime = 0;

  DABGame() {
    particles = new ArrayList<Particle>();
    renderer = new DABRenderer(this);
    network = new GameNetwork();
  }

  String getName() { return "Dots & Boxes"; }
  color getColor() { return color(30, 60, 120); }

  void init() {
    state = DAB_MENU;
    particles.clear();
    aiThinking = false;
    disconnectMessage = "";
  }

  void startPlay(int m) {
    mode = m;
    board = new DABBoard();
    currentPlayer = 1;
    state = DAB_PLAYING;
    winner = 0;
    particles.clear();
    lastLineType = -1;
    aiThinking = false;
  }

  void render() {
    updateParticles(particles);
    updateHover();

    switch (state) {
      case DAB_MENU:
        renderer.drawMenu();
        break;
      case DAB_PLAYING:
        if (mode == DAB_AI_MODE && currentPlayer == 2 && !aiThinking) {
          startAIMove();
        }
        if (aiThinking) updateAI();
        if (mode == DAB_ONLINE) dabReceive();
        renderer.drawGame();
        break;
      case DAB_GAMEOVER:
        if (mode == DAB_ONLINE) dabReceive();
        renderer.drawGame();
        break;
      case DAB_LOBBY:
        if (network.connected && !network.isHost) {
          playerRole = 2;
          startPlay(DAB_ONLINE);
          break;
        }
        renderer.drawLobby();
        break;
      case DAB_HOWTO:
        renderer.drawHowTo(howToPage);
        break;
    }
  }

  void updateHover() {
    if (state != DAB_PLAYING) { hoverType = -1; return; }
    if (mode == DAB_AI_MODE && currentPlayer == 2) { hoverType = -1; return; }
    if (mode == DAB_ONLINE && currentPlayer != playerRole) { hoverType = -1; return; }

    int[] nearest = findNearestLine(mouseX, mouseY);
    if (nearest != null) {
      hoverType = nearest[0];
      hoverRow = nearest[1];
      hoverCol = nearest[2];
    } else {
      hoverType = -1;
    }
  }

  int[] findNearestLine(float mx, float my) {
    float bestDist = DAB_LINE_THRESHOLD;
    int[] best = null;

    // check horizontal lines
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 4; c++) {
        if (board.isLineSet(0, r, c)) continue;
        float x1 = DAB_OFFSET_X + c * DAB_SPACING;
        float y1 = DAB_OFFSET_Y + r * DAB_SPACING;
        float x2 = x1 + DAB_SPACING;
        float cx = (x1 + x2) / 2;
        float cy = y1;
        // distance from point to line segment
        float d = dabPointToSegDist(mx, my, x1, y1, x2, y1);
        if (d < bestDist) {
          bestDist = d;
          best = new int[]{0, r, c};
        }
      }
    }

    // check vertical lines
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 5; c++) {
        if (board.isLineSet(1, r, c)) continue;
        float x1 = DAB_OFFSET_X + c * DAB_SPACING;
        float y1 = DAB_OFFSET_Y + r * DAB_SPACING;
        float y2 = y1 + DAB_SPACING;
        float d = dabPointToSegDist(mx, my, x1, y1, x1, y2);
        if (d < bestDist) {
          bestDist = d;
          best = new int[]{1, r, c};
        }
      }
    }

    return best;
  }

  void executeMove(int type, int row, int col) {
    int completed = board.placeLine(type, row, col, currentPlayer);

    lastLineType = type;
    lastLineRow = row;
    lastLineCol = col;
    lastLineTime = millis();

    if (completed > 0) {
      spawnBoxParticles(type, row, col, currentPlayer);
    }

    if (board.isGameOver()) {
      winner = board.getWinner();
      state = DAB_GAMEOVER;
      gameOverTime = millis();
      spawnGameOverParticles();
      return;
    }

    // extra turn if completed a box
    if (completed == 0) {
      currentPlayer = (currentPlayer == 1) ? 2 : 1;
    }
  }

  void spawnBoxParticles(int type, int row, int col, int player) {
    color c = (player == 1) ? DAB_COLOR_P1 : DAB_COLOR_P2;

    // find which boxes were just completed — check adjacent boxes
    if (type == 0) {
      if (row < 4 && board.boxes[row][col] == player) {
        float bx = DAB_OFFSET_X + col * DAB_SPACING + DAB_SPACING / 2;
        float by = DAB_OFFSET_Y + row * DAB_SPACING + DAB_SPACING / 2;
        for (int i = 0; i < 12; i++) particles.add(new Particle(bx + random(-20, 20), by + random(-20, 20), c));
      }
      if (row > 0 && board.boxes[row - 1][col] == player) {
        float bx = DAB_OFFSET_X + col * DAB_SPACING + DAB_SPACING / 2;
        float by = DAB_OFFSET_Y + (row - 1) * DAB_SPACING + DAB_SPACING / 2;
        for (int i = 0; i < 12; i++) particles.add(new Particle(bx + random(-20, 20), by + random(-20, 20), c));
      }
    } else {
      if (col < 4 && board.boxes[row][col] == player) {
        float bx = DAB_OFFSET_X + col * DAB_SPACING + DAB_SPACING / 2;
        float by = DAB_OFFSET_Y + row * DAB_SPACING + DAB_SPACING / 2;
        for (int i = 0; i < 12; i++) particles.add(new Particle(bx + random(-20, 20), by + random(-20, 20), c));
      }
      if (col > 0 && board.boxes[row][col - 1] == player) {
        float bx = DAB_OFFSET_X + (col - 1) * DAB_SPACING + DAB_SPACING / 2;
        float by = DAB_OFFSET_Y + row * DAB_SPACING + DAB_SPACING / 2;
        for (int i = 0; i < 12; i++) particles.add(new Particle(bx + random(-20, 20), by + random(-20, 20), c));
      }
    }
  }

  void spawnGameOverParticles() {
    color c;
    if (winner == 1) c = DAB_COLOR_P1;
    else if (winner == 2) c = DAB_COLOR_P2;
    else c = color(150);
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
      case DAB_MENU:
        handleMenuClick();
        break;
      case DAB_PLAYING:
        handlePlayClick();
        break;
      case DAB_GAMEOVER:
        handleGameOverClick();
        break;
      case DAB_LOBBY:
        handleLobbyClick();
        break;
      case DAB_HOWTO:
        int nav = handleHowToNav(howToPage, 2);
        if (nav == -1) state = DAB_MENU;
        else howToPage = nav;
        break;
    }
  }

  void onKeyPressed() {
    if (state == DAB_LOBBY && lobbyState == LOBBY_JOINING) {
      if (key == ENTER || key == RETURN) {
        if (roomCode.length() == 8) network.joinGame(roomCode);
        return;
      }
      roomCode = lobbyHandleKey(roomCode);
    }
  }

  void onEscape() {
    switch (state) {
      case DAB_MENU:
        returnToLauncher();
        break;
      case DAB_PLAYING:
      case DAB_GAMEOVER:
        if (mode == DAB_ONLINE) network.stop();
        state = DAB_MENU;
        particles.clear();
        break;
      case DAB_LOBBY:
        network.stop();
        state = DAB_MENU;
        break;
      case DAB_HOWTO:
        state = DAB_MENU;
        break;
    }
  }

  void handleMenuClick() {
    float bw = 200, bh = 50;
    if (dabButtonHit(CANVAS_W / 2, 310, bw, bh)) {
      startPlay(DAB_TWO_PLAYER);
    }
    if (dabButtonHit(CANVAS_W / 2, 375, bw, bh)) {
      startPlay(DAB_AI_MODE);
    }
    if (dabButtonHit(CANVAS_W / 2, 440, bw, bh)) {
      state = DAB_LOBBY;
      lobbyState = LOBBY_CHOOSE;
      network.stop();
    }
    if (dabButtonHit(CANVAS_W / 2, 505, bw, bh)) {
      state = DAB_HOWTO;
      howToPage = 0;
    }
    if (dabButtonHit(CANVAS_W / 2, 570, bw, bh)) {
      returnToLauncher();
    }
  }

  void handlePlayClick() {
    if (mode == DAB_AI_MODE && currentPlayer == 2) return;
    if (mode == DAB_ONLINE && currentPlayer != playerRole) return;

    int[] nearest = findNearestLine(mouseX, mouseY);
    if (nearest != null) {
      executeMove(nearest[0], nearest[1], nearest[2]);
      if (mode == DAB_ONLINE) network.send("MOVE:" + nearest[0] + ":" + nearest[1] + ":" + nearest[2]);
    }
  }

  void handleGameOverClick() {
    float elapsed = (millis() - gameOverTime) / 1000.0;
    if (elapsed < 1.0) return;

    float bw = 200, bh = 50;
    if (dabButtonHit(CANVAS_W / 2 - 110, 80, bw, bh)) {
      if (mode == DAB_ONLINE) network.send("REMATCH");
      startPlay(mode);
    }
    if (dabButtonHit(CANVAS_W / 2 + 110, 80, bw, bh)) {
      if (mode == DAB_ONLINE) network.stop();
      state = DAB_MENU;
      particles.clear();
    }
  }

  // AI

  void startAIMove() {
    aiThinking = true;
    aiMoveTime = millis();
    aiMove = dabFindBestMove(board, 2);
  }

  void updateAI() {
    if (!aiThinking) return;
    if (millis() - aiMoveTime < 400) return;
    if (aiMove != null) {
      executeMove(aiMove[0], aiMove[1], aiMove[2]);
    }
    aiThinking = false;
  }

  // Online

  void dabReceive() {
    if (!network.isPeerConnected()) {
      network.stop();
      disconnectMessage = "Opponent disconnected";
      disconnectMessageTime = millis();
      state = DAB_MENU;
      particles.clear();
      return;
    }
    String data = network.receiveNext();
    while (data != null) {
      if (data.startsWith("MOVE:")) {
        String[] parts = data.split(":");
        if (parts.length == 4) {
          try {
            int type = Integer.parseInt(parts[1]);
            int row = Integer.parseInt(parts[2]);
            int col = Integer.parseInt(parts[3]);
            if (!board.isLineSet(type, row, col)) {
              executeMove(type, row, col);
            }
          } catch (Exception e) {}
        }
      } else if (data.equals("REMATCH")) {
        startPlay(DAB_ONLINE);
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
        state = DAB_MENU;
        break;
    }
  }

  void onServerEvent(Server s, Client c) {
    network.onServerEvent(s, c);
    playerRole = 1;
    startPlay(DAB_ONLINE);
  }

  void onDisconnectEvent(Client c) {
    network.onDisconnectEvent(c);
    state = DAB_MENU;
    particles.clear();
  }
  boolean dabButtonHit(float x, float y, float w, float h) {
    return mouseX > x - w / 2 && mouseX < x + w / 2 &&
           mouseY > y - h / 2 && mouseY < y + h / 2;
  }

  float dabPointToSegDist(float px, float py, float x1, float y1, float x2, float y2) {
    float dx = x2 - x1;
    float dy = y2 - y1;
    float lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return dist(px, py, x1, y1);
    float t = constrain(((px - x1) * dx + (py - y1) * dy) / lenSq, 0, 1);
    float projX = x1 + t * dx;
    float projY = y1 + t * dy;
    return dist(px, py, projX, projY);
  }
}
