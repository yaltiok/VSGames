final color QRD_COLOR_BG = color(45, 30, 60);
final color QRD_COLOR_BOARD = color(200, 170, 120);
final color QRD_COLOR_CELL = color(220, 190, 140);
final color QRD_COLOR_P1 = color(70, 130, 230);
final color QRD_COLOR_P2 = color(230, 80, 70);
final color QRD_COLOR_WALL = color(90, 60, 30);
final color QRD_COLOR_WALL_PREVIEW = color(90, 60, 30, 100);
final color QRD_COLOR_HIGHLIGHT = color(255, 255, 100, 100);

class QRDRenderer {
  QRDGame game;
  int cellSize = 65;
  int gap = 6;
  int boardPx = cellSize * 9 + gap * 8; // 585 + 48 = 633... no
  // 9 cells + 8 gaps
  int boardW;
  int offsetX;
  int offsetY = 130;

  QRDRenderer(QRDGame game) {
    this.game = game;
    boardW = cellSize * 9 + gap * 8;
    offsetX = (CANVAS_W - boardW) / 2;
  }

  float cellLeft(int col) {
    return offsetX + col * (cellSize + gap);
  }

  float cellTop(int row) {
    return offsetY + row * (cellSize + gap);
  }

  int[] getCellAtMouse() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        float x = cellLeft(c);
        float y = cellTop(r);
        if (mouseX >= x && mouseX <= x + cellSize && mouseY >= y && mouseY <= y + cellSize) {
          return new int[]{r, c};
        }
      }
    }
    return null;
  }

  int[] getWallAtMouse() {
    // Find nearest intersection point
    float bestDist = 999;
    int bestR = -1, bestC = -1;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        // Intersection (r,c) is at bottom-right corner of cell (r,c)
        float ix = cellLeft(c) + cellSize + gap / 2.0;
        float iy = cellTop(r) + cellSize + gap / 2.0;
        float d = dist(mouseX, mouseY, ix, iy);
        if (d < bestDist && d < cellSize * 0.8) {
          bestDist = d;
          bestR = r;
          bestC = c;
        }
      }
    }
    if (bestR >= 0) return new int[]{bestR, bestC};
    return null;
  }

  // Game drawing

  void drawGame() {
    background(QRD_COLOR_BG);
    drawTopBar();
    drawBoard();
    drawWalls();
    drawPawns();
    drawHighlights();
    drawWallPreview();
    drawParticles(game.particles);
  }

  void drawBoard() {
    // Board background
    noStroke();
    fill(QRD_COLOR_BOARD);
    rect(offsetX - 8, offsetY - 8, boardW + 16, boardW + 16, 12);

    // Draw cells
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        float x = cellLeft(c);
        float y = cellTop(r);
        noStroke();
        fill(QRD_COLOR_CELL);
        rect(x, y, cellSize, cellSize, 4);
      }
    }
  }

  void drawWalls() {
    noStroke();
    fill(QRD_COLOR_WALL);
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (game.board.hWalls[r][c]) {
          // Horizontal wall: spans from cell (r,c) bottom to cell (r,c+1) bottom
          float x = cellLeft(c);
          float y = cellTop(r) + cellSize;
          float w = cellSize * 2 + gap;
          rect(x, y, w, gap, 2);
        }
        if (game.board.vWalls[r][c]) {
          // Vertical wall: spans from cell (r,c) right to cell (r+1,c) right
          float x = cellLeft(c) + cellSize;
          float y = cellTop(r);
          float h = cellSize * 2 + gap;
          rect(x, y, gap, h, 2);
        }
      }
    }
  }

  void drawPawns() {
    for (int p = 0; p < 2; p++) {
      int r = game.board.pawnRow[p];
      int c = game.board.pawnCol[p];
      float cx = cellLeft(c) + cellSize / 2.0;
      float cy = cellTop(r) + cellSize / 2.0;
      float diam = cellSize * 0.7;
      color base = (p == 0) ? QRD_COLOR_P1 : QRD_COLOR_P2;

      noStroke();
      // Shadow
      fill(0, 40);
      ellipse(cx + 2, cy + 2, diam, diam);
      // Main
      fill(base);
      ellipse(cx, cy, diam, diam);
      // Highlight
      color hl = (p == 0) ? color(150, 190, 255, 100) : color(255, 150, 140, 100);
      fill(hl);
      ellipse(cx - diam * 0.12, cy - diam * 0.12, diam * 0.35, diam * 0.35);
    }
  }

  void drawHighlights() {
    if (game.state != QRD_PLAYING) return;
    if (game.wallMode) return;
    if (game.mode == QRD_AI_MODE && game.currentPlayer == 2) return;
    if (game.mode == QRD_ONLINE && game.currentPlayer != game.playerRole) return;

    ArrayList<int[]> moves = game.board.getValidPawnMoves(game.currentPlayer);
    noStroke();
    fill(QRD_COLOR_HIGHLIGHT);
    for (int[] m : moves) {
      float x = cellLeft(m[1]);
      float y = cellTop(m[0]);
      rect(x, y, cellSize, cellSize, 4);
    }
  }

  void drawWallPreview() {
    if (game.state != QRD_PLAYING) return;
    if (!game.wallMode) return;
    if (game.mode == QRD_AI_MODE && game.currentPlayer == 2) return;
    if (game.mode == QRD_ONLINE && game.currentPlayer != game.playerRole) return;

    int[] wpos = getWallAtMouse();
    if (wpos == null) return;
    int wr = wpos[0], wc = wpos[1];

    boolean valid = game.board.canPlaceWall(wr, wc, game.wallOrientation, game.currentPlayer);
    color previewColor = valid ? QRD_COLOR_WALL_PREVIEW : color(200, 50, 50, 80);

    noStroke();
    fill(previewColor);
    if (game.wallOrientation == 0) {
      float x = cellLeft(wc);
      float y = cellTop(wr) + cellSize;
      float w = cellSize * 2 + gap;
      rect(x, y, w, gap, 2);
    } else {
      float x = cellLeft(wc) + cellSize;
      float y = cellTop(wr);
      float h = cellSize * 2 + gap;
      rect(x, y, gap, h, 2);
    }
  }

  void drawTopBar() {
    textAlign(CENTER, CENTER);

    if (game.state == QRD_GAMEOVER) {
      drawGameOverUI();
      return;
    }

    // Current player indicator
    String label;
    color c;
    if (game.currentPlayer == 1) {
      label = "Blue's Turn";
      c = QRD_COLOR_P1;
    } else {
      label = "Red's Turn";
      c = QRD_COLOR_P2;
    }
    if (game.mode == QRD_AI_MODE && game.currentPlayer == 2) {
      label = "AI Thinking...";
    }
    if (game.mode == QRD_ONLINE) {
      if (game.currentPlayer == game.playerRole) {
        label = "Your Turn (" + (game.playerRole == 1 ? "Blue" : "Red") + ")";
      } else {
        label = "Opponent's Turn";
      }
      c = (game.currentPlayer == 1) ? QRD_COLOR_P1 : QRD_COLOR_P2;
    }

    // Player indicator circle
    noStroke();
    fill(c);
    ellipse(CANVAS_W / 2 - 100, 35, 18, 18);

    textSize(22);
    fill(255);
    text(label, CANVAS_W / 2 + 10, 35);

    // Wall counts
    textSize(14);
    fill(QRD_COLOR_P1);
    textAlign(LEFT, CENTER);
    text("P1 Walls: " + game.board.wallsLeft[0], offsetX, 65);
    fill(QRD_COLOR_P2);
    textAlign(RIGHT, CENTER);
    text("P2 Walls: " + game.board.wallsLeft[1], offsetX + boardW, 65);

    // Mode indicator
    textAlign(CENTER, CENTER);
    textSize(13);
    if (game.wallMode) {
      String orient = (game.wallOrientation == 0) ? "H" : "V";
      fill(QRD_COLOR_WALL);
      text("Wall Mode (" + orient + ")  |  W: toggle  R: rotate", CANVAS_W / 2, 90);
    } else {
      fill(180);
      text("Move Mode  |  W: wall mode  R: rotate", CANVAS_W / 2, 90);
    }

    // Bottom info
    textSize(12);
    fill(120);
    textAlign(CENTER, CENTER);
    float bottomY = offsetY + boardW + 20;
    text("Goal: reach the opposite side  |  Walls block paths but must leave a route", CANVAS_W / 2, bottomY);
  }

  void drawGameOverUI() {
    String msg;
    color c;
    if (game.mode == QRD_ONLINE) {
      if (game.winner == game.playerRole) {
        msg = "You Win!";
      } else {
        msg = "You Lose!";
      }
      c = (game.winner == 1) ? QRD_COLOR_P1 : QRD_COLOR_P2;
    } else if (game.winner == 1) {
      msg = "Blue Wins!";
      c = QRD_COLOR_P1;
    } else {
      msg = (game.mode == QRD_AI_MODE) ? "AI Wins!" : "Red Wins!";
      c = QRD_COLOR_P2;
    }

    textSize(28);
    fill(c);
    text(msg, CANVAS_W / 2, 30);

    float elapsed = (millis() - game.gameOverTime) / 1000.0;
    if (elapsed > 1.0) {
      qrdDrawButton(CANVAS_W / 2 - 110, 60, "Restart", color(46, 204, 113));
      qrdDrawButton(CANVAS_W / 2 + 110, 60, "Menu", color(120));
    }
  }

  // Menu

  void drawMenu() {
    background(QRD_COLOR_BG);

    // Floating decorative wall-like rectangles
    for (int i = 0; i < 10; i++) {
      float x = noise(i * 10 + millis() * 0.0003) * CANVAS_W;
      float y = noise(i * 20 + 500 + millis() * 0.0003) * CANVAS_H;
      noStroke();
      fill(QRD_COLOR_WALL, 30);
      if (i % 2 == 0) {
        rect(x, y, 50, 6, 2);
      } else {
        rect(x, y, 6, 50, 2);
      }
    }

    // Title
    float bounce = sin(millis() * 0.003) * 8;
    textAlign(CENTER, CENTER);
    textSize(52);
    fill(255);
    text("QUORIDOR", CANVAS_W / 2, 180 + bounce);

    textSize(18);
    fill(150);
    text("Duvar Stratejisi", CANVAS_W / 2, 230);

    // Disconnect message
    if (game.disconnectMessage.length() > 0) {
      float elapsed = (millis() - game.disconnectMessageTime) / 1000.0;
      if (elapsed < 3.0) {
        float alpha = elapsed < 2.0 ? 255 : map(elapsed, 2.0, 3.0, 255, 0);
        textSize(16);
        fill(220, 40, 40, alpha);
        text(game.disconnectMessage, CANVAS_W / 2, 275);
      } else {
        game.disconnectMessage = "";
      }
    }

    qrdDrawButton(CANVAS_W / 2, 310, "2 Players", color(46, 204, 113));
    qrdDrawButton(CANVAS_W / 2, 375, "vs AI", QRD_COLOR_P2);
    qrdDrawButton(CANVAS_W / 2, 440, "Online", color(180, 120, 60));
    qrdDrawButton(CANVAS_W / 2, 505, "How to Play", color(241, 196, 15));
    qrdDrawButton(CANVAS_W / 2, 570, "Back", color(120));
  }

  void drawLobby() {
    background(QRD_COLOR_BG);
    drawLobbyUI(game.lobbyState, game.network, game.roomCode, color(180, 120, 60));
  }

  void drawHowTo(int page) {
    color accent = color(180, 120, 60);
    drawHowToFrame("QUORIDOR - How to Play", page, 2, accent);

    if (page == 0) {
      drawHowToSubtitle("How to Play", 90);

      // Mini board illustration
      float gx = CANVAS_W / 2 - 80;
      float gy = 140;
      float cs = 16;
      float gp = 3;

      noStroke();
      fill(QRD_COLOR_BOARD);
      rect(gx - 4, gy - 4, (cs + gp) * 9 - gp + 8, (cs + gp) * 9 - gp + 8, 6);
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          fill(QRD_COLOR_CELL);
          rect(gx + c * (cs + gp), gy + r * (cs + gp), cs, cs, 2);
        }
      }
      // P1 pawn at bottom center
      fill(QRD_COLOR_P1);
      ellipse(gx + 4 * (cs + gp) + cs / 2, gy + 8 * (cs + gp) + cs / 2, cs * 0.7, cs * 0.7);
      // P2 pawn at top center
      fill(QRD_COLOR_P2);
      ellipse(gx + 4 * (cs + gp) + cs / 2, gy + 0 * (cs + gp) + cs / 2, cs * 0.7, cs * 0.7);
      // Example wall
      fill(QRD_COLOR_WALL);
      rect(gx + 3 * (cs + gp), gy + 3 * (cs + gp) + cs, cs * 2 + gp, gp, 1);

      float ty = gy + (cs + gp) * 9 + 20;
      drawHowToText("9x9 board. Each player has a pawn and 10 walls.", ty);
      drawHowToText("On your turn: move your pawn 1 step OR place a wall.", ty + 25);
      drawHowToText("Pawns move up/down/left/right (no diagonals).", ty + 50);
      drawHowToText("You can jump over an adjacent opponent.", ty + 75);
      drawHowToText("Press W to toggle wall mode, R to rotate wall.", ty + 100);

    } else if (page == 1) {
      drawHowToSubtitle("Walls & Winning", 90);

      // Wall illustration
      float gx = CANVAS_W / 2 - 60;
      float gy = 130;
      float cs = 30;
      float gp = 5;

      noStroke();
      fill(QRD_COLOR_BOARD);
      rect(gx - 4, gy - 4, (cs + gp) * 4 - gp + 8, (cs + gp) * 4 - gp + 8, 6);
      for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
          fill(QRD_COLOR_CELL);
          rect(gx + c * (cs + gp), gy + r * (cs + gp), cs, cs, 2);
        }
      }
      // Horizontal wall
      fill(QRD_COLOR_WALL);
      rect(gx + 1 * (cs + gp), gy + 1 * (cs + gp) + cs, cs * 2 + gp, gp, 1);
      // Vertical wall
      rect(gx + 2 * (cs + gp) + cs, gy + 2 * (cs + gp), gp, cs * 2 + gp, 1);

      float ty = gy + (cs + gp) * 4 + 20;
      drawHowToText("Walls span 2 cells and block movement.", ty);
      drawHowToText("Walls cannot overlap or cross each other.", ty + 25);
      drawHowToText("You must always leave a path for both players!", ty + 50);
      drawHowToText("", ty + 75);

      // Goal arrows
      textAlign(CENTER, CENTER);
      textSize(14);
      fill(QRD_COLOR_P1);
      text("Blue goal: reach the TOP row", CANVAS_W / 2, ty + 100);
      fill(QRD_COLOR_P2);
      text("Red goal: reach the BOTTOM row", CANVAS_W / 2, ty + 125);
      fill(210);
      textSize(14);
      text("First to reach their goal row wins!", CANVAS_W / 2, ty + 160);
    }
  }

  void qrdDrawButton(float x, float y, String label, color c) {
    float bw = 200, bh = 50;
    boolean hover = mouseX > x - bw/2 && mouseX < x + bw/2 &&
                    mouseY > y - bh/2 && mouseY < y + bh/2;
    noStroke();
    fill(c, hover ? 200 : 120);
    rect(x - bw/2, y - bh/2, bw, bh, 8);
    textAlign(CENTER, CENTER);
    textSize(20);
    fill(255);
    text(label, x, y);
  }
}
