final int MNG_MENU = 0;
final int MNG_PLAYING = 1;
final int MNG_GAMEOVER = 2;
final int MNG_HOWTO = 3;
final int MNG_LOBBY = 4;

final int MNG_TWO_PLAYER = 0;
final int MNG_AI_MODE = 1;
final int MNG_ONLINE = 2;

class MNGGame extends GameBase {
  int state;
  int mode;
  MNGBoard board;
  int winner;
  boolean extraTurn;
  String extraTurnMsg;
  int extraTurnTime;


  // How to play
  int howToPage;

  // AI
  int aiMove;
  int aiMoveTime;
  boolean aiThinking;

  // Game over
  int gameOverTime;

  // Particles
  ArrayList<Particle> particles;

  // Renderer
  MNGRenderer renderer;

  // Online
  GameNetwork network;
  int lobbyState;
  int playerRole;
  String roomCode = "";
  String disconnectMessage = "";
  int disconnectMessageTime = 0;

  MNGGame() {
    particles = new ArrayList<Particle>();
    renderer = new MNGRenderer(this);
    network = new GameNetwork();
  }

  String getName() { return "Mangala"; }
  color getColor() { return color(205, 133, 63); }

  void init() {
    state = MNG_MENU;
    particles.clear();
    aiThinking = false;
    extraTurn = false;
    extraTurnMsg = "";
    disconnectMessage = "";
  }

  void startPlay(int m) {
    mode = m;
    board = new MNGBoard();
    board.currentPlayer = 1;
    state = MNG_PLAYING;
    winner = 0;
    extraTurn = false;
    extraTurnMsg = "";
    aiThinking = false;
    particles.clear();
  }

  void render() {
    updateParticles(particles);

    switch (state) {
      case MNG_MENU:
        renderer.drawMenu();
        break;
      case MNG_PLAYING:
        if (mode == MNG_AI_MODE && board.currentPlayer == 2 && !aiThinking) {
          startAIMove();
        }
        if (aiThinking) updateAI();
        if (mode == MNG_ONLINE) mngReceive();
        renderer.drawGame();
        break;
      case MNG_GAMEOVER:
        if (mode == MNG_ONLINE) mngReceive();
        renderer.drawGame();
        break;
      case MNG_LOBBY:
        if (network.connected && !network.isHost) {
          playerRole = 2;
          startPlay(MNG_ONLINE);
          break;
        }
        renderer.drawLobby();
        break;
      case MNG_HOWTO:
        renderer.drawHowTo(howToPage);
        break;
    }
  }

  void executeMove(int pitIndex) {
    boolean extra = board.sow(pitIndex);

    if (board.isGameOver()) {
      winner = board.getWinner();
      state = MNG_GAMEOVER;
      gameOverTime = millis();
      spawnEndParticles();
      return;
    }

    if (extra) {
      extraTurn = true;
      extraTurnMsg = "Extra Turn!";
      extraTurnTime = millis();
    } else {
      extraTurn = false;
      extraTurnMsg = "";
      board.currentPlayer = (board.currentPlayer == 1) ? 2 : 1;
    }
  }

  // Input

  void onMousePressed() {
    switch (state) {
      case MNG_MENU:
        handleMenuClick();
        break;
      case MNG_PLAYING:
        handlePlayClick();
        break;
      case MNG_GAMEOVER:
        handleGameOverClick();
        break;
      case MNG_LOBBY:
        handleLobbyClick();
        break;
      case MNG_HOWTO:
        int nav = handleHowToNav(howToPage, 3);
        if (nav == -1) state = MNG_MENU;
        else howToPage = nav;
        break;
    }
  }

  void onKeyPressed() {
    if (state == MNG_LOBBY && lobbyState == LOBBY_JOINING) {
      if (key == ENTER || key == RETURN) {
        if (roomCode.length() == 8) network.joinGame(roomCode);
        return;
      }
      roomCode = lobbyHandleKey(roomCode);
    }
  }

  void onEscape() {
    switch (state) {
      case MNG_MENU:
        returnToLauncher();
        break;
      case MNG_PLAYING:
      case MNG_GAMEOVER:
        if (mode == MNG_ONLINE) network.stop();
        state = MNG_MENU;
        particles.clear();
        break;
      case MNG_LOBBY:
        network.stop();
        state = MNG_MENU;
        break;
      case MNG_HOWTO:
        state = MNG_MENU;
        break;
    }
  }

  void handleMenuClick() {
    float bw = 200, bh = 50;
    if (mngButtonHit(CANVAS_W / 2, 310, bw, bh)) {
      startPlay(MNG_TWO_PLAYER);
    }
    if (mngButtonHit(CANVAS_W / 2, 375, bw, bh)) {
      startPlay(MNG_AI_MODE);
    }
    if (mngButtonHit(CANVAS_W / 2, 440, bw, bh)) {
      state = MNG_LOBBY;
      lobbyState = LOBBY_CHOOSE;
      network.stop();
    }
    if (mngButtonHit(CANVAS_W / 2, 505, bw, bh)) {
      state = MNG_HOWTO;
      howToPage = 0;
    }
    if (mngButtonHit(CANVAS_W / 2, 570, bw, bh)) {
      returnToLauncher();
    }
  }

  void handlePlayClick() {
    if (mode == MNG_AI_MODE && board.currentPlayer == 2) return;
    if (mode == MNG_ONLINE && board.currentPlayer != playerRole) return;

    int clicked = renderer.getPitAtMouse();
    if (clicked == -1) return;
    if (!board.isValidMove(clicked, board.currentPlayer)) return;

    executeMove(clicked);
    if (mode == MNG_ONLINE) network.send("MOVE:" + clicked);
  }

  void handleGameOverClick() {
    float elapsed = (millis() - gameOverTime) / 1000.0;
    if (elapsed < 1.0) return;

    float bw = 200, bh = 50;
    if (mngButtonHit(CANVAS_W / 2 - 110, 85, bw, bh)) {
      if (mode == MNG_ONLINE) network.send("REMATCH");
      startPlay(mode);
    }
    if (mngButtonHit(CANVAS_W / 2 + 110, 85, bw, bh)) {
      if (mode == MNG_ONLINE) network.stop();
      state = MNG_MENU;
      particles.clear();
    }
  }

  boolean mngButtonHit(float x, float y, float w, float h) {
    return mouseX > x - w / 2 && mouseX < x + w / 2 &&
           mouseY > y - h / 2 && mouseY < y + h / 2;
  }

  // AI

  void startAIMove() {
    aiThinking = true;
    aiMoveTime = millis();
    aiMove = mngFindBestMove(board, 2);
  }

  void updateAI() {
    if (!aiThinking) return;
    if (millis() - aiMoveTime < 400) return;
    if (aiMove >= 0) {
      executeMove(aiMove);
    }
    aiThinking = false;
  }


  // Particles

  // Online

  void mngReceive() {
    if (!network.isPeerConnected()) {
      network.stop();
      disconnectMessage = "Opponent disconnected";
      disconnectMessageTime = millis();
      state = MNG_MENU;
      particles.clear();
      return;
    }
    String data = network.receiveNext();
    while (data != null) {
      if (data.startsWith("MOVE:")) {
        String[] parts = data.split(":");
        if (parts.length == 2) {
          try {
            int pit = Integer.parseInt(parts[1]);
            if (board.isValidMove(pit, board.currentPlayer)) {
              executeMove(pit);
            }
          } catch (Exception e) {}
        }
      } else if (data.equals("REMATCH")) {
        startPlay(MNG_ONLINE);
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
        state = MNG_MENU;
        break;
    }
  }

  void onServerEvent(Server s, Client c) {
    network.onServerEvent(s, c);
    playerRole = 1;
    startPlay(MNG_ONLINE);
  }

  void onDisconnectEvent(Client c) {
    network.onDisconnectEvent(c);
    state = MNG_MENU;
    particles.clear();
  }

  // Particles

  void spawnEndParticles() {
    if (winner == 3) {
      for (int i = 0; i < 30; i++) {
        particles.add(new Particle(random(CANVAS_W), random(200, 500), color(150)));
      }
    } else {
      color c = (winner == 1) ? MNG_COLOR_P1 : MNG_COLOR_P2;
      for (int i = 0; i < 80; i++) {
        Particle p = new Particle(random(CANVAS_W), random(-10, 10), c);
        p.vy = random(1, 4);
        p.vx = random(-2, 2);
        p.sz = random(4, 10);
        p.life = random(80, 150);
        p.maxLife = p.life;
        particles.add(p);
      }
    }
  }
}
