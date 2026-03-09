final int REV_MENU = 0;
final int REV_PLAYING = 1;
final int REV_GAMEOVER = 2;
final int REV_HOWTO = 3;

final int REV_TWO_PLAYER = 0;
final int REV_AI_MODE = 1;

class REVGame extends GameBase {
  int state;
  int mode;
  int currentPlayer;
  int winner;
  int howToPage;
  REVBoard board;
  REVRenderer renderer;
  ArrayList<Particle> particles;

  int lastMoveRow = -1;
  int lastMoveCol = -1;

  // AI
  int[] aiMove;
  int aiMoveTime;
  boolean aiThinking;

  // flip animation
  ArrayList<int[]> flipCells;
  int flipOldPlayer;
  int flipStartTime;
  final int REV_FLIP_DURATION = 400;
  final int REV_FLIP_STAGGER = 60;
  boolean flipAnimating;

  // pass tracking
  int passMessageTime;
  int passedPlayer;

  // game over
  int gameOverTime;

  REVGame() {
    particles = new ArrayList<Particle>();
    renderer = new REVRenderer(this);
  }

  String getName() { return "Reversi"; }
  color getColor() { return color(0, 160, 70); }

  void init() {
    state = REV_MENU;
    particles.clear();
    aiThinking = false;
    passMessageTime = 0;
  }

  void startPlay(int m) {
    mode = m;
    board = new REVBoard();
    currentPlayer = 1;
    state = REV_PLAYING;
    winner = 0;
    lastMoveRow = -1;
    lastMoveCol = -1;
    aiThinking = false;
    passMessageTime = 0;
    flipCells = new ArrayList<int[]>();
    flipAnimating = false;
    particles.clear();
  }

  void render() {
    updateParticles(particles);

    switch (state) {
      case REV_MENU:
        renderer.drawMenu();
        break;
      case REV_PLAYING:
        updateFlipAnimation();
        if (!flipAnimating) {
          handleAutoPass();
          if (mode == REV_AI_MODE && currentPlayer == 2 && !aiThinking && state == REV_PLAYING) {
            startAIMove();
          }
          if (aiThinking) updateAI();
        }
        renderer.drawGame();
        break;
      case REV_GAMEOVER:
        renderer.drawGame();
        break;
      case REV_HOWTO:
        renderer.drawHowTo(howToPage);
        break;
    }
  }

  void handleAutoPass() {
    if (board.isGameOver()) {
      endGame();
      return;
    }
    if (!board.hasValidMoves(currentPlayer)) {
      passedPlayer = currentPlayer;
      passMessageTime = millis();
      currentPlayer = (currentPlayer == 1) ? 2 : 1;
      if (!board.hasValidMoves(currentPlayer)) {
        endGame();
      }
    }
  }

  void endGame() {
    winner = board.getWinner();
    state = REV_GAMEOVER;
    gameOverTime = millis();
    spawnGameOverParticles();
  }

  void executeMove(int row, int col) {
    flipCells = board.getFlips(row, col, currentPlayer);
    flipOldPlayer = (currentPlayer == 1) ? 2 : 1;
    board.makeMove(row, col, currentPlayer);
    lastMoveRow = row;
    lastMoveCol = col;
    if (flipCells.size() > 0) {
      flipStartTime = millis();
      flipAnimating = true;
      sortFlipCells(row, col);
    }
    currentPlayer = (currentPlayer == 1) ? 2 : 1;
  }

  void sortFlipCells(int originRow, int originCol) {
    // Sort by distance from placed disc for cascade effect
    for (int i = 0; i < flipCells.size() - 1; i++) {
      for (int j = i + 1; j < flipCells.size(); j++) {
        float di = dist(flipCells.get(i)[1], flipCells.get(i)[0], originCol, originRow);
        float dj = dist(flipCells.get(j)[1], flipCells.get(j)[0], originCol, originRow);
        if (dj < di) {
          int[] tmp = flipCells.get(i);
          flipCells.set(i, flipCells.get(j));
          flipCells.set(j, tmp);
        }
      }
    }
  }

  void updateFlipAnimation() {
    if (!flipAnimating) return;
    int totalTime = REV_FLIP_DURATION + (flipCells.size() - 1) * REV_FLIP_STAGGER;
    if (millis() - flipStartTime > totalTime) {
      flipAnimating = false;
    }
  }

  float getFlipProgress(int index) {
    float elapsed = millis() - flipStartTime - index * REV_FLIP_STAGGER;
    return constrain(elapsed / (float)REV_FLIP_DURATION, 0, 1);
  }

  boolean isFlipping(int row, int col) {
    if (!flipAnimating) return false;
    for (int[] f : flipCells) {
      if (f[0] == row && f[1] == col) return true;
    }
    return false;
  }

  int getFlipIndex(int row, int col) {
    for (int i = 0; i < flipCells.size(); i++) {
      if (flipCells.get(i)[0] == row && flipCells.get(i)[1] == col) return i;
    }
    return -1;
  }

  // AI

  void startAIMove() {
    aiThinking = true;
    aiMoveTime = millis();
    aiMove = revFindBestMove(board, 2);
  }

  void updateAI() {
    if (!aiThinking) return;
    if (millis() - aiMoveTime < 400) return;
    if (aiMove != null) {
      executeMove(aiMove[0], aiMove[1]);
    }
    aiThinking = false;
  }

  // Input

  void onMousePressed() {
    switch (state) {
      case REV_MENU:
        handleMenuClick();
        break;
      case REV_PLAYING:
        handlePlayClick();
        break;
      case REV_GAMEOVER:
        handleGameOverClick();
        break;
      case REV_HOWTO:
        int nav = handleHowToNav(howToPage, 3);
        if (nav == -1) state = REV_MENU;
        else howToPage = nav;
        break;
    }
  }

  void onKeyPressed() {}

  void onEscape() {
    switch (state) {
      case REV_MENU:
        returnToLauncher();
        break;
      case REV_PLAYING:
      case REV_GAMEOVER:
        state = REV_MENU;
        particles.clear();
        break;
      case REV_HOWTO:
        state = REV_MENU;
        break;
    }
  }

  void handleMenuClick() {
    float bw = 200, bh = 50;
    if (mouseX > CANVAS_W / 2 - bw / 2 && mouseX < CANVAS_W / 2 + bw / 2) {
      if (mouseY > 330 - bh / 2 && mouseY < 330 + bh / 2) {
        startPlay(REV_TWO_PLAYER);
      }
      if (mouseY > 400 - bh / 2 && mouseY < 400 + bh / 2) {
        startPlay(REV_AI_MODE);
      }
      if (mouseY > 470 - bh / 2 && mouseY < 470 + bh / 2) {
        state = REV_HOWTO;
        howToPage = 0;
      }
      if (mouseY > 540 - bh / 2 && mouseY < 540 + bh / 2) {
        returnToLauncher();
      }
    }
  }

  void handlePlayClick() {
    if (flipAnimating) return;
    if (mode == REV_AI_MODE && currentPlayer == 2) return;

    int[] cell = renderer.getCellUnderMouse();
    if (cell == null) return;

    if (board.getFlips(cell[0], cell[1], currentPlayer).size() == 0) return;
    executeMove(cell[0], cell[1]);
  }

  void handleGameOverClick() {
    float elapsed = (millis() - gameOverTime) / 1000.0;
    if (elapsed < 1.0) return;

    float bw = 200, bh = 50;
    float rx = CANVAS_W / 2 - 110;
    float ry = 105;
    if (mouseX > rx - bw / 2 && mouseX < rx + bw / 2 && mouseY > ry - bh / 2 && mouseY < ry + bh / 2) {
      startPlay(mode);
    }
    float mx = CANVAS_W / 2 + 110;
    float my = 105;
    if (mouseX > mx - bw / 2 && mouseX < mx + bw / 2 && mouseY > my - bh / 2 && mouseY < my + bh / 2) {
      state = REV_MENU;
      particles.clear();
    }
  }

  // Particles

  void spawnGameOverParticles() {
    color c;
    if (winner == 1) c = color(40, 40, 40);
    else if (winner == 2) c = color(220, 220, 220);
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
}
