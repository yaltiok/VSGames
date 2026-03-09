final int GMK_MENU = 0;
final int GMK_PLAYING = 1;
final int GMK_GAMEOVER = 2;
final int GMK_HOWTO = 3;

final int GMK_TWO_PLAYER = 0;
final int GMK_AI_MODE = 1;

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

  GMKGame() {
    particles = new ArrayList<Particle>();
    renderer = new GMKRenderer(this);
  }

  String getName() { return "Gomoku"; }
  color getColor() { return color(210, 180, 140); }

  void init() {
    state = GMK_MENU;
    particles.clear();
    aiThinking = false;
  }

  void startGame(int gameMode) {
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

    if (state == GMK_PLAYING && aiThinking && aiMove != null && millis() - aiMoveTime > 500) {
      executeAIMove();
    }

    renderer.render();
    drawParticles(particles);
  }

  void onMousePressed() {
    if (state == GMK_MENU) {
      handleMenuClick();
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

  void onKeyPressed() {}

  void onEscape() {
    if (state == GMK_MENU) {
      returnToLauncher();
    } else if (state == GMK_HOWTO) {
      state = GMK_MENU;
    } else if (state == GMK_PLAYING || state == GMK_GAMEOVER) {
      state = GMK_MENU;
      particles.clear();
    }
  }

  void handleMenuClick() {
    float cx = CANVAS_W / 2;
    float btnW = 200, btnH = 50;

    if (gmkButtonHit(cx, 300, btnW, btnH)) {
      startGame(GMK_TWO_PLAYER);
    } else if (gmkButtonHit(cx, 370, btnW, btnH)) {
      startGame(GMK_AI_MODE);
    } else if (gmkButtonHit(cx, 440, btnW, btnH)) {
      state = GMK_HOWTO;
      howToPage = 0;
    } else if (gmkButtonHit(cx, 510, btnW, btnH)) {
      returnToLauncher();
    }
  }

  void handlePlayClick() {
    if (aiThinking) return;

    int[] pos = renderer.getGridPos(mouseX, mouseY);
    if (pos == null) return;

    int row = pos[0];
    int col = pos[1];

    if (!board.placeStone(row, col, currentPlayer)) return;
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
    if (gmkButtonHit(cx, 400, btnW, btnH)) {
      startGame(mode);
    } else if (gmkButtonHit(cx, 470, btnW, btnH)) {
      state = GMK_MENU;
      particles.clear();
    }
  }
}

boolean gmkButtonHit(float cx, float cy, float w, float h) {
  return mouseX > cx - w / 2 && mouseX < cx + w / 2 &&
         mouseY > cy - h / 2 && mouseY < cy + h / 2;
}
