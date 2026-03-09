final color GMK_COLOR_BG = color(210, 180, 140);
final color GMK_COLOR_GRID = color(60, 40, 20);
final color GMK_COLOR_BLACK = color(20, 20, 20);
final color GMK_COLOR_WHITE = color(245, 245, 245);
final color GMK_COLOR_LAST = color(220, 50, 50);
final color GMK_COLOR_WIN = color(241, 196, 15);

final int GMK_CELL_SIZE = 37;
final int GMK_OFFSET_X = (CANVAS_W - GMK_CELL_SIZE * 14) / 2;
final int GMK_OFFSET_Y = 105;

class GMKRenderer {
  GMKGame game;

  GMKRenderer(GMKGame game) {
    this.game = game;
  }

  void render() {
    if (game.state == GMK_MENU) {
      drawMenu();
    } else if (game.state == GMK_LOBBY) {
      drawLobby();
    } else if (game.state == GMK_PLAYING) {
      drawPlaying();
    } else if (game.state == GMK_GAMEOVER) {
      drawGameOver();
    } else if (game.state == GMK_HOWTO) {
      drawHowTo(game.howToPage);
    }
  }

  // --- Menu ---

  void drawMenu() {
    background(GMK_COLOR_BG);

    // Decorative grid lines in background
    stroke(0, 0, 0, 20);
    strokeWeight(1);
    for (int i = 0; i < 15; i++) {
      float x = 50 + i * 35;
      line(x, 50, x, 650);
      float y = 50 + i * 35;
      line(50, y, 540, y);
    }

    textAlign(CENTER, CENTER);
    noStroke();

    textSize(52);
    fill(60, 40, 20);
    text("GOMOKU", CANVAS_W / 2, 180);

    textSize(18);
    fill(100, 70, 40);
    text("Five in a Row", CANVAS_W / 2, 230);

    float cx = CANVAS_W / 2;
    gmkDrawButton(cx, 310, 200, 50, "2 Players");
    gmkDrawButton(cx, 375, 200, 50, "vs AI");
    gmkDrawButton(cx, 440, 200, 50, "Online");
    gmkDrawButton(cx, 505, 200, 50, "How to Play");
    gmkDrawButton(cx, 570, 200, 50, "Back");
  }

  // --- Playing ---

  void drawPlaying() {
    background(GMK_COLOR_BG);
    drawBoard();
    drawStones();
    drawHover();
    drawStatus();
  }

  void drawBoard() {
    stroke(GMK_COLOR_GRID);
    strokeWeight(1);
    for (int i = 0; i < GMK_BOARD_SIZE; i++) {
      float x = GMK_OFFSET_X + i * GMK_CELL_SIZE;
      float y = GMK_OFFSET_Y + i * GMK_CELL_SIZE;
      line(GMK_OFFSET_X, y, GMK_OFFSET_X + 14 * GMK_CELL_SIZE, y);
      line(x, GMK_OFFSET_Y, x, GMK_OFFSET_Y + 14 * GMK_CELL_SIZE);
    }

    // Star points
    fill(GMK_COLOR_GRID);
    noStroke();
    int[] starPts = {3, 7, 11};
    for (int sr : starPts) {
      for (int sc : starPts) {
        float x = GMK_OFFSET_X + sc * GMK_CELL_SIZE;
        float y = GMK_OFFSET_Y + sr * GMK_CELL_SIZE;
        ellipse(x, y, 6, 6);
      }
    }

    // Coordinate labels
    textSize(10);
    fill(100, 70, 40);
    textAlign(CENTER, CENTER);
    for (int i = 0; i < GMK_BOARD_SIZE; i++) {
      float x = GMK_OFFSET_X + i * GMK_CELL_SIZE;
      text(char('A' + i), x, GMK_OFFSET_Y - 14);
      float y = GMK_OFFSET_Y + i * GMK_CELL_SIZE;
      text(str(i + 1), GMK_OFFSET_X - 18, y);
    }
  }

  void drawStones() {
    for (int r = 0; r < GMK_BOARD_SIZE; r++) {
      for (int c = 0; c < GMK_BOARD_SIZE; c++) {
        int cell = game.board.grid[r][c];
        if (cell == 0) continue;
        float x = GMK_OFFSET_X + c * GMK_CELL_SIZE;
        float y = GMK_OFFSET_Y + r * GMK_CELL_SIZE;
        drawStone(x, y, cell);

        if (r == game.lastRow && c == game.lastCol) {
          fill(GMK_COLOR_LAST);
          noStroke();
          ellipse(x, y, 6, 6);
        }
      }
    }
  }

  void drawStone(float x, float y, int player) {
    float radius = GMK_CELL_SIZE * 0.42;
    if (player == 1) {
      // Black stone
      noStroke();
      fill(GMK_COLOR_BLACK);
      ellipse(x, y, radius * 2, radius * 2);
      // Subtle highlight
      fill(80, 80, 80, 60);
      ellipse(x - radius * 0.25, y - radius * 0.25, radius * 0.6, radius * 0.6);
    } else {
      // White stone
      stroke(160);
      strokeWeight(1);
      fill(GMK_COLOR_WHITE);
      ellipse(x, y, radius * 2, radius * 2);
      // Subtle highlight
      noStroke();
      fill(255, 255, 255, 100);
      ellipse(x - radius * 0.25, y - radius * 0.25, radius * 0.6, radius * 0.6);
    }
  }

  void drawHover() {
    if (game.state != GMK_PLAYING) return;
    if (game.aiThinking && game.mode == GMK_AI_MODE) return;

    int[] pos = getGridPos(mouseX, mouseY);
    if (pos == null) return;
    if (game.board.grid[pos[0]][pos[1]] != 0) return;

    float x = GMK_OFFSET_X + pos[1] * GMK_CELL_SIZE;
    float y = GMK_OFFSET_Y + pos[0] * GMK_CELL_SIZE;
    float radius = GMK_CELL_SIZE * 0.42;
    noStroke();
    if (game.currentPlayer == 1) {
      fill(20, 20, 20, 80);
    } else {
      fill(245, 245, 245, 80);
    }
    ellipse(x, y, radius * 2, radius * 2);
  }

  void drawStatus() {
    textAlign(CENTER, CENTER);
    noStroke();

    fill(60, 40, 20);
    textSize(20);
    String status;
    if (game.aiThinking) {
      status = "AI is thinking...";
    } else {
      String playerName = (game.currentPlayer == 1) ? "Black" : "White";
      status = playerName + "'s turn";
    }
    text(status, CANVAS_W / 2, 50);

    textSize(13);
    fill(120, 90, 50);
    text("Move " + game.board.moveCount, CANVAS_W / 2, 75);
  }

  // --- Game Over ---

  void drawGameOver() {
    background(GMK_COLOR_BG);
    drawBoard();
    drawStones();

    // Draw winning line
    if (game.winLine != null) {
      float x1 = GMK_OFFSET_X + game.winLine[1] * GMK_CELL_SIZE;
      float y1 = GMK_OFFSET_Y + game.winLine[0] * GMK_CELL_SIZE;
      float x2 = GMK_OFFSET_X + game.winLine[3] * GMK_CELL_SIZE;
      float y2 = GMK_OFFSET_Y + game.winLine[2] * GMK_CELL_SIZE;

      stroke(GMK_COLOR_WIN);
      strokeWeight(4);
      line(x1, y1, x2, y2);
    }

    // Overlay
    fill(0, 0, 0, 120);
    noStroke();
    rect(0, 300, CANVAS_W, 230);

    textAlign(CENTER, CENTER);
    textSize(36);
    fill(255);
    if (game.winner != 0) {
      String winnerName = (game.winner == 1) ? "Black" : "White";
      text(winnerName + " Wins!", CANVAS_W / 2, 340);
    } else {
      text("Draw!", CANVAS_W / 2, 340);
    }

    gmkDrawButton(CANVAS_W / 2, 400, 200, 50, "Play Again");
    gmkDrawButton(CANVAS_W / 2, 470, 200, 50, "Menu");
  }

  // --- How To ---

  void drawHowTo(int page) {
    drawHowToFrame("Gomoku - How to Play", page, 2, color(210, 180, 140));

    if (page == 0) {
      drawHowToSubtitle("The Board", 90);

      // Mini 9x9 grid
      float gx = CANVAS_W / 2 - 80;
      float gy = 140;
      float cs = 20;
      stroke(180, 150, 110);
      strokeWeight(1);
      for (int i = 0; i < 9; i++) {
        line(gx, gy + i * cs, gx + 8 * cs, gy + i * cs);
        line(gx + i * cs, gy, gx + i * cs, gy + 8 * cs);
      }

      // A few black stones
      noStroke();
      fill(20);
      ellipse(gx + 3 * cs, gy + 3 * cs, 14, 14);
      ellipse(gx + 4 * cs, gy + 4 * cs, 14, 14);
      ellipse(gx + 5 * cs, gy + 2 * cs, 14, 14);

      // A few white stones
      fill(240);
      stroke(160);
      strokeWeight(1);
      ellipse(gx + 4 * cs, gy + 3 * cs, 14, 14);
      ellipse(gx + 3 * cs, gy + 4 * cs, 14, 14);
      ellipse(gx + 5 * cs, gy + 5 * cs, 14, 14);

      drawHowToText("15x15 board. Black goes first.", gy + 9 * cs + 30);
      drawHowToText("Place stones on intersections.", gy + 9 * cs + 55);

    } else if (page == 1) {
      drawHowToSubtitle("Winning", 90);

      // Mini grid
      float gx = CANVAS_W / 2 - 80;
      float gy = 140;
      float cs = 20;
      stroke(180, 150, 110);
      strokeWeight(1);
      for (int i = 0; i < 9; i++) {
        line(gx, gy + i * cs, gx + 8 * cs, gy + i * cs);
        line(gx + i * cs, gy, gx + i * cs, gy + 8 * cs);
      }

      // 5 black stones in a row (horizontal)
      noStroke();
      fill(20);
      for (int i = 0; i < 5; i++) {
        ellipse(gx + (2 + i) * cs, gy + 4 * cs, 14, 14);
      }

      // Gold highlight line
      stroke(241, 196, 15);
      strokeWeight(3);
      line(gx + 2 * cs, gy + 4 * cs, gx + 6 * cs, gy + 4 * cs);

      float ty = gy + 9 * cs + 30;
      drawHowToText("Get 5 stones in a row to win!", ty);
      drawHowToText("Horizontal, vertical, or diagonal.", ty + 28);
      drawHowToText("Board full = draw (very rare).", ty + 56);
    }
  }

  // --- Lobby ---

  void drawLobby() {
    background(GMK_COLOR_BG);
    drawLobbyUI(game.lobbyState, game.network, game.roomCode, color(80, 55, 30));
  }

  // --- Helpers ---

  int[] getGridPos(float mx, float my) {
    float halfCell = GMK_CELL_SIZE / 2.0;
    int col = round((mx - GMK_OFFSET_X) / (float) GMK_CELL_SIZE);
    int row = round((my - GMK_OFFSET_Y) / (float) GMK_CELL_SIZE);
    if (row < 0 || row >= GMK_BOARD_SIZE || col < 0 || col >= GMK_BOARD_SIZE) return null;

    float snapX = GMK_OFFSET_X + col * GMK_CELL_SIZE;
    float snapY = GMK_OFFSET_Y + row * GMK_CELL_SIZE;
    if (abs(mx - snapX) > halfCell || abs(my - snapY) > halfCell) return null;

    return new int[] {row, col};
  }
}

void gmkDrawButton(float cx, float cy, float w, float h, String label) {
  boolean hover = mouseX > cx - w / 2 && mouseX < cx + w / 2 &&
                  mouseY > cy - h / 2 && mouseY < cy + h / 2;
  noStroke();
  if (hover) {
    fill(100, 70, 40, 200);
  } else {
    fill(80, 55, 30, 160);
  }
  rect(cx - w / 2, cy - h / 2, w, h, 8);

  textAlign(CENTER, CENTER);
  textSize(20);
  fill(255);
  text(label, cx, cy);
}
