final color REV_COLOR_BG = color(20, 80, 40);
final color REV_COLOR_BOARD = color(0, 128, 55);
final color REV_COLOR_GRID = color(0, 90, 38);
final color REV_COLOR_BLACK = color(20, 20, 20);
final color REV_COLOR_WHITE = color(240, 240, 240);
final color REV_COLOR_VALID = color(255, 255, 255, 60);
final color REV_COLOR_LAST = color(241, 196, 15, 100);

final int REV_CELL_SIZE = 66;
final int REV_BOARD_PX = REV_CELL_SIZE * 8; // 528
final int REV_OFFSET_X = (CANVAS_W - REV_BOARD_PX) / 2;
final int REV_OFFSET_Y = 120;

class REVRenderer {
  REVGame game;

  REVRenderer(REVGame game) {
    this.game = game;
  }

  // Menu

  void drawMenu() {
    background(REV_COLOR_BG);

    // decorative discs
    for (int i = 0; i < 10; i++) {
      float x = noise(i * 13 + millis() * 0.0002) * CANVAS_W;
      float y = noise(i * 17 + 300 + millis() * 0.0002) * CANVAS_H;
      noStroke();
      if (i % 2 == 0) {
        fill(REV_COLOR_BLACK, 40);
      } else {
        fill(REV_COLOR_WHITE, 30);
      }
      ellipse(x, y, 40, 40);
    }

    float bounce = sin(millis() * 0.003) * 8;
    textAlign(CENTER, CENTER);
    textSize(56);
    fill(255);
    text("REVERSI", CANVAS_W / 2, 180 + bounce);

    textSize(16);
    fill(180);
    text("Othello", CANVAS_W / 2, 230);

    revDrawButton(CANVAS_W / 2, 330, "2 Players", color(46, 204, 113));
    revDrawButton(CANVAS_W / 2, 400, "vs AI", color(52, 152, 219));
    revDrawButton(CANVAS_W / 2, 470, "How to Play", color(0, 160, 70));
    revDrawButton(CANVAS_W / 2, 540, "Back", color(120));
  }

  // Game

  void drawGame() {
    background(REV_COLOR_BG);
    drawScoreBar();
    drawBoard();
    drawDiscs();
    drawValidMoves();
    drawLastMove();
    drawHover();
    drawPassMessage();
    drawParticles(game.particles);
  }

  void drawScoreBar() {
    int[] counts = game.board.countDiscs();
    textAlign(CENTER, CENTER);

    // black score (left)
    noStroke();
    fill(REV_COLOR_BLACK);
    ellipse(CANVAS_W / 2 - 120, 50, 32, 32);
    // highlight
    fill(60, 60, 60, 120);
    arc(CANVAS_W / 2 - 120, 50, 32, 32, -PI, 0);
    textSize(28);
    fill(255);
    text(counts[0], CANVAS_W / 2 - 75, 50);

    // white score (right)
    noStroke();
    fill(REV_COLOR_WHITE);
    ellipse(CANVAS_W / 2 + 75, 50, 32, 32);
    fill(200, 200, 200, 120);
    arc(CANVAS_W / 2 + 75, 50, 32, 32, -PI, 0);
    textSize(28);
    fill(255);
    text(counts[1], CANVAS_W / 2 + 120, 50);

    // vs separator
    textSize(16);
    fill(150);
    text("-", CANVAS_W / 2, 50);

    // current player or game over
    if (game.state == REV_GAMEOVER) {
      drawGameOverBar();
    } else {
      String label;
      if (game.mode == REV_AI_MODE && game.currentPlayer == 2) {
        label = "AI Thinking...";
      } else if (game.currentPlayer == 1) {
        label = "Black's Turn";
      } else {
        label = "White's Turn";
      }
      textSize(14);
      fill(200);
      text(label, CANVAS_W / 2, 90);
    }
  }

  void drawGameOverBar() {
    int[] counts = game.board.countDiscs();
    String msg;
    if (game.winner == 3) {
      msg = "Draw!  " + counts[0] + " - " + counts[1];
    } else if (game.winner == 1) {
      msg = "Black Wins!  " + counts[0] + " - " + counts[1];
    } else {
      msg = (game.mode == REV_AI_MODE) ? "AI Wins!  " : "White Wins!  ";
      msg += counts[0] + " - " + counts[1];
    }
    textSize(14);
    fill(241, 196, 15);
    text(msg, CANVAS_W / 2, 85);

    float elapsed = (millis() - game.gameOverTime) / 1000.0;
    if (elapsed > 1.0) {
      revDrawButton(CANVAS_W / 2 - 110, 105, "Restart", color(46, 204, 113));
      revDrawButton(CANVAS_W / 2 + 110, 105, "Menu", color(120));
    }
  }

  void drawBoard() {
    // board background
    noStroke();
    fill(REV_COLOR_BOARD);
    rect(REV_OFFSET_X, REV_OFFSET_Y, REV_BOARD_PX, REV_BOARD_PX, 4);

    // grid lines
    stroke(REV_COLOR_GRID);
    strokeWeight(2);
    for (int i = 0; i <= 8; i++) {
      int x = REV_OFFSET_X + i * REV_CELL_SIZE;
      line(x, REV_OFFSET_Y, x, REV_OFFSET_Y + REV_BOARD_PX);
      int y = REV_OFFSET_Y + i * REV_CELL_SIZE;
      line(REV_OFFSET_X, y, REV_OFFSET_X + REV_BOARD_PX, y);
    }

    // corner dots (standard Othello board markers)
    fill(REV_COLOR_GRID);
    noStroke();
    for (int dr = 2; dr <= 6; dr += 4) {
      for (int dc = 2; dc <= 6; dc += 4) {
        float cx = REV_OFFSET_X + dc * REV_CELL_SIZE;
        float cy = REV_OFFSET_Y + dr * REV_CELL_SIZE;
        ellipse(cx, cy, 8, 8);
      }
    }
  }

  void drawDiscs() {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        int val = game.board.grid[r][c];
        if (val == 0) continue;
        float cx = REV_OFFSET_X + c * REV_CELL_SIZE + REV_CELL_SIZE / 2.0;
        float cy = REV_OFFSET_Y + r * REV_CELL_SIZE + REV_CELL_SIZE / 2.0;
        float discSize = REV_CELL_SIZE * 0.8;

        int flipIdx = game.getFlipIndex(r, c);
        if (flipIdx >= 0 && game.flipAnimating) {
          float p = game.getFlipProgress(flipIdx);
          drawFlippingDisc(cx, cy, discSize, p, game.flipOldPlayer, val);
        } else {
          drawDisc(cx, cy, discSize, val);
        }
      }
    }
  }

  void drawDisc(float cx, float cy, float sz, int player) {
    drawDisc3D(cx, cy, sz, sz, player);
  }

  void drawDisc3D(float cx, float cy, float w, float h, int player) {
    float thickness = 5;
    noStroke();

    // Drop shadow
    fill(0, 50);
    ellipse(cx + 2, cy + 3, w, h);

    // Side edge (thickness) — draw from bottom up
    color baseCol = (player == 1) ? color(10, 10, 10) : color(200, 200, 200);
    color darkEdge = (player == 1) ? color(5, 5, 5) : color(170, 170, 170);
    for (int i = (int)thickness; i >= 0; i--) {
      float t = i / thickness;
      fill(lerpColor(darkEdge, baseCol, t));
      ellipse(cx, cy + i, w, h);
    }

    // Top face base
    color topCol = (player == 1) ? REV_COLOR_BLACK : REV_COLOR_WHITE;
    fill(topCol);
    ellipse(cx, cy, w, h);

    // Radial gradient layers for dome effect (light from top-left)
    int layers = 5;
    for (int i = layers; i >= 1; i--) {
      float ratio = i / (float)layers;
      float layerW = w * 0.7 * ratio;
      float layerH = h * 0.7 * ratio;
      float offX = -w * 0.12 * (1 - ratio);
      float offY = -h * 0.12 * (1 - ratio);
      if (player == 1) {
        fill(55 + (int)(25 * (1 - ratio)), 55 + (int)(25 * (1 - ratio)), 55 + (int)(25 * (1 - ratio)), 60);
      } else {
        fill(255, 255, 255, (int)(40 + 50 * (1 - ratio)));
      }
      ellipse(cx + offX, cy + offY, layerW, layerH);
    }

    // Specular highlight — small bright spot top-left
    float specX = cx - w * 0.18;
    float specY = cy - h * 0.18;
    float specSz = min(w, h) * 0.22;
    if (player == 1) {
      fill(120, 120, 120, 100);
    } else {
      fill(255, 255, 255, 200);
    }
    ellipse(specX, specY, specSz, specSz * 0.7);

    // Rim light — subtle bright arc on bottom-right edge
    noFill();
    if (player == 1) {
      stroke(80, 80, 80, 60);
    } else {
      stroke(255, 255, 255, 80);
    }
    strokeWeight(1.5);
    arc(cx, cy, w - 2, h - 2, PI * 0.1, PI * 0.7);
    noStroke();
  }

  void drawFlippingDisc(float cx, float cy, float sz, float progress, int oldPlayer, int newPlayer) {
    float scaleX;
    int drawPlayer;
    if (progress < 0.5) {
      scaleX = 1.0 - progress * 2;
      drawPlayer = oldPlayer;
    } else {
      scaleX = (progress - 0.5) * 2;
      drawPlayer = newPlayer;
    }
    scaleX = scaleX * scaleX * (3 - 2 * scaleX); // smoothstep

    float w = sz * max(scaleX, 0.05);
    float h = sz;
    drawDisc3D(cx, cy, w, h, drawPlayer);
  }

  void drawValidMoves() {
    if (game.state != REV_PLAYING) return;
    if (game.mode == REV_AI_MODE && game.currentPlayer == 2) return;

    ArrayList<int[]> moves = game.board.getValidMoves(game.currentPlayer);
    noStroke();
    fill(REV_COLOR_VALID);
    for (int[] m : moves) {
      float cx = REV_OFFSET_X + m[1] * REV_CELL_SIZE + REV_CELL_SIZE / 2.0;
      float cy = REV_OFFSET_Y + m[0] * REV_CELL_SIZE + REV_CELL_SIZE / 2.0;
      ellipse(cx, cy, 14, 14);
    }
  }

  void drawLastMove() {
    if (game.lastMoveRow < 0 || game.lastMoveCol < 0) return;
    float x = REV_OFFSET_X + game.lastMoveCol * REV_CELL_SIZE;
    float y = REV_OFFSET_Y + game.lastMoveRow * REV_CELL_SIZE;
    noStroke();
    fill(REV_COLOR_LAST);
    rect(x + 2, y + 2, REV_CELL_SIZE - 4, REV_CELL_SIZE - 4, 2);
  }

  void drawHover() {
    if (game.state != REV_PLAYING) return;
    if (game.mode == REV_AI_MODE && game.currentPlayer == 2) return;

    int[] cell = getCellUnderMouse();
    if (cell == null) return;
    if (game.board.getFlips(cell[0], cell[1], game.currentPlayer).size() == 0) return;

    float x = REV_OFFSET_X + cell[1] * REV_CELL_SIZE;
    float y = REV_OFFSET_Y + cell[0] * REV_CELL_SIZE;
    noStroke();
    fill(255, 255, 255, 30);
    rect(x + 1, y + 1, REV_CELL_SIZE - 2, REV_CELL_SIZE - 2, 2);
  }

  void drawPassMessage() {
    if (game.passMessageTime > 0) {
      float elapsed = (millis() - game.passMessageTime) / 1000.0;
      if (elapsed < 1.5) {
        float alpha = elapsed < 1.0 ? 255 : map(elapsed, 1.0, 1.5, 255, 0);
        textAlign(CENTER, CENTER);
        textSize(20);
        fill(241, 196, 15, alpha);
        String who = game.passedPlayer == 1 ? "Black" : "White";
        if (game.mode == REV_AI_MODE && game.passedPlayer == 2) who = "AI";
        text(who + " passed - no valid moves", CANVAS_W / 2, REV_OFFSET_Y + REV_BOARD_PX + 25);
      }
    }
  }

  int[] getCellUnderMouse() {
    if (mouseX < REV_OFFSET_X || mouseX > REV_OFFSET_X + REV_BOARD_PX) return null;
    if (mouseY < REV_OFFSET_Y || mouseY > REV_OFFSET_Y + REV_BOARD_PX) return null;
    int col = (mouseX - REV_OFFSET_X) / REV_CELL_SIZE;
    int row = (mouseY - REV_OFFSET_Y) / REV_CELL_SIZE;
    if (row < 0 || row > 7 || col < 0 || col > 7) return null;
    return new int[]{row, col};
  }

  void drawHowTo(int page) {
    color accent = color(0, 160, 70);
    drawHowToFrame("REVERSI - How to Play", page, 3, accent);

    if (page == 0) {
      drawHowToSubtitle("The Board", 90);

      // Mini 8x8 green grid
      float gx = CANVAS_W / 2 - 100;
      float gy = 140;
      float cs = 25;
      noStroke();
      fill(0, 128, 55);
      rect(gx, gy, cs * 8, cs * 8, 4);
      stroke(0, 90, 38);
      strokeWeight(1);
      for (int i = 0; i <= 8; i++) {
        line(gx + i * cs, gy, gx + i * cs, gy + cs * 8);
        line(gx, gy + i * cs, gx + cs * 8, gy + i * cs);
      }
      // Center 4 discs: (3,3)=W, (3,4)=B, (4,3)=B, (4,4)=W
      noStroke();
      fill(240); ellipse(gx + 3 * cs + cs / 2, gy + 3 * cs + cs / 2, cs * 0.7, cs * 0.7);
      fill(20);  ellipse(gx + 4 * cs + cs / 2, gy + 3 * cs + cs / 2, cs * 0.7, cs * 0.7);
      fill(20);  ellipse(gx + 3 * cs + cs / 2, gy + 4 * cs + cs / 2, cs * 0.7, cs * 0.7);
      fill(240); ellipse(gx + 4 * cs + cs / 2, gy + 4 * cs + cs / 2, cs * 0.7, cs * 0.7);

      drawHowToText("8x8 board. Black goes first.", gy + cs * 8 + 30);
      drawHowToText("Center starts with 2 black and 2 white discs.", gy + cs * 8 + 55);

    } else if (page == 1) {
      drawHowToSubtitle("Flipping Discs", 90);

      // Example: black at left, whites in middle, black placed at right
      float ey = 200;
      float ex = CANVAS_W / 2 - 100;
      float cs = 40;
      // Row of cells
      noStroke();
      fill(0, 128, 55);
      rect(ex, ey, cs * 5, cs, 4);
      stroke(0, 90, 38); strokeWeight(1);
      for (int i = 0; i <= 5; i++) line(ex + i * cs, ey, ex + i * cs, ey + cs);
      line(ex, ey, ex + cs * 5, ey); line(ex, ey + cs, ex + cs * 5, ey + cs);

      noStroke();
      // Existing black disc
      fill(20); ellipse(ex + cs * 0.5, ey + cs * 0.5, cs * 0.7, cs * 0.7);
      // White discs to be flipped
      fill(240); ellipse(ex + cs * 1.5, ey + cs * 0.5, cs * 0.7, cs * 0.7);
      fill(240); ellipse(ex + cs * 2.5, ey + cs * 0.5, cs * 0.7, cs * 0.7);
      // New black disc placed
      fill(20); ellipse(ex + cs * 3.5, ey + cs * 0.5, cs * 0.7, cs * 0.7);
      // Star marker on new disc
      fill(241, 196, 15); textAlign(CENTER, CENTER); textSize(12);
      text("NEW", ex + cs * 3.5, ey + cs + 14);

      // Arrows showing flip direction
      stroke(241, 196, 15); strokeWeight(2);
      line(ex + cs * 3.2, ey + cs * 0.5, ex + cs * 1.8, ey + cs * 0.5);
      // arrowhead
      line(ex + cs * 1.8, ey + cs * 0.5, ex + cs * 2.0, ey + cs * 0.35);
      line(ex + cs * 1.8, ey + cs * 0.5, ex + cs * 2.0, ey + cs * 0.65);

      // Result row
      float ry = ey + 80;
      noStroke();
      fill(0, 128, 55);
      rect(ex, ry, cs * 5, cs, 4);
      stroke(0, 90, 38); strokeWeight(1);
      for (int i = 0; i <= 5; i++) line(ex + i * cs, ry, ex + i * cs, ry + cs);
      line(ex, ry, ex + cs * 5, ry); line(ex, ry + cs, ex + cs * 5, ry + cs);
      noStroke();
      fill(20); ellipse(ex + cs * 0.5, ry + cs * 0.5, cs * 0.7, cs * 0.7);
      fill(20); ellipse(ex + cs * 1.5, ry + cs * 0.5, cs * 0.7, cs * 0.7);
      fill(20); ellipse(ex + cs * 2.5, ry + cs * 0.5, cs * 0.7, cs * 0.7);
      fill(20); ellipse(ex + cs * 3.5, ry + cs * 0.5, cs * 0.7, cs * 0.7);

      textAlign(CENTER, CENTER); textSize(12); fill(150);
      text("Flipped!", ex + cs * 2.5, ry + cs + 14);

      drawHowToBullet("Place a disc to sandwich opponent's discs.", 100, ry + cs + 55);
      drawHowToBullet("Sandwiched discs flip to your color.", 100, ry + cs + 80);
      drawHowToBullet("Must flip at least 1 disc (horizontal, vertical, or diagonal).", 100, ry + cs + 105);

    } else if (page == 2) {
      drawHowToSubtitle("Winning", 90);

      // Mini board mostly filled
      float gx = CANVAS_W / 2 - 80;
      float gy = 140;
      float cs = 20;
      noStroke();
      fill(0, 128, 55);
      rect(gx, gy, cs * 8, cs * 8, 4);
      stroke(0, 90, 38); strokeWeight(1);
      for (int i = 0; i <= 8; i++) {
        line(gx + i * cs, gy, gx + i * cs, gy + cs * 8);
        line(gx, gy + i * cs, gx + cs * 8, gy + i * cs);
      }
      noStroke();
      // Fill most cells with discs
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          if (r == 7 && c > 5) continue; // leave a few empty
          int player = ((r + c) % 3 == 0) ? 2 : 1;
          fill(player == 1 ? 20 : 240);
          ellipse(gx + c * cs + cs / 2, gy + r * cs + cs / 2, cs * 0.7, cs * 0.7);
        }
      }

      drawHowToText("No valid move? Your turn is skipped.", gy + cs * 8 + 30);
      drawHowToText("Game ends when neither player can move.", gy + cs * 8 + 55);
      drawHowToText("Most discs on the board wins!", gy + cs * 8 + 80);
    }
  }

  void revDrawButton(float x, float y, String label, color c) {
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
