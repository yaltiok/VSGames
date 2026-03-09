// SXO Game States
final int SXO_MENU = 0;
final int SXO_PLAYING = 1;
final int SXO_GAMEOVER = 2;
final int SXO_LOBBY = 3;
final int SXO_HOWTO = 4;

// SXO Game Modes
final int SXO_TWO_PLAYER = 0;
final int SXO_AI_MODE = 1;
final int SXO_ONLINE = 2;

// SXO Lobby sub-states
final int SXO_LOBBY_CHOOSE = 0;
final int SXO_LOBBY_HOSTING = 1;
final int SXO_LOBBY_JOINING = 2;

// SXO Layout
final int SXO_TOP_BAR = 100;
final int SXO_GRID_SIZE = 600;
final int SXO_BIG_CELL = 200;
final int SXO_OFFSET_X = (CANVAS_W - SXO_GRID_SIZE) / 2;
final int SXO_ANIM_DURATION = 300;
final int SXO_NET_PORT = 12345;

class SXOGame extends GameBase {
  // State
  int state;
  int mode;
  int currentPlayer;
  SXOBoard board;
  ArrayList<Particle> particles;

  // Online
  int lobbyState;
  int playerRole;
  String roomCode = "";
  String hostRoomCode = "";
  String disconnectMessage = "";
  int disconnectMessageTime = 0;

  // Animation
  int lastMoveGrid = -1;
  int lastMoveCell = -1;
  float animProgress = 1.0;
  int animStartTime;

  // Win line
  float[] winLineStart;
  float[] winLineEnd;
  int gameOverTime;

  // AI
  int[] aiMove;
  int aiMoveTime;
  boolean aiThinking;

  // How to play
  int howToPage;

  // Sub-components
  SXORenderer renderer;
  SXONetwork network;

  SXOGame() {
    particles = new ArrayList<Particle>();
    renderer = new SXORenderer(this);
    network = new SXONetwork(this);
  }

  String getName() { return "Super XOX"; }
  color getColor() { return color(231, 76, 60); }

  void init() {
    state = SXO_MENU;
    particles.clear();
    aiThinking = false;
    disconnectMessage = "";
  }

  void render() {
    if (animProgress < 1.0) {
      animProgress = constrain((millis() - animStartTime) / (float)SXO_ANIM_DURATION, 0, 1);
    }
    updateParticles(particles);

    switch (state) {
      case SXO_MENU:
        renderer.drawMenu();
        break;
      case SXO_LOBBY:
        renderer.drawLobby();
        break;
      case SXO_PLAYING:
        if (mode == SXO_AI_MODE && currentPlayer == 2 && !aiThinking) {
          startAIMove();
        }
        if (aiThinking) updateAI();
        if (mode == SXO_ONLINE) network.receive();
        renderer.drawGame();
        break;
      case SXO_GAMEOVER:
        if (mode == SXO_ONLINE) network.receive();
        renderer.drawGame();
        break;
      case SXO_HOWTO:
        renderer.drawHowTo(howToPage);
        break;
    }
  }

  void startPlay(int m) {
    mode = m;
    board = new SXOBoard();
    currentPlayer = 1;
    state = SXO_PLAYING;
    particles.clear();
    lastMoveGrid = -1;
    lastMoveCell = -1;
    animProgress = 1.0;
    winLineStart = null;
    winLineEnd = null;
    aiThinking = false;
  }

  void executeMove(int gridIdx, int cellIdx) {
    int prevWinner = board.grids[gridIdx].winner;
    board.makeMove(gridIdx, cellIdx, currentPlayer);

    lastMoveGrid = gridIdx;
    lastMoveCell = cellIdx;
    animProgress = 0;
    animStartTime = millis();

    if (prevWinner == 0 && board.grids[gridIdx].winner != 0 && board.grids[gridIdx].winner != 3) {
      spawnGridWinParticles(gridIdx, board.grids[gridIdx].winner);
    }

    if (board.bigWinner != 0) {
      state = SXO_GAMEOVER;
      gameOverTime = millis();
      if (board.bigWinner == 3) {
        spawnDrawParticles();
      } else {
        spawnBigWinParticles(board.bigWinner);
        findWinLine();
      }
      return;
    }

    currentPlayer = (currentPlayer == 1) ? 2 : 1;
  }

  void findWinLine() {
    int[][] lines = {
      {0,1,2}, {3,4,5}, {6,7,8},
      {0,3,6}, {1,4,7}, {2,5,8},
      {0,4,8}, {2,4,6}
    };
    for (int[] l : lines) {
      if (board.bigGrid[l[0]] != 0 && board.bigGrid[l[0]] != 3 &&
          board.bigGrid[l[0]] == board.bigGrid[l[1]] && board.bigGrid[l[1]] == board.bigGrid[l[2]]) {
        winLineStart = new float[]{
          SXO_OFFSET_X + (l[0] % 3) * SXO_BIG_CELL + SXO_BIG_CELL / 2,
          SXO_TOP_BAR + (l[0] / 3) * SXO_BIG_CELL + SXO_BIG_CELL / 2
        };
        winLineEnd = new float[]{
          SXO_OFFSET_X + (l[2] % 3) * SXO_BIG_CELL + SXO_BIG_CELL / 2,
          SXO_TOP_BAR + (l[2] / 3) * SXO_BIG_CELL + SXO_BIG_CELL / 2
        };
        return;
      }
    }
  }

  // Input

  void onMousePressed() {
    switch (state) {
      case SXO_MENU:
        handleMenuClick();
        break;
      case SXO_LOBBY:
        handleLobbyClick();
        break;
      case SXO_PLAYING:
        handlePlayClick();
        break;
      case SXO_GAMEOVER:
        handleGameOverClick();
        break;
      case SXO_HOWTO:
        int nav = handleHowToNav(howToPage, 3);
        if (nav == -1) state = SXO_MENU;
        else howToPage = nav;
        break;
    }
  }

  void onKeyPressed() {
    if (state == SXO_LOBBY && lobbyState == SXO_LOBBY_JOINING) {
      handleLobbyKeyInput();
    }
  }

  void onEscape() {
    switch (state) {
      case SXO_MENU:
        returnToLauncher();
        break;
      case SXO_LOBBY:
        network.stop();
        state = SXO_MENU;
        break;
      case SXO_PLAYING:
      case SXO_GAMEOVER:
        if (mode == SXO_ONLINE) network.stop();
        state = SXO_MENU;
        particles.clear();
        break;
      case SXO_HOWTO:
        state = SXO_MENU;
        break;
    }
  }

  void handleMenuClick() {
    float bw = 200, bh = 50;
    if (mouseX > CANVAS_W/2 - bw/2 && mouseX < CANVAS_W/2 + bw/2 &&
        mouseY > 310 - bh/2 && mouseY < 310 + bh/2) {
      startPlay(SXO_TWO_PLAYER);
    }
    if (mouseX > CANVAS_W/2 - bw/2 && mouseX < CANVAS_W/2 + bw/2 &&
        mouseY > 375 - bh/2 && mouseY < 375 + bh/2) {
      startPlay(SXO_AI_MODE);
    }
    if (mouseX > CANVAS_W/2 - bw/2 && mouseX < CANVAS_W/2 + bw/2 &&
        mouseY > 440 - bh/2 && mouseY < 440 + bh/2) {
      state = SXO_LOBBY;
      lobbyState = SXO_LOBBY_CHOOSE;
      roomCode = "";
    }
    if (mouseX > CANVAS_W/2 - bw/2 && mouseX < CANVAS_W/2 + bw/2 &&
        mouseY > 505 - bh/2 && mouseY < 505 + bh/2) {
      state = SXO_HOWTO;
      howToPage = 0;
    }
    // Back to launcher
    if (mouseX > CANVAS_W/2 - bw/2 && mouseX < CANVAS_W/2 + bw/2 &&
        mouseY > 570 - bh/2 && mouseY < 570 + bh/2) {
      returnToLauncher();
    }
  }

  void handlePlayClick() {
    if (animProgress < 1.0) return;
    if (mode == SXO_AI_MODE && currentPlayer == 2) return;
    if (mode == SXO_ONLINE && currentPlayer != playerRole) return;
    if (mouseY < SXO_TOP_BAR || mouseY > SXO_TOP_BAR + SXO_GRID_SIZE) return;
    if (mouseX < SXO_OFFSET_X || mouseX > SXO_OFFSET_X + SXO_GRID_SIZE) return;

    int bigCol = (mouseX - SXO_OFFSET_X) / SXO_BIG_CELL;
    int bigRow = (mouseY - SXO_TOP_BAR) / SXO_BIG_CELL;
    if (bigCol < 0 || bigCol > 2 || bigRow < 0 || bigRow > 2) return;
    int gridIdx = bigRow * 3 + bigCol;

    int bx = SXO_OFFSET_X + bigCol * SXO_BIG_CELL;
    int by = SXO_TOP_BAR + bigRow * SXO_BIG_CELL;
    float pad = 8;
    float cellW = (SXO_BIG_CELL - pad * 2) / 3.0;
    int smallCol = (int)((mouseX - bx - pad) / cellW);
    int smallRow = (int)((mouseY - by - pad) / cellW);
    if (smallCol < 0 || smallCol > 2 || smallRow < 0 || smallRow > 2) return;
    int cellIdx = smallRow * 3 + smallCol;

    if (!board.isValidMove(gridIdx, cellIdx)) return;

    if (mode == SXO_ONLINE) network.sendMove(gridIdx, cellIdx);
    executeMove(gridIdx, cellIdx);
  }

  void handleGameOverClick() {
    float elapsed = (millis() - gameOverTime) / 1000.0;
    if (elapsed < 1.5) return;

    float bw = 200, bh = 50;
    float rx = CANVAS_W/2 - 110;
    float ry = SXO_TOP_BAR/2 + 25;
    if (mouseX > rx - bw/2 && mouseX < rx + bw/2 && mouseY > ry - bh/2 && mouseY < ry + bh/2) {
      if (mode == SXO_ONLINE) network.sendRematch();
      startPlay(mode);
    }
    float mx = CANVAS_W/2 + 110;
    float my = SXO_TOP_BAR/2 + 25;
    if (mouseX > mx - bw/2 && mouseX < mx + bw/2 && mouseY > my - bh/2 && mouseY < my + bh/2) {
      if (mode == SXO_ONLINE) network.stop();
      state = SXO_MENU;
      particles.clear();
    }
  }

  void handleLobbyClick() {
    float bw = 200, bh = 50;
    switch (lobbyState) {
      case SXO_LOBBY_CHOOSE:
        if (mouseX > CANVAS_W/2 - bw/2 && mouseX < CANVAS_W/2 + bw/2 &&
            mouseY > 320 - bh/2 && mouseY < 320 + bh/2) {
          network.startHosting();
        }
        if (mouseX > CANVAS_W/2 - bw/2 && mouseX < CANVAS_W/2 + bw/2 &&
            mouseY > 400 - bh/2 && mouseY < 400 + bh/2) {
          lobbyState = SXO_LOBBY_JOINING;
          roomCode = "";
        }
        if (mouseX > CANVAS_W/2 - bw/2 && mouseX < CANVAS_W/2 + bw/2 &&
            mouseY > 520 - bh/2 && mouseY < 520 + bh/2) {
          state = SXO_MENU;
        }
        break;
      case SXO_LOBBY_HOSTING:
        if (mouseX > CANVAS_W/2 - bw/2 && mouseX < CANVAS_W/2 + bw/2 &&
            mouseY > 520 - bh/2 && mouseY < 520 + bh/2) {
          network.stop();
          state = SXO_MENU;
        }
        break;
      case SXO_LOBBY_JOINING:
        if (!network.joining && roomCode.length() == 8 &&
            mouseX > CANVAS_W/2 - bw/2 && mouseX < CANVAS_W/2 + bw/2 &&
            mouseY > 430 - bh/2 && mouseY < 430 + bh/2) {
          network.joinGame(roomCode);
        }
        if (mouseX > CANVAS_W/2 - bw/2 && mouseX < CANVAS_W/2 + bw/2 &&
            mouseY > 520 - bh/2 && mouseY < 520 + bh/2) {
          network.stop();
          state = SXO_MENU;
        }
        break;
    }
  }

  void handleLobbyKeyInput() {
    if (key == BACKSPACE && roomCode.length() > 0) {
      roomCode = roomCode.substring(0, roomCode.length() - 1);
    } else if (key == ENTER || key == RETURN) {
      if (roomCode.length() == 8) network.joinGame(roomCode);
    } else if (roomCode.length() < 8) {
      char k = Character.toUpperCase(key);
      if ((k >= '0' && k <= '9') || (k >= 'A' && k <= 'F')) {
        roomCode += k;
      }
    }
  }

  // AI

  void startAIMove() {
    aiThinking = true;
    aiMoveTime = millis();
    aiMove = sxoFindBestMove(board, 2);
  }

  void updateAI() {
    if (!aiThinking) return;
    if (millis() - aiMoveTime < 400) return;
    if (aiMove != null) {
      executeMove(aiMove[0], aiMove[1]);
    }
    aiThinking = false;
  }

  // Particles

  void spawnGridWinParticles(int gridIdx, int winner) {
    float cx = SXO_OFFSET_X + (gridIdx % 3) * SXO_BIG_CELL + SXO_BIG_CELL / 2;
    float cy = SXO_TOP_BAR + (gridIdx / 3) * SXO_BIG_CELL + SXO_BIG_CELL / 2;
    color c = (winner == 1) ? SXO_COLOR_X : SXO_COLOR_O;
    for (int i = 0; i < 25; i++) {
      particles.add(new Particle(cx + random(-20, 20), cy + random(-20, 20), c));
    }
  }

  void spawnBigWinParticles(int winner) {
    color c = (winner == 1) ? SXO_COLOR_X : SXO_COLOR_O;
    for (int i = 0; i < 120; i++) {
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
      particles.add(new Particle(random(CANVAS_W), random(SXO_TOP_BAR, CANVAS_H), color(150)));
    }
  }

  // Network callbacks

  void onServerEvent(Server s, Client c) {
    network.onServerEvent(s, c);
  }

  void onDisconnectEvent(Client c) {
    network.onDisconnectEvent(c);
  }
}
