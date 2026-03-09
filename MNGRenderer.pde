final color MNG_COLOR_BG = color(139, 90, 43);
final color MNG_COLOR_BOARD = color(101, 67, 33);
final color MNG_COLOR_PIT = color(70, 45, 20);
final color MNG_COLOR_STONE_BASE = color(180, 160, 140);
final color MNG_COLOR_P1 = color(52, 199, 190);
final color MNG_COLOR_P2 = color(230, 126, 34);
final color MNG_COLOR_SELECT = color(46, 204, 113);

// Layout constants
final int MNG_TOP_BAR = 80;
final float MNG_BOARD_W = 540;
final float MNG_BOARD_H = 320;
final float MNG_BOARD_X = (CANVAS_W - MNG_BOARD_W) / 2;
final float MNG_BOARD_Y = 160;
final float MNG_STORE_W = 70;
final float MNG_PIT_SPACING = 66;
final float MNG_PIT_RADIUS = 28;
final float MNG_STORE_H = 260;

class MNGRenderer {
  MNGGame game;

  MNGRenderer(MNGGame game) {
    this.game = game;
  }

  // Pit center positions
  float pitX(int idx) {
    if (idx == 13) return MNG_BOARD_X + MNG_STORE_W / 2;
    if (idx == 6) return MNG_BOARD_X + MNG_BOARD_W - MNG_STORE_W / 2;
    float startX = MNG_BOARD_X + MNG_STORE_W + 30;
    if (idx >= 0 && idx <= 5) {
      return startX + idx * MNG_PIT_SPACING;
    }
    // idx 7-12: top row, right to left → 12 is leftmost, 7 is rightmost
    return startX + (12 - idx) * MNG_PIT_SPACING;
  }

  float pitY(int idx) {
    if (idx == 13 || idx == 6) return MNG_BOARD_Y + MNG_BOARD_H / 2;
    if (idx >= 0 && idx <= 5) return MNG_BOARD_Y + MNG_BOARD_H - 55;
    return MNG_BOARD_Y + 55;
  }

  int getPitAtMouse() {
    for (int i = 0; i < 14; i++) {
      if (i == 6 || i == 13) continue;
      float px = pitX(i);
      float py = pitY(i);
      if (dist(mouseX, mouseY, px, py) < MNG_PIT_RADIUS + 4) {
        return i;
      }
    }
    return -1;
  }

  // Drawing

  void drawGame() {
    background(MNG_COLOR_BG);
    drawTopBar();
    drawBoard();
    drawStores();
    drawPits();
    drawStones();
    drawHover();
    if (game.state == MNG_GAMEOVER) drawGameOverUI();
    drawParticles(game.particles);
  }

  void drawTopBar() {
    textAlign(CENTER, CENTER);

    if (game.state == MNG_GAMEOVER) return;

    String label;
    color c;
    if (game.board.currentPlayer == 1) {
      label = "Player 1's Turn";
      c = MNG_COLOR_P1;
    } else {
      label = "Player 2's Turn";
      c = MNG_COLOR_P2;
    }
    if (game.mode == MNG_AI_MODE && game.board.currentPlayer == 2) {
      label = "AI Thinking...";
    }

    textSize(22);
    fill(c);
    text(label, CANVAS_W / 2, 30);

    // Scores
    textSize(16);
    fill(MNG_COLOR_P1);
    text("P1: " + game.board.pits[6], 80, 55);
    fill(MNG_COLOR_P2);
    text("P2: " + game.board.pits[13], CANVAS_W - 80, 55);

    // Extra turn indicator
    if (game.extraTurn && millis() - game.extraTurnTime < 2000) {
      float alpha = 255;
      if (millis() - game.extraTurnTime > 1500) {
        alpha = map(millis() - game.extraTurnTime, 1500, 2000, 255, 0);
      }
      textSize(18);
      fill(MNG_COLOR_SELECT, alpha);
      text("Extra Turn!", CANVAS_W / 2, 60);
    }
  }

  void drawBoard() {
    noStroke();
    fill(MNG_COLOR_BOARD);
    rect(MNG_BOARD_X, MNG_BOARD_Y, MNG_BOARD_W, MNG_BOARD_H, 30);

    // Decorative border
    noFill();
    stroke(80, 50, 20);
    strokeWeight(3);
    rect(MNG_BOARD_X, MNG_BOARD_Y, MNG_BOARD_W, MNG_BOARD_H, 30);

    // Inner decorative line
    stroke(120, 80, 40, 80);
    strokeWeight(1);
    rect(MNG_BOARD_X + 6, MNG_BOARD_Y + 6, MNG_BOARD_W - 12, MNG_BOARD_H - 12, 26);
  }

  void drawStores() {
    // P2 store (left, index 13)
    drawStore(pitX(13), MNG_BOARD_Y + (MNG_BOARD_H - MNG_STORE_H) / 2,
              MNG_STORE_W - 10, MNG_STORE_H, game.board.pits[13], MNG_COLOR_P2);

    // P1 store (right, index 6)
    drawStore(pitX(6), MNG_BOARD_Y + (MNG_BOARD_H - MNG_STORE_H) / 2,
              MNG_STORE_W - 10, MNG_STORE_H, game.board.pits[6], MNG_COLOR_P1);
  }

  void drawStore(float cx, float y, float w, float h, int count, color accent) {
    noStroke();
    fill(MNG_COLOR_PIT);
    rect(cx - w / 2, y, w, h, 25);

    // Inner shadow
    fill(50, 30, 10, 40);
    rect(cx - w / 2 + 3, y + 3, w - 6, h - 6, 22);

    // Stone count
    textAlign(CENTER, CENTER);
    textSize(28);
    fill(accent);
    text(count, cx, y + h / 2);
  }

  void drawPits() {
    for (int i = 0; i < 14; i++) {
      if (i == 6 || i == 13) continue;
      float px = pitX(i);
      float py = pitY(i);

      noStroke();
      fill(MNG_COLOR_PIT);
      ellipse(px, py, MNG_PIT_RADIUS * 2, MNG_PIT_RADIUS * 2);

      // Inner shadow
      fill(50, 30, 10, 50);
      ellipse(px + 1, py + 1, MNG_PIT_RADIUS * 1.7, MNG_PIT_RADIUS * 1.7);

      // Player indicator (subtle line under pits)
      if (i >= 0 && i <= 5) {
        stroke(MNG_COLOR_P1, 60);
      } else {
        stroke(MNG_COLOR_P2, 60);
      }
      strokeWeight(2);
      noFill();
      arc(px, py, MNG_PIT_RADIUS * 2 + 6, MNG_PIT_RADIUS * 2 + 6, PI * 0.8, PI * 1.2);
      if (i >= 7 && i <= 12) {
        arc(px, py, MNG_PIT_RADIUS * 2 + 6, MNG_PIT_RADIUS * 2 + 6, -PI * 0.2, PI * 0.2);
      }
    }
  }

  void drawStones() {
    for (int i = 0; i < 14; i++) {
      if (i == 6 || i == 13) continue;
      int count = game.board.pits[i];
      if (count == 0) continue;

      float px = pitX(i);
      float py = pitY(i);

      if (count <= 8) {
        drawStoneCircles(px, py, count, MNG_PIT_RADIUS * 0.6);
      } else {
        drawStoneCircles(px, py, 8, MNG_PIT_RADIUS * 0.6);
      }

      // Count label
      textAlign(CENTER, CENTER);
      textSize(13);
      fill(255);
      text(count, px, py);
    }
  }

  void drawStoneCircles(float cx, float cy, int count, float radius) {
    for (int i = 0; i < count; i++) {
      float angle = TWO_PI * i / count - HALF_PI;
      float sx = cx + cos(angle) * radius;
      float sy = cy + sin(angle) * radius;
      noStroke();
      fill(MNG_COLOR_STONE_BASE);
      ellipse(sx, sy, 10, 10);
      fill(200, 185, 170);
      ellipse(sx - 1, sy - 1, 6, 6);
    }
  }

  void drawHover() {
    if (game.state != MNG_PLAYING) return;
    if (game.animating) return;
    if (game.mode == MNG_AI_MODE && game.board.currentPlayer == 2) return;

    int hovered = getPitAtMouse();
    if (hovered == -1) return;
    if (!game.board.isValidMove(hovered, game.board.currentPlayer)) return;

    float px = pitX(hovered);
    float py = pitY(hovered);

    noFill();
    stroke(MNG_COLOR_SELECT, 180);
    strokeWeight(3);
    ellipse(px, py, MNG_PIT_RADIUS * 2 + 8, MNG_PIT_RADIUS * 2 + 8);

    // Cursor hand effect: slightly brighter pit
    fill(MNG_COLOR_SELECT, 30);
    noStroke();
    ellipse(px, py, MNG_PIT_RADIUS * 2, MNG_PIT_RADIUS * 2);
  }

  void drawGameOverUI() {
    // Overlay
    noStroke();
    fill(0, 0, 0, 120);
    rect(0, 0, CANVAS_W, MNG_TOP_BAR + 20);

    String msg;
    color c;
    if (game.winner == 3) {
      msg = "Draw!";
      c = color(180);
    } else if (game.winner == 1) {
      msg = "Player 1 Wins!";
      c = MNG_COLOR_P1;
    } else {
      msg = (game.mode == MNG_AI_MODE) ? "AI Wins!" : "Player 2 Wins!";
      c = MNG_COLOR_P2;
    }

    textAlign(CENTER, CENTER);
    textSize(32);
    fill(c);
    text(msg, CANVAS_W / 2, 30);

    // Final scores
    textSize(18);
    fill(MNG_COLOR_P1);
    text("P1: " + game.board.pits[6], 150, 60);
    fill(MNG_COLOR_P2);
    text("P2: " + game.board.pits[13], CANVAS_W - 150, 60);

    float elapsed = (millis() - game.gameOverTime) / 1000.0;
    if (elapsed > 1.0) {
      drawButton(CANVAS_W / 2 - 110, 660, "Restart", MNG_COLOR_SELECT);
      drawButton(CANVAS_W / 2 + 110, 660, "Menu", color(120));
    }
  }

  // Menu

  void drawMenu() {
    background(MNG_COLOR_BG);

    // Decorative stones
    for (int i = 0; i < 16; i++) {
      float x = noise(i * 10 + millis() * 0.0002) * CANVAS_W;
      float y = noise(i * 20 + 500 + millis() * 0.0002) * CANVAS_H;
      noStroke();
      fill(MNG_COLOR_STONE_BASE, 40);
      ellipse(x, y, 14, 14);
      fill(200, 185, 170, 30);
      ellipse(x - 1, y - 1, 8, 8);
    }

    // Title
    float bounce = sin(millis() * 0.003) * 8;
    textAlign(CENTER, CENTER);
    textSize(56);
    fill(255);
    text("MANGALA", CANVAS_W / 2, 180 + bounce);

    textSize(16);
    fill(200, 180, 150);
    text("Turkish Mancala", CANVAS_W / 2, 230);

    drawButton(CANVAS_W / 2, 330, "2 Players", MNG_COLOR_SELECT);
    drawButton(CANVAS_W / 2, 400, "vs AI", MNG_COLOR_P2);
    drawButton(CANVAS_W / 2, 470, "How to Play", color(241, 196, 15));
    drawButton(CANVAS_W / 2, 540, "Back", color(120));
  }

  // How to Play

  void drawHowTo(int page) {
    drawHowToFrame("Mangala — How to Play", page, 3, color(205, 133, 63));

    switch (page) {
      case 0: drawHowToPage0(); break;
      case 1: drawHowToPage1(); break;
      case 2: drawHowToPage2(); break;
    }
  }

  void drawHowToPage0() {
    drawHowToSubtitle("The Board", 85);

    float cx = CANVAS_W / 2;
    float cy = 230;
    float pitR = 22;
    float spacing = 55;
    float storeW = 35, storeH = 110;

    // Board background
    noStroke();
    fill(MNG_COLOR_BOARD);
    rect(cx - 200, cy - 65, 400, 130, 20);

    // P1 store (right)
    fill(MNG_COLOR_PIT);
    rect(cx + 140, cy - storeH / 2, storeW, storeH, 16);
    // P2 store (left)
    rect(cx - 175, cy - storeH / 2, storeW, storeH, 16);

    // Bottom row (P1 pits, 0-5)
    for (int i = 0; i < 6; i++) {
      float px = cx - 120 + i * spacing;
      float py = cy + 28;
      noStroke();
      fill(MNG_COLOR_PIT);
      ellipse(px, py, pitR * 2, pitR * 2);
      fill(255);
      textAlign(CENTER, CENTER);
      textSize(11);
      text("4", px, py);
    }

    // Top row (P2 pits, 7-12)
    for (int i = 0; i < 6; i++) {
      float px = cx - 120 + i * spacing;
      float py = cy - 28;
      noStroke();
      fill(MNG_COLOR_PIT);
      ellipse(px, py, pitR * 2, pitR * 2);
      fill(255);
      textAlign(CENTER, CENTER);
      textSize(11);
      text("4", px, py);
    }

    // Labels
    textSize(12);
    fill(MNG_COLOR_P1);
    text("P1 Pits", cx, cy + 65);
    text("P1 Store", cx + 157, cy + 70);
    fill(MNG_COLOR_P2);
    text("P2 Pits", cx, cy - 65);
    text("P2 Store", cx - 157, cy + 70);

    drawHowToBullet("Each player has 6 pits and 1 store.", 80, 380);
    drawHowToBullet("Each pit starts with 4 stones (48 total).", 80, 410);
  }

  void drawHowToPage1() {
    drawHowToSubtitle("Sowing", 85);

    float cx = CANVAS_W / 2;
    float cy = 210;
    float pitR = 20;
    float spacing = 50;

    // Simplified board - just bottom row + store
    noStroke();
    fill(MNG_COLOR_BOARD);
    rect(cx - 180, cy - 40, 360, 80, 16);

    // Pits — show "before → after" of sowing from pit 0 (had 4 stones)
    // After sow: pit0=1(stays), pit1+1, pit2+1, pit3+1
    int[] afterVals = {1, 6, 6, 6, 5, 5};
    float[] pitXs = new float[6];
    for (int i = 0; i < 6; i++) {
      pitXs[i] = cx - 120 + i * spacing;
      noStroke();
      fill(i == 0 ? color(46, 204, 113, 120) : (i <= 3 ? color(241, 196, 15, 80) : MNG_COLOR_PIT));
      ellipse(pitXs[i], cy, pitR * 2, pitR * 2);
      fill(255);
      textAlign(CENTER, CENTER);
      textSize(12);
      text(afterVals[i], pitXs[i], cy);
    }

    // Store
    fill(MNG_COLOR_PIT);
    rect(cx + 145, cy - 35, 30, 70, 12);

    // Arrows from pit 0 to pits 1-3
    stroke(241, 196, 15);
    strokeWeight(2);
    noFill();
    for (int i = 0; i < 3; i++) {
      float x1 = pitXs[i] + pitR + 3;
      float x2 = pitXs[i + 1] - pitR - 3;
      line(x1, cy - 8, x2, cy - 8);
      line(x2, cy - 8, x2 - 5, cy - 13);
      line(x2, cy - 8, x2 - 5, cy - 3);
    }

    drawHowToBullet("One stone stays in the picked pit, rest go right.", 60, 320);
    drawHowToBullet("Single stone? Just move it to the next pit. Turn ends.", 60, 350);
    drawHowToBullet("Skip opponent's store, but drop in your own.", 60, 380);
    drawHowToBullet("Last stone in your store = extra turn!", 60, 410);
  }

  void drawHowToPage2() {
    drawHowToSubtitle("Capture & Winning", 85);

    float cx = CANVAS_W / 2;
    float cy = 210;
    float pitR = 20;
    float spacing = 50;

    // Show bottom row
    noStroke();
    fill(MNG_COLOR_BOARD);
    rect(cx - 180, cy - 55, 360, 110, 16);

    // Bottom pits (P1)
    float[] vals = {0, 3, 2, 0, 1, 5};
    for (int i = 0; i < 6; i++) {
      float px = cx - 120 + i * spacing;
      noStroke();
      fill(i == 3 ? color(46, 204, 113, 120) : MNG_COLOR_PIT);
      ellipse(px, cy + 20, pitR * 2, pitR * 2);
      fill(255);
      textAlign(CENTER, CENTER);
      textSize(12);
      text(int(vals[i]), px, cy + 20);
    }

    // Top pits (P2) - opposite of pit 3 is pit 9 (index in top row = 3)
    float[] topVals = {2, 1, 4, 3, 0, 1};
    for (int i = 0; i < 6; i++) {
      float px = cx - 120 + i * spacing;
      noStroke();
      fill(i == 2 ? color(231, 76, 60, 120) : MNG_COLOR_PIT);
      ellipse(px, cy - 20, pitR * 2, pitR * 2);
      fill(255);
      textAlign(CENTER, CENTER);
      textSize(12);
      text(int(topVals[i]), px, cy - 20);
    }

    // Arrow from empty pit to opposite and to store
    float emptyX = cx - 120 + 3 * spacing;
    float oppX = cx - 120 + 2 * spacing;
    stroke(241, 196, 15);
    strokeWeight(2);
    // Arrow up from empty pit to opposite
    line(emptyX, cy + 2, oppX, cy - 5);
    line(oppX, cy - 5, oppX + 6, cy + 1);
    line(oppX, cy - 5, oppX - 4, cy + 3);

    // Store
    fill(MNG_COLOR_PIT);
    noStroke();
    rect(cx + 145, cy - 35, 30, 70, 12);
    // Arrow to store
    stroke(MNG_COLOR_P1);
    strokeWeight(2);
    line(oppX, cy - 25, cx + 140, cy - 25);
    line(cx + 140, cy - 25, cx + 133, cy - 30);
    line(cx + 140, cy - 25, cx + 133, cy - 20);

    textAlign(CENTER, CENTER);
    textSize(11);
    fill(MNG_COLOR_P1);
    text("Store", cx + 160, cy);

    drawHowToBullet("Last stone on opponent's side makes it even = capture all!", 60, 340);
    drawHowToBullet("Last stone in your empty pit = capture it + opposite stones.", 60, 370);
    drawHowToBullet("Empty your side first = win opponent's remaining stones!", 60, 400);
  }

  // Shared button

  void drawButton(float x, float y, String label, color c) {
    float bw = 200, bh = 50;
    boolean hover = mouseX > x - bw / 2 && mouseX < x + bw / 2 &&
                    mouseY > y - bh / 2 && mouseY < y + bh / 2;
    noStroke();
    fill(c, hover ? 200 : 120);
    rect(x - bw / 2, y - bh / 2, bw, bh, 8);
    textAlign(CENTER, CENTER);
    textSize(20);
    fill(255);
    text(label, x, y);
  }
}
