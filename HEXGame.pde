final int HEX_MENU = 0;
final int HEX_PLAYING = 1;
final int HEX_GAMEOVER = 2;
final int HEX_HOWTO = 3;

final int HEX_TWO_PLAYER = 0;
final int HEX_AI_MODE = 1;

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

  HEXGame() {
    particles = new ArrayList<Particle>();
    renderer = new HEXRenderer(this);
  }

  String getName() { return "Hex"; }
  color getColor() { return color(140, 80, 200); }

  void init() {
    state = HEX_MENU;
    particles.clear();
    aiThinking = false;
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
      case HEX_HOWTO:
        renderer.drawHowTo(howToPage);
        break;
      case HEX_PLAYING:
        if (mode == HEX_AI_MODE && currentPlayer == 2 && !aiThinking) {
          startAIMove();
        }
        if (aiThinking) updateAI();
        renderer.drawGame();
        break;
      case HEX_GAMEOVER:
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

  void onKeyPressed() {}

  void onEscape() {
    switch (state) {
      case HEX_MENU:
        returnToLauncher();
        break;
      case HEX_HOWTO:
        state = HEX_MENU;
        break;
      case HEX_PLAYING:
      case HEX_GAMEOVER:
        state = HEX_MENU;
        particles.clear();
        break;
    }
  }

  void handleMenuClick() {
    float bw = 200, bh = 50;
    if (mouseX > CANVAS_W/2 - bw/2 && mouseX < CANVAS_W/2 + bw/2) {
      if (mouseY > 330 - bh/2 && mouseY < 330 + bh/2) startPlay(HEX_TWO_PLAYER);
      if (mouseY > 400 - bh/2 && mouseY < 400 + bh/2) startPlay(HEX_AI_MODE);
      if (mouseY > 470 - bh/2 && mouseY < 470 + bh/2) { state = HEX_HOWTO; howToPage = 0; }
      if (mouseY > 540 - bh/2 && mouseY < 540 + bh/2) returnToLauncher();
    }
  }

  void handlePlayClick() {
    if (mode == HEX_AI_MODE && currentPlayer == 2) return;

    int[] cell = renderer.pixelToHex(mouseX, mouseY);
    if (cell == null) return;
    if (!board.isOnBoard(cell[0], cell[1])) return;
    if (board.grid[cell[0]][cell[1]] != 0) return;

    executeMove(cell[0], cell[1]);
  }

  void handleGameOverClick() {
    float elapsed = (millis() - gameOverTime) / 1000.0;
    if (elapsed < 1.0) return;

    float bw = 200, bh = 50;
    float rx = CANVAS_W/2 - 110;
    float ry = 45;
    if (mouseX > rx - bw/2 && mouseX < rx + bw/2 && mouseY > ry - bh/2 && mouseY < ry + bh/2) {
      startPlay(mode);
    }
    float mx = CANVAS_W/2 + 110;
    float my = 45;
    if (mouseX > mx - bw/2 && mouseX < mx + bw/2 && mouseY > my - bh/2 && mouseY < my + bh/2) {
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
