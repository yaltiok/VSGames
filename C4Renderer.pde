final color C4_COLOR_BG = color(25, 35, 60);
final color C4_COLOR_BOARD = color(30, 100, 200);
final color C4_COLOR_EMPTY = color(240, 240, 250);
final color C4_COLOR_P1 = color(220, 40, 40);
final color C4_COLOR_P2 = color(240, 200, 30);
final color C4_COLOR_WIN = color(255, 255, 100, 150);

class C4Renderer {
  C4Game game;
  int cellSize = 72;
  int boardW = cellSize * C4_COLS;   // 504
  int boardH = cellSize * C4_ROWS;   // 432
  int offsetX = (CANVAS_W - boardW) / 2;  // 48
  int offsetY = 150;

  C4Renderer(C4Game game) {
    this.game = game;
  }

  int getColumnAtMouse() {
    if (mouseX < offsetX || mouseX > offsetX + boardW) return -1;
    return (mouseX - offsetX) / cellSize;
  }

  // Game drawing

  void drawGame() {
    background(C4_COLOR_BG);
    drawTopBar();
    drawHoverPreview();
    drawBoard();
    drawDropAnimation();
    drawWinHighlight();
    drawParticles(game.particles);
  }

  void drawBoard() {
    // Board background
    noStroke();
    fill(C4_COLOR_BOARD);
    rect(offsetX - 8, offsetY - 8, boardW + 16, boardH + 16, 12);

    for (int r = 0; r < C4_ROWS; r++) {
      for (int c = 0; c < C4_COLS; c++) {
        float cx = offsetX + c * cellSize + cellSize / 2.0;
        float cy = offsetY + r * cellSize + cellSize / 2.0;
        float diam = cellSize * 0.78;
        int val = game.board.grid[r][c];

        if (val == 0) {
          fill(C4_COLOR_EMPTY);
          noStroke();
          ellipse(cx, cy, diam, diam);
        } else {
          drawDisc(cx, cy, diam, val);
        }
      }
    }
  }

  void drawDisc(float cx, float cy, float diam, int player) {
    color base = (player == 1) ? C4_COLOR_P1 : C4_COLOR_P2;
    noStroke();
    // Shadow
    fill(0, 40);
    ellipse(cx + 2, cy + 2, diam, diam);
    // Main disc
    fill(base);
    ellipse(cx, cy, diam, diam);
    // Highlight for 3D look
    color highlight = (player == 1) ? color(255, 120, 100, 100) : color(255, 240, 120, 100);
    fill(highlight);
    ellipse(cx - diam * 0.12, cy - diam * 0.12, diam * 0.45, diam * 0.45);
  }

  void drawHoverPreview() {
    if (game.state != C4_PLAYING) return;
    if (game.mode == C4_AI_MODE && game.currentPlayer == 2) return;
    if (game.mode == C4_ONLINE && game.currentPlayer != game.playerRole) return;

    int col = getColumnAtMouse();
    if (col < 0 || col >= C4_COLS) return;
    if (!game.board.isValidDrop(col)) return;

    float cx = offsetX + col * cellSize + cellSize / 2.0;
    float cy = offsetY - cellSize / 2.0 - 5;
    float diam = cellSize * 0.78;

    color base = (game.currentPlayer == 1) ? C4_COLOR_P1 : C4_COLOR_P2;
    noStroke();
    fill(base, 120);
    ellipse(cx, cy, diam, diam);
  }

  void drawDropAnimation() {
    if (game.state != C4_DROPPING) return;

    float cx = offsetX + game.dropCol * cellSize + cellSize / 2.0;
    float diam = cellSize * 0.78;
    drawDisc(cx, game.dropCurrentY, diam, game.dropPlayer);
  }

  void drawWinHighlight() {
    if (game.state != C4_GAMEOVER || game.winLine == null) return;

    float progress = constrain((millis() - game.gameOverTime) / 500.0, 0, 1);
    float pulse = map(sin(millis() * 0.006), -1, 1, 80, 200);

    int r1 = game.winLine[0], c1 = game.winLine[1];
    int r2 = game.winLine[2], c2 = game.winLine[3];

    int dr = 0, dc = 0;
    if (r2 > r1) dr = 1; else if (r2 < r1) dr = -1;
    if (c2 > c1) dc = 1; else if (c2 < c1) dc = -1;

    for (int i = 0; i < 4; i++) {
      float t = constrain(progress * 4 - i, 0, 1);
      if (t <= 0) continue;
      int rr = r1 + i * dr;
      int cc = c1 + i * dc;
      float cx = offsetX + cc * cellSize + cellSize / 2.0;
      float cy = offsetY + rr * cellSize + cellSize / 2.0;
      float diam = cellSize * 0.88;

      noFill();
      stroke(255, 255, 100, pulse * t);
      strokeWeight(4);
      ellipse(cx, cy, diam, diam);
    }
  }

  void drawTopBar() {
    textAlign(CENTER, CENTER);

    if (game.state == C4_GAMEOVER) {
      drawGameOverUI();
      return;
    }

    // Current player indicator
    String label;
    color c;
    if (game.currentPlayer == 1) {
      label = "Red's Turn";
      c = C4_COLOR_P1;
    } else {
      label = "Yellow's Turn";
      c = C4_COLOR_P2;
    }
    if (game.mode == C4_AI_MODE && game.currentPlayer == 2) {
      label = "AI Thinking...";
    }
    if (game.mode == C4_ONLINE) {
      if (game.currentPlayer == game.playerRole) {
        label = "Your Turn (" + (game.playerRole == 1 ? "Red" : "Yellow") + ")";
      } else {
        label = "Opponent's Turn";
      }
      c = (game.currentPlayer == 1) ? C4_COLOR_P1 : C4_COLOR_P2;
    }
    if (game.state == C4_DROPPING) {
      label = (game.dropPlayer == 1) ? "Red" : "Yellow";
      c = (game.dropPlayer == 1) ? C4_COLOR_P1 : C4_COLOR_P2;
    }

    // Disc indicator
    float indicatorX = CANVAS_W / 2 - textWidth(label) / 2 - 25;
    noStroke();
    fill(c);
    ellipse(CANVAS_W / 2 - 80, 40, 20, 20);

    textSize(24);
    fill(255);
    text(label, CANVAS_W / 2 + 5, 40);
  }

  void drawGameOverUI() {
    String msg;
    color c;
    if (game.winner == 3) {
      msg = "Draw!";
      c = color(180);
    } else if (game.mode == C4_ONLINE) {
      if (game.winner == game.playerRole) {
        msg = "You Win!";
      } else {
        msg = "You Lose!";
      }
      c = (game.winner == 1) ? C4_COLOR_P1 : C4_COLOR_P2;
    } else if (game.winner == 1) {
      msg = "Red Wins!";
      c = C4_COLOR_P1;
    } else {
      msg = (game.mode == C4_AI_MODE) ? "AI Wins!" : "Yellow Wins!";
      c = C4_COLOR_P2;
    }

    textSize(28);
    fill(c);
    text(msg, CANVAS_W / 2, 30);

    float elapsed = (millis() - game.gameOverTime) / 1000.0;
    if (elapsed > 1.0) {
      c4DrawButton(CANVAS_W / 2 - 110, 60, "Restart", color(46, 204, 113));
      c4DrawButton(CANVAS_W / 2 + 110, 60, "Menu", color(120));
    }
  }

  // Menu

  void drawMenu() {
    background(C4_COLOR_BG);

    // Floating decorative circles
    for (int i = 0; i < 10; i++) {
      float x = noise(i * 10 + millis() * 0.0003) * CANVAS_W;
      float y = noise(i * 20 + 500 + millis() * 0.0003) * CANVAS_H;
      noStroke();
      if (i % 2 == 0) {
        fill(C4_COLOR_P1, 25);
      } else {
        fill(C4_COLOR_P2, 25);
      }
      ellipse(x, y, 35, 35);
    }

    // Title
    float bounce = sin(millis() * 0.003) * 8;
    textAlign(CENTER, CENTER);
    textSize(52);
    fill(255);
    text("CONNECT FOUR", CANVAS_W / 2, 180 + bounce);

    textSize(18);
    fill(150);
    text("4'l\u00fc Ba\u011fla", CANVAS_W / 2, 230);

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

    c4DrawButton(CANVAS_W / 2, 310, "2 Players", color(46, 204, 113));
    c4DrawButton(CANVAS_W / 2, 375, "vs AI", C4_COLOR_P2);
    c4DrawButton(CANVAS_W / 2, 440, "Online", color(30, 100, 200));
    c4DrawButton(CANVAS_W / 2, 505, "How to Play", color(241, 196, 15));
    c4DrawButton(CANVAS_W / 2, 570, "Back", color(120));
  }

  void drawLobby() {
    background(C4_COLOR_BG);
    drawLobbyUI(game.lobbyState, game.network, game.roomCode, color(30, 100, 200));
  }

  void drawHowTo(int page) {
    color accent = color(30, 100, 200);
    drawHowToFrame("CONNECT FOUR - How to Play", page, 2, accent);

    if (page == 0) {
      drawHowToSubtitle("How to Play", 90);

      // Mini 7x6 board
      float gx = CANVAS_W / 2 - 105;
      float gy = 150;
      float cs = 30;
      noStroke();
      fill(30, 100, 200);
      rect(gx - 4, gy - 4, cs * 7 + 8, cs * 6 + 8, 8);
      // Empty cells
      for (int r = 0; r < 6; r++) {
        for (int c = 0; c < 7; c++) {
          fill(240, 240, 250);
          ellipse(gx + c * cs + cs / 2, gy + r * cs + cs / 2, cs * 0.7, cs * 0.7);
        }
      }
      // A few placed discs showing gravity
      fill(220, 40, 40); ellipse(gx + 2 * cs + cs / 2, gy + 5 * cs + cs / 2, cs * 0.7, cs * 0.7);
      fill(240, 200, 30); ellipse(gx + 3 * cs + cs / 2, gy + 5 * cs + cs / 2, cs * 0.7, cs * 0.7);
      fill(220, 40, 40); ellipse(gx + 3 * cs + cs / 2, gy + 4 * cs + cs / 2, cs * 0.7, cs * 0.7);

      // Arrow showing disc dropping
      float arrowX = gx + 5 * cs + cs / 2;
      stroke(241, 196, 15); strokeWeight(2);
      line(arrowX, gy - 25, arrowX, gy + 4 * cs);
      line(arrowX, gy + 4 * cs, arrowX - 6, gy + 4 * cs - 10);
      line(arrowX, gy + 4 * cs, arrowX + 6, gy + 4 * cs - 10);
      // Disc at top of arrow
      noStroke();
      fill(240, 200, 30, 150);
      ellipse(arrowX, gy - 30, cs * 0.7, cs * 0.7);

      drawHowToText("Drop discs into columns \u2014 they fall to the bottom.", gy + cs * 6 + 30);
      drawHowToText("Red goes first, then Yellow.", gy + cs * 6 + 55);

    } else if (page == 1) {
      drawHowToSubtitle("Winning", 90);

      float gy = 130;
      float cs = 28;

      // Horizontal example
      float hx = CANVAS_W / 2 - 70;
      textAlign(CENTER, CENTER); textSize(12); fill(180);
      text("Horizontal", hx + cs * 2, gy - 10);
      noStroke();
      for (int i = 0; i < 4; i++) {
        fill(220, 40, 40);
        ellipse(hx + i * cs + cs / 2, gy + cs / 2, cs * 0.75, cs * 0.75);
      }
      noFill(); stroke(255, 255, 100, 200); strokeWeight(2);
      rect(hx - 2, gy - 2, cs * 4 + 4, cs + 4, 4);

      // Vertical example
      float vx = CANVAS_W / 2 - 60;
      float vy = gy + 60;
      noStroke();
      textAlign(CENTER, CENTER); textSize(12); fill(180);
      text("Vertical", vx + cs / 2, vy - 10);
      for (int i = 0; i < 4; i++) {
        fill(240, 200, 30);
        ellipse(vx + cs / 2, vy + i * cs + cs / 2, cs * 0.75, cs * 0.75);
      }
      noFill(); stroke(255, 255, 100, 200); strokeWeight(2);
      rect(vx - 2, vy - 2, cs + 4, cs * 4 + 4, 4);

      // Diagonal example
      float dx = CANVAS_W / 2 - 70;
      float dy = vy + cs * 4 + 30;
      noStroke();
      textAlign(CENTER, CENTER); textSize(12); fill(180);
      text("Diagonal", dx + cs * 2, dy - 10);
      for (int i = 0; i < 4; i++) {
        fill(220, 40, 40);
        ellipse(dx + i * cs + cs / 2, dy + i * cs + cs / 2, cs * 0.75, cs * 0.75);
      }
      noFill(); stroke(255, 255, 100, 200); strokeWeight(2);
      line(dx, dy, dx + cs * 4, dy + cs * 4);

      drawHowToText("Connect 4 of your discs in a row to win!", dy + cs * 4 + 30);
      drawHowToText("Horizontal, vertical, or diagonal all count.", dy + cs * 4 + 55);
      drawHowToText("Board full with no winner = draw.", dy + cs * 4 + 80);
    }
  }

  void c4DrawButton(float x, float y, String label, color c) {
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
