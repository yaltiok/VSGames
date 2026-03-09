// SXO Colors
final color SXO_COLOR_BG = color(30, 30, 40);
final color SXO_COLOR_X = color(231, 76, 60);
final color SXO_COLOR_O = color(52, 152, 219);
final color SXO_COLOR_GRID_BIG = color(200, 200, 210);
final color SXO_COLOR_GRID_SMALL = color(80, 80, 100);
final color SXO_COLOR_ACTIVE = color(46, 204, 113);
final color SXO_COLOR_WON_X = color(231, 76, 60, 60);
final color SXO_COLOR_WON_O = color(52, 152, 219, 60);
final color SXO_COLOR_DRAW_BG = color(100, 100, 100, 60);

class SXORenderer {
  SXOGame game;

  SXORenderer(SXOGame game) {
    this.game = game;
  }

  void drawGame() {
    background(SXO_COLOR_BG);
    drawTopBar();
    drawActiveHighlight();
    drawBigGrid();
    drawSmallGrids();
    drawMarks();
    drawWonOverlays();
    drawHover();
    if (game.board.bigWinner != 0) drawWinLine();
    drawParticles(game.particles);
  }

  void drawTopBar() {
    textAlign(CENTER, CENTER);
    textSize(20);

    if (game.state == SXO_GAMEOVER) {
      drawGameOverUI();
      return;
    }

    String label;
    color c;
    if (game.currentPlayer == 1) {
      label = "X's Turn";
      c = SXO_COLOR_X;
    } else {
      label = "O's Turn";
      c = SXO_COLOR_O;
    }
    if (game.mode == SXO_AI_MODE && game.currentPlayer == 2) {
      label = "AI Thinking...";
    }
    if (game.mode == SXO_ONLINE) {
      if (game.currentPlayer == game.playerRole) {
        label = "Your Turn (" + (game.playerRole == 1 ? "X" : "O") + ")";
      } else {
        label = "Opponent's Turn";
      }
    }

    fill(c);
    text(label, CANVAS_W / 2, SXO_TOP_BAR / 2);

    textSize(12);
    fill(180);
    if (game.board.activeGrid == -1) {
      text("Play anywhere", CANVAS_W / 2, SXO_TOP_BAR / 2 + 22);
    } else {
      int r = game.board.activeGrid / 3 + 1;
      int col = game.board.activeGrid % 3 + 1;
      text("Play in grid (" + r + "," + col + ")", CANVAS_W / 2, SXO_TOP_BAR / 2 + 22);
    }
  }

  void drawBigGrid() {
    stroke(SXO_COLOR_GRID_BIG);
    strokeWeight(4);
    for (int i = 1; i < 3; i++) {
      line(SXO_OFFSET_X + i * SXO_BIG_CELL, SXO_TOP_BAR, SXO_OFFSET_X + i * SXO_BIG_CELL, SXO_TOP_BAR + SXO_GRID_SIZE);
      line(SXO_OFFSET_X, SXO_TOP_BAR + i * SXO_BIG_CELL, SXO_OFFSET_X + SXO_GRID_SIZE, SXO_TOP_BAR + i * SXO_BIG_CELL);
    }
  }

  void drawActiveHighlight() {
    if (game.board.bigWinner != 0) return;
    float pulse = map(sin(millis() * 0.004), -1, 1, 30, 80);

    if (game.board.activeGrid == -1) {
      for (int g = 0; g < 9; g++) {
        if (game.board.grids[g].winner != 0) continue;
        int bx = SXO_OFFSET_X + (g % 3) * SXO_BIG_CELL;
        int by = SXO_TOP_BAR + (g / 3) * SXO_BIG_CELL;
        noStroke();
        fill(SXO_COLOR_ACTIVE, pulse * 0.5);
        rect(bx + 3, by + 3, SXO_BIG_CELL - 6, SXO_BIG_CELL - 6, 4);
      }
    } else {
      int bx = SXO_OFFSET_X + (game.board.activeGrid % 3) * SXO_BIG_CELL;
      int by = SXO_TOP_BAR + (game.board.activeGrid / 3) * SXO_BIG_CELL;
      noStroke();
      fill(SXO_COLOR_ACTIVE, pulse);
      rect(bx + 3, by + 3, SXO_BIG_CELL - 6, SXO_BIG_CELL - 6, 4);
    }
  }

  void drawSmallGrids() {
    stroke(SXO_COLOR_GRID_SMALL);
    strokeWeight(1);
    for (int g = 0; g < 9; g++) {
      int bx = SXO_OFFSET_X + (g % 3) * SXO_BIG_CELL;
      int by = SXO_TOP_BAR + (g / 3) * SXO_BIG_CELL;
      float pad = 8;
      float cellW = (SXO_BIG_CELL - pad * 2) / 3.0;
      for (int i = 1; i < 3; i++) {
        float lx = bx + pad + i * cellW;
        line(lx, by + pad, lx, by + SXO_BIG_CELL - pad);
        float ly = by + pad + i * cellW;
        line(bx + pad, ly, bx + SXO_BIG_CELL - pad, ly);
      }
    }
  }

  void drawMarks() {
    for (int g = 0; g < 9; g++) {
      int bx = SXO_OFFSET_X + (g % 3) * SXO_BIG_CELL;
      int by = SXO_TOP_BAR + (g / 3) * SXO_BIG_CELL;
      float pad = 8;
      float cellW = (SXO_BIG_CELL - pad * 2) / 3.0;

      for (int c = 0; c < 9; c++) {
        int val = game.board.grids[g].cells[c];
        if (val == 0) continue;
        float cx = bx + pad + (c % 3) * cellW + cellW / 2;
        float cy = by + pad + (c / 3) * cellW + cellW / 2;
        float sz = cellW * 0.35;

        float anim = 1.0;
        if (game.lastMoveGrid == g && game.lastMoveCell == c && game.animProgress < 1.0) {
          anim = game.animProgress;
        }

        if (val == 1) drawX(cx, cy, sz, anim);
        else drawO(cx, cy, sz, anim);
      }
    }
  }

  void drawX(float cx, float cy, float sz, float anim) {
    stroke(SXO_COLOR_X);
    strokeWeight(3);
    noFill();
    float d = sz * anim;
    line(cx - d, cy - d, cx + d, cy + d);
    if (anim > 0.5) {
      float d2 = sz * (anim - 0.5) * 2;
      line(cx + d2, cy - d2, cx - d2, cy + d2);
    }
  }

  void drawO(float cx, float cy, float sz, float anim) {
    stroke(SXO_COLOR_O);
    strokeWeight(3);
    noFill();
    float angle = TWO_PI * anim;
    arc(cx, cy, sz * 2, sz * 2, 0, angle);
  }

  void drawWonOverlays() {
    for (int g = 0; g < 9; g++) {
      if (game.board.bigGrid[g] == 0) continue;
      int bx = SXO_OFFSET_X + (g % 3) * SXO_BIG_CELL;
      int by = SXO_TOP_BAR + (g / 3) * SXO_BIG_CELL;

      noStroke();
      if (game.board.bigGrid[g] == 1) fill(SXO_COLOR_WON_X);
      else if (game.board.bigGrid[g] == 2) fill(SXO_COLOR_WON_O);
      else fill(SXO_COLOR_DRAW_BG);
      rect(bx + 2, by + 2, SXO_BIG_CELL - 4, SXO_BIG_CELL - 4, 4);

      float cx = bx + SXO_BIG_CELL / 2;
      float cy = by + SXO_BIG_CELL / 2;
      float sz = SXO_BIG_CELL * 0.3;
      if (game.board.bigGrid[g] == 1) {
        stroke(SXO_COLOR_X);
        strokeWeight(6);
        line(cx - sz, cy - sz, cx + sz, cy + sz);
        line(cx + sz, cy - sz, cx - sz, cy + sz);
      } else if (game.board.bigGrid[g] == 2) {
        stroke(SXO_COLOR_O);
        strokeWeight(6);
        noFill();
        ellipse(cx, cy, sz * 2, sz * 2);
      } else {
        textAlign(CENTER, CENTER);
        textSize(40);
        fill(150);
        text("=", cx, cy);
      }
    }
  }

  void drawHover() {
    if (game.board.bigWinner != 0) return;
    if (game.mode == SXO_AI_MODE && game.currentPlayer == 2) return;
    if (game.mode == SXO_ONLINE && game.currentPlayer != game.playerRole) return;
    if (mouseY < SXO_TOP_BAR || mouseY > SXO_TOP_BAR + SXO_GRID_SIZE) return;
    if (mouseX < SXO_OFFSET_X || mouseX > SXO_OFFSET_X + SXO_GRID_SIZE) return;

    int bigCol = (mouseX - SXO_OFFSET_X) / SXO_BIG_CELL;
    int bigRow = (mouseY - SXO_TOP_BAR) / SXO_BIG_CELL;
    int gridIdx = bigRow * 3 + bigCol;

    int bx = SXO_OFFSET_X + bigCol * SXO_BIG_CELL;
    int by = SXO_TOP_BAR + bigRow * SXO_BIG_CELL;
    float pad = 8;
    float cellW = (SXO_BIG_CELL - pad * 2) / 3.0;
    int smallCol = (int)((mouseX - bx - pad) / cellW);
    int smallRow = (int)((mouseY - by - pad) / cellW);
    if (smallCol < 0 || smallCol > 2 || smallRow < 0 || smallRow > 2) return;
    int cellIdx = smallRow * 3 + smallCol;

    if (!game.board.isValidMove(gridIdx, cellIdx)) return;

    float cx = bx + pad + smallCol * cellW + cellW / 2;
    float cy = by + pad + smallRow * cellW + cellW / 2;
    float sz = cellW * 0.35;

    if (game.currentPlayer == 1) {
      stroke(SXO_COLOR_X, 80);
      strokeWeight(2);
      noFill();
      line(cx - sz, cy - sz, cx + sz, cy + sz);
      line(cx + sz, cy - sz, cx - sz, cy + sz);
    } else {
      stroke(SXO_COLOR_O, 80);
      strokeWeight(2);
      noFill();
      ellipse(cx, cy, sz * 2, sz * 2);
    }
  }

  void drawWinLine() {
    if (game.winLineStart == null || game.winLineEnd == null) return;
    float progress = constrain((millis() - game.gameOverTime) / 600.0, 0, 1);
    float ex = lerp(game.winLineStart[0], game.winLineEnd[0], progress);
    float ey = lerp(game.winLineStart[1], game.winLineEnd[1], progress);
    stroke(255, 255, 100, 200);
    strokeWeight(6);
    line(game.winLineStart[0], game.winLineStart[1], ex, ey);
  }

  void drawGameOverUI() {
    String msg;
    color c;
    if (game.board.bigWinner == 3) {
      msg = "Draw!";
      c = color(180);
    } else if (game.mode == SXO_ONLINE) {
      if (game.board.bigWinner == game.playerRole) {
        msg = "You Win!";
        c = (game.playerRole == 1) ? SXO_COLOR_X : SXO_COLOR_O;
      } else {
        msg = "You Lose!";
        c = (game.playerRole == 1) ? SXO_COLOR_O : SXO_COLOR_X;
      }
    } else if (game.board.bigWinner == 1) {
      msg = "X Wins!";
      c = SXO_COLOR_X;
    } else {
      msg = (game.mode == SXO_AI_MODE) ? "AI Wins!" : "O Wins!";
      c = SXO_COLOR_O;
    }
    textSize(28);
    fill(c);
    text(msg, CANVAS_W / 2, SXO_TOP_BAR / 2 - 10);

    float elapsed = (millis() - game.gameOverTime) / 1000.0;
    if (elapsed > 1.5) {
      drawButton(CANVAS_W / 2 - 110, SXO_TOP_BAR / 2 + 25, "Restart", SXO_COLOR_ACTIVE);
      drawButton(CANVAS_W / 2 + 110, SXO_TOP_BAR / 2 + 25, "Menu", color(180));
    }
  }

  // Menu

  void drawMenu() {
    background(SXO_COLOR_BG);

    // Floating decorative marks
    for (int i = 0; i < 12; i++) {
      float x = (noise(i * 10 + millis() * 0.0003) * CANVAS_W);
      float y = (noise(i * 20 + 500 + millis() * 0.0003) * CANVAS_H);
      if (i % 2 == 0) {
        stroke(SXO_COLOR_X, 30);
        strokeWeight(2);
        float s = 15;
        line(x - s, y - s, x + s, y + s);
        line(x + s, y - s, x - s, y + s);
      } else {
        stroke(SXO_COLOR_O, 30);
        strokeWeight(2);
        noFill();
        ellipse(x, y, 30, 30);
      }
    }

    // Title
    float bounce = sin(millis() * 0.003) * 8;
    textAlign(CENTER, CENTER);
    textSize(56);
    fill(255);
    text("SUPER XOX", CANVAS_W / 2, 180 + bounce);

    textSize(16);
    fill(150);
    text("Ultimate Tic-Tac-Toe", CANVAS_W / 2, 230);

    // Disconnect message
    if (game.disconnectMessage.length() > 0) {
      float elapsed = (millis() - game.disconnectMessageTime) / 1000.0;
      if (elapsed < 3.0) {
        float alpha = elapsed < 2.0 ? 255 : map(elapsed, 2.0, 3.0, 255, 0);
        textSize(16);
        fill(SXO_COLOR_X, alpha);
        text(game.disconnectMessage, CANVAS_W / 2, 290);
      } else {
        game.disconnectMessage = "";
      }
    }

    drawButton(CANVAS_W / 2, 310, "2 Players", SXO_COLOR_ACTIVE);
    drawButton(CANVAS_W / 2, 375, "vs AI", SXO_COLOR_O);
    drawButton(CANVAS_W / 2, 440, "Online", SXO_COLOR_X);
    drawButton(CANVAS_W / 2, 505, "How to Play", color(241, 196, 15));
    drawButton(CANVAS_W / 2, 570, "Back", color(120));
  }

  // Lobby

  void drawLobby() {
    background(SXO_COLOR_BG);
    drawLobbyUI(game.lobbyState, game.network, game.roomCode, SXO_COLOR_ACTIVE);
  }

  // How to Play

  void drawHowTo(int page) {
    drawHowToFrame("Super XOX — How to Play", page, 3, SXO_COLOR_X);

    switch (page) {
      case 0: drawHowToPage0(); break;
      case 1: drawHowToPage1(); break;
      case 2: drawHowToPage2(); break;
    }
  }

  void drawHowToPage0() {
    drawHowToSubtitle("The Board", 85);

    // Draw mini 3x3 grid of 3x3 grids
    float ox = CANVAS_W / 2 - 90;
    float oy = 130;
    float bigSz = 60;
    float pad = 3;
    float cellSz = (bigSz - pad * 2) / 3.0;

    for (int g = 0; g < 9; g++) {
      float bx = ox + (g % 3) * bigSz;
      float by = oy + (g / 3) * bigSz;
      // Sub-grid background
      noStroke();
      fill(50, 50, 65);
      rect(bx + 1, by + 1, bigSz - 2, bigSz - 2, 2);
      // Inner lines
      stroke(SXO_COLOR_GRID_SMALL);
      strokeWeight(1);
      for (int i = 1; i < 3; i++) {
        float lx = bx + pad + i * cellSz;
        line(lx, by + pad, lx, by + bigSz - pad);
        float ly = by + pad + i * cellSz;
        line(bx + pad, ly, bx + bigSz - pad, ly);
      }
    }
    // Big grid lines
    stroke(SXO_COLOR_GRID_BIG);
    strokeWeight(2);
    for (int i = 1; i < 3; i++) {
      line(ox + i * bigSz, oy, ox + i * bigSz, oy + bigSz * 3);
      line(ox, oy + i * bigSz, ox + bigSz * 3, oy + i * bigSz);
    }

    drawHowToBullet("The board has 9 mini grids, each a tic-tac-toe game.", 80, 340);
    drawHowToBullet("Win 3 mini grids in a row to win the game!", 80, 370);
  }

  void drawHowToPage1() {
    drawHowToSubtitle("The Active Grid Rule", 85);

    float sz = 50;
    float pad = 2;
    float cellSz = (sz - pad * 2) / 3.0;

    // Left mini board: show move in cell 4 (center) of sub-grid
    float lx = 120;
    float ly = 150;
    for (int g = 0; g < 9; g++) {
      float bx = lx + (g % 3) * sz;
      float by = ly + (g / 3) * sz;
      noStroke();
      fill(50, 50, 65);
      rect(bx + 1, by + 1, sz - 2, sz - 2, 1);
      stroke(SXO_COLOR_GRID_SMALL);
      strokeWeight(0.5);
      for (int i = 1; i < 3; i++) {
        line(bx + pad + i * cellSz, by + pad, bx + pad + i * cellSz, by + sz - pad);
        line(bx + pad, by + pad + i * cellSz, bx + sz - pad, by + pad + i * cellSz);
      }
    }
    // Mark X in grid 0, cell 7 (bottom-center)
    float markGx = lx + 0 * sz;
    float markGy = ly + 0 * sz;
    float mx = markGx + pad + 1 * cellSz + cellSz / 2;
    float my = markGy + pad + 2 * cellSz + cellSz / 2;
    float ms = cellSz * 0.3;
    stroke(SXO_COLOR_X);
    strokeWeight(2);
    line(mx - ms, my - ms, mx + ms, my + ms);
    line(mx + ms, my - ms, mx - ms, my + ms);

    // Highlight sub-grid 7 (bottom-center) on right board
    float rx = 330;
    float ry = 150;
    for (int g = 0; g < 9; g++) {
      float bx = rx + (g % 3) * sz;
      float by = ry + (g / 3) * sz;
      noStroke();
      fill(g == 7 ? color(46, 204, 113, 80) : color(50, 50, 65));
      rect(bx + 1, by + 1, sz - 2, sz - 2, 1);
      stroke(SXO_COLOR_GRID_SMALL);
      strokeWeight(0.5);
      for (int i = 1; i < 3; i++) {
        line(bx + pad + i * cellSz, by + pad, bx + pad + i * cellSz, by + sz - pad);
        line(bx + pad, by + pad + i * cellSz, bx + sz - pad, by + pad + i * cellSz);
      }
    }

    // Arrow from left board to right board
    float ax1 = lx + sz * 1.5;
    float ay1 = ly + sz * 3 + 15;
    float ax2 = rx + sz * 1.5;
    float ay2 = ry + sz * 3 + 15;
    stroke(241, 196, 15);
    strokeWeight(2);
    line(ax1, ay1, ax2, ay2);
    line(ax2, ay2, ax2 - 10, ay2 - 8);
    line(ax2, ay2, ax2 - 10, ay2 + 8);

    // Labels
    textAlign(CENTER, CENTER);
    textSize(12);
    fill(SXO_COLOR_X);
    text("Cell 7", lx + sz * 0.5, ly - 12);
    fill(SXO_COLOR_ACTIVE);
    text("Grid 7", rx + sz * 1.5, ry - 12);

    drawHowToBullet("After you play in cell N, your opponent must play in grid N.", 60, 380);
    drawHowToBullet("If that grid is won or full, opponent can play anywhere.", 60, 410);
  }

  void drawHowToPage2() {
    drawHowToSubtitle("Winning", 85);

    // Draw 3x3 big grid with won sub-grids
    float ox = CANVAS_W / 2 - 90;
    float oy = 130;
    float bigSz = 60;

    int[] demo = {1, 0, 2, 1, 2, 0, 1, 0, 0}; // X wins diagonal 0,3,6 → vertical left
    for (int g = 0; g < 9; g++) {
      float bx = ox + (g % 3) * bigSz;
      float by = oy + (g / 3) * bigSz;
      noStroke();
      if (demo[g] == 1) fill(SXO_COLOR_WON_X);
      else if (demo[g] == 2) fill(SXO_COLOR_WON_O);
      else fill(50, 50, 65);
      rect(bx + 1, by + 1, bigSz - 2, bigSz - 2, 2);

      float cx = bx + bigSz / 2;
      float cy = by + bigSz / 2;
      float s = bigSz * 0.25;
      if (demo[g] == 1) {
        stroke(SXO_COLOR_X);
        strokeWeight(3);
        line(cx - s, cy - s, cx + s, cy + s);
        line(cx + s, cy - s, cx - s, cy + s);
      } else if (demo[g] == 2) {
        stroke(SXO_COLOR_O);
        strokeWeight(3);
        noFill();
        ellipse(cx, cy, s * 2, s * 2);
      }
    }

    // Big grid lines
    stroke(SXO_COLOR_GRID_BIG);
    strokeWeight(2);
    for (int i = 1; i < 3; i++) {
      line(ox + i * bigSz, oy, ox + i * bigSz, oy + bigSz * 3);
      line(ox, oy + i * bigSz, ox + bigSz * 3, oy + i * bigSz);
    }

    // Win line (vertical left column: grids 0,3,6)
    stroke(255, 255, 100, 200);
    strokeWeight(4);
    line(ox + bigSz / 2, oy + bigSz / 2, ox + bigSz / 2, oy + bigSz * 2.5);

    drawHowToBullet("Win a mini grid by getting 3 in a row.", 60, 350);
    drawHowToBullet("Win 3 mini grids in a row (horizontal, vertical, or diagonal) to win!", 60, 380);
    drawHowToBullet("If all grids are decided with no winner, it's a draw.", 60, 410);
  }

  // Shared button

  void drawButton(float x, float y, String label, color c) {
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
