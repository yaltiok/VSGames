final color HEX_COLOR_BG = color(30, 25, 35);
final color HEX_COLOR_CELL = color(200, 200, 210);
final color HEX_COLOR_BORDER = color(100, 100, 110);
final color HEX_COLOR_P1 = color(220, 50, 50);
final color HEX_COLOR_P2 = color(50, 100, 220);
final color HEX_COLOR_EDGE_P1 = color(220, 50, 50, 80);
final color HEX_COLOR_EDGE_P2 = color(50, 100, 220, 80);
final color HEX_COLOR_WIN = color(255, 220, 50);
final color HEX_COLOR_HOVER = color(150, 150, 160, 120);

final float HEX_SIZE = 20;

class HEXRenderer {
  HEXGame game;
  float hexW, hexH;
  float offsetX, offsetY;

  HEXRenderer(HEXGame game) {
    this.game = game;
    hexW = sqrt(3) * HEX_SIZE;
    hexH = 2 * HEX_SIZE;
    float totalW = HEX_BOARD_SIZE * hexW + (HEX_BOARD_SIZE - 1) * hexW * 0.5;
    float totalH = HEX_BOARD_SIZE * hexH * 0.75 + hexH * 0.25;
    offsetX = (CANVAS_W - totalW) / 2 + hexW / 2;
    offsetY = (CANVAS_H - totalH) / 2 + hexH / 2 + 30;
  }

  float hexCenterX(int row, int col) {
    return offsetX + col * hexW + row * hexW * 0.5;
  }

  float hexCenterY(int row, int col) {
    return offsetY + row * hexH * 0.75;
  }

  void hexDrawHexagon(float cx, float cy, float size) {
    beginShape();
    for (int i = 0; i < 6; i++) {
      float angle = PI / 6 + i * PI / 3;
      vertex(cx + size * cos(angle), cy + size * sin(angle));
    }
    endShape(CLOSE);
  }

  int[] pixelToHex(float px, float py) {
    float bestDist = 999999;
    int bestR = -1, bestC = -1;
    for (int r = 0; r < HEX_BOARD_SIZE; r++) {
      for (int c = 0; c < HEX_BOARD_SIZE; c++) {
        float cx = hexCenterX(r, c);
        float cy = hexCenterY(r, c);
        float d = dist(px, py, cx, cy);
        if (d < bestDist && d < HEX_SIZE) {
          bestDist = d;
          bestR = r;
          bestC = c;
        }
      }
    }
    if (bestR == -1) return null;
    return new int[] {bestR, bestC};
  }

  // Game drawing

  void drawGame() {
    background(HEX_COLOR_BG);
    drawTopBar();
    drawEdgeIndicators();
    drawBoard();
    drawStones();
    drawWinPath();
    drawHover();
    drawLastMove();
    drawParticles(game.particles);
  }

  void drawTopBar() {
    textAlign(CENTER, CENTER);

    if (game.state == HEX_GAMEOVER) {
      drawGameOverUI();
      return;
    }

    textSize(20);
    String label;
    color c;
    if (game.currentPlayer == 1) {
      label = "Red's Turn";
      c = HEX_COLOR_P1;
    } else {
      label = "Blue's Turn";
      c = HEX_COLOR_P2;
    }
    if (game.mode == HEX_AI_MODE && game.currentPlayer == 2) {
      label = "AI Thinking...";
    }
    if (game.mode == HEX_ONLINE) {
      if (game.currentPlayer == game.playerRole) {
        label = "Your Turn (" + (game.playerRole == 1 ? "Red" : "Blue") + ")";
      } else {
        label = "Opponent's Turn";
      }
    }
    fill(c);
    text(label, CANVAS_W / 2, 30);

    // Player legend
    textSize(12);
    fill(HEX_COLOR_P1);
    text("Red: Left-Right", CANVAS_W / 2 - 100, 55);
    fill(HEX_COLOR_P2);
    text("Blue: Top-Bottom", CANVAS_W / 2 + 100, 55);
  }

  void drawGameOverUI() {
    String msg;
    color c;
    if (game.mode == HEX_ONLINE) {
      if (game.winner == game.playerRole) {
        msg = "You Win!";
      } else {
        msg = "You Lose!";
      }
      c = (game.winner == 1) ? HEX_COLOR_P1 : HEX_COLOR_P2;
    } else if (game.winner == 1) {
      msg = "Red Wins!";
      c = HEX_COLOR_P1;
    } else {
      msg = (game.mode == HEX_AI_MODE) ? "AI Wins!" : "Blue Wins!";
      c = HEX_COLOR_P2;
    }
    textSize(24);
    fill(c);
    text(msg, CANVAS_W / 2, 20);

    float elapsed = (millis() - game.gameOverTime) / 1000.0;
    if (elapsed > 1.0) {
      hexDrawButton(CANVAS_W / 2 - 110, 45, "Restart", color(46, 204, 113));
      hexDrawButton(CANVAS_W / 2 + 110, 45, "Menu", color(180));
    }
  }

  void drawEdgeIndicators() {
    // Red edges (left and right)
    stroke(HEX_COLOR_EDGE_P1);
    strokeWeight(4);
    for (int r = 0; r < HEX_BOARD_SIZE; r++) {
      // Left edge
      float cx0 = hexCenterX(r, 0);
      float cy0 = hexCenterY(r, 0);
      float angle0 = PI / 6 + 3 * PI / 3;
      float angle1 = PI / 6 + 4 * PI / 3;
      float ax = cx0 + HEX_SIZE * cos(angle0);
      float ay = cy0 + HEX_SIZE * sin(angle0);
      float bx = cx0 + HEX_SIZE * cos(angle1);
      float by = cy0 + HEX_SIZE * sin(angle1);
      line(ax, ay, bx, by);

      // Right edge
      float cxR = hexCenterX(r, HEX_BOARD_SIZE - 1);
      float cyR = hexCenterY(r, HEX_BOARD_SIZE - 1);
      float angle2 = PI / 6 + 0 * PI / 3;
      float angle3 = PI / 6 + 5 * PI / 3;
      float ax2 = cxR + HEX_SIZE * cos(angle2);
      float ay2 = cyR + HEX_SIZE * sin(angle2);
      float bx2 = cxR + HEX_SIZE * cos(angle3);
      float by2 = cyR + HEX_SIZE * sin(angle3);
      line(ax2, ay2, bx2, by2);
    }

    // Blue edges (top and bottom)
    stroke(HEX_COLOR_EDGE_P2);
    strokeWeight(4);
    for (int c = 0; c < HEX_BOARD_SIZE; c++) {
      // Top edge
      float cxT = hexCenterX(0, c);
      float cyT = hexCenterY(0, c);
      float angle4 = PI / 6 + 4 * PI / 3;
      float angle5 = PI / 6 + 5 * PI / 3;
      float ax3 = cxT + HEX_SIZE * cos(angle4);
      float ay3 = cyT + HEX_SIZE * sin(angle4);
      float bx3 = cxT + HEX_SIZE * cos(angle5);
      float by3 = cyT + HEX_SIZE * sin(angle5);
      line(ax3, ay3, bx3, by3);

      // Bottom edge
      float cxB = hexCenterX(HEX_BOARD_SIZE - 1, c);
      float cyB = hexCenterY(HEX_BOARD_SIZE - 1, c);
      float angle6 = PI / 6 + 1 * PI / 3;
      float angle7 = PI / 6 + 2 * PI / 3;
      float ax4 = cxB + HEX_SIZE * cos(angle6);
      float ay4 = cyB + HEX_SIZE * sin(angle6);
      float bx4 = cxB + HEX_SIZE * cos(angle7);
      float by4 = cyB + HEX_SIZE * sin(angle7);
      line(ax4, ay4, bx4, by4);
    }
  }

  void drawBoard() {
    for (int r = 0; r < HEX_BOARD_SIZE; r++) {
      for (int c = 0; c < HEX_BOARD_SIZE; c++) {
        float cx = hexCenterX(r, c);
        float cy = hexCenterY(r, c);

        // Background color with edge tinting
        color fillC = HEX_COLOR_CELL;
        stroke(HEX_COLOR_BORDER);
        strokeWeight(1.5);
        fill(fillC);
        hexDrawHexagon(cx, cy, HEX_SIZE - 1);
      }
    }
  }

  void drawStones() {
    for (int r = 0; r < HEX_BOARD_SIZE; r++) {
      for (int c = 0; c < HEX_BOARD_SIZE; c++) {
        if (game.board.grid[r][c] == 0) continue;
        float cx = hexCenterX(r, c);
        float cy = hexCenterY(r, c);
        color stoneColor = (game.board.grid[r][c] == 1) ? HEX_COLOR_P1 : HEX_COLOR_P2;
        noStroke();
        fill(stoneColor);
        ellipse(cx, cy, HEX_SIZE * 1.2, HEX_SIZE * 1.2);

        // Inner highlight
        fill(255, 60);
        ellipse(cx - 2, cy - 2, HEX_SIZE * 0.5, HEX_SIZE * 0.5);
      }
    }
  }

  void drawWinPath() {
    if (game.winPath == null) return;
    float progress = constrain((millis() - game.gameOverTime) / 800.0, 0, 1);
    int count = (int)(game.winPath.length / 2 * progress);

    for (int i = 0; i < count; i++) {
      int r = game.winPath[i * 2];
      int c = game.winPath[i * 2 + 1];
      float cx = hexCenterX(r, c);
      float cy = hexCenterY(r, c);
      stroke(HEX_COLOR_WIN);
      strokeWeight(3);
      noFill();
      ellipse(cx, cy, HEX_SIZE * 1.6, HEX_SIZE * 1.6);
    }

    // Draw connecting lines between path cells
    for (int i = 0; i < count - 1; i++) {
      int r1 = game.winPath[i * 2];
      int c1 = game.winPath[i * 2 + 1];
      int r2 = game.winPath[(i + 1) * 2];
      int c2 = game.winPath[(i + 1) * 2 + 1];
      float cx1 = hexCenterX(r1, c1);
      float cy1 = hexCenterY(r1, c1);
      float cx2 = hexCenterX(r2, c2);
      float cy2 = hexCenterY(r2, c2);
      stroke(HEX_COLOR_WIN, 150);
      strokeWeight(2);
      line(cx1, cy1, cx2, cy2);
    }
  }

  void drawHover() {
    if (game.state != HEX_PLAYING) return;
    if (game.mode == HEX_AI_MODE && game.currentPlayer == 2) return;
    if (game.mode == HEX_ONLINE && game.currentPlayer != game.playerRole) return;

    int[] cell = pixelToHex(mouseX, mouseY);
    if (cell == null) return;
    if (game.board.grid[cell[0]][cell[1]] != 0) return;

    float cx = hexCenterX(cell[0], cell[1]);
    float cy = hexCenterY(cell[0], cell[1]);
    noStroke();
    fill(HEX_COLOR_HOVER);
    ellipse(cx, cy, HEX_SIZE * 1.2, HEX_SIZE * 1.2);

    // Ghost stone
    color ghostC = (game.currentPlayer == 1) ? HEX_COLOR_P1 : HEX_COLOR_P2;
    fill(ghostC, 80);
    ellipse(cx, cy, HEX_SIZE * 1.0, HEX_SIZE * 1.0);
  }

  void drawLastMove() {
    if (game.lastRow < 0 || game.lastCol < 0) return;
    float cx = hexCenterX(game.lastRow, game.lastCol);
    float cy = hexCenterY(game.lastRow, game.lastCol);
    stroke(255, 200);
    strokeWeight(2);
    noFill();
    ellipse(cx, cy, HEX_SIZE * 0.4, HEX_SIZE * 0.4);
  }

  // Menu

  void drawMenu() {
    background(HEX_COLOR_BG);

    // Decorative hexagons
    for (int i = 0; i < 10; i++) {
      float x = noise(i * 10 + millis() * 0.0003) * CANVAS_W;
      float y = noise(i * 20 + 500 + millis() * 0.0003) * CANVAS_H;
      stroke(140, 80, 200, 30);
      strokeWeight(1.5);
      noFill();
      hexDrawHexagon(x, y, 15);
    }

    float bounce = sin(millis() * 0.003) * 8;
    textAlign(CENTER, CENTER);
    textSize(56);
    fill(255);
    text("HEX", CANVAS_W / 2, 180 + bounce);

    textSize(16);
    fill(150);
    text("Connection Game", CANVAS_W / 2, 230);

    textSize(12);
    fill(HEX_COLOR_P1);
    text("Red connects Left-Right", CANVAS_W / 2, 270);
    fill(HEX_COLOR_P2);
    text("Blue connects Top-Bottom", CANVAS_W / 2, 290);

    // Disconnect message
    if (game.disconnectMessage.length() > 0) {
      float elapsed = (millis() - game.disconnectMessageTime) / 1000.0;
      if (elapsed < 3.0) {
        float alpha = elapsed < 2.0 ? 255 : map(elapsed, 2.0, 3.0, 255, 0);
        textSize(14);
        fill(HEX_COLOR_P1, alpha);
        text(game.disconnectMessage, CANVAS_W / 2, 252);
      } else {
        game.disconnectMessage = "";
      }
    }

    hexDrawButton(CANVAS_W / 2, 310, "2 Players", color(46, 204, 113));
    hexDrawButton(CANVAS_W / 2, 375, "vs AI", HEX_COLOR_P2);
    hexDrawButton(CANVAS_W / 2, 440, "Online", color(230, 126, 34));
    hexDrawButton(CANVAS_W / 2, 505, "How to Play", color(140, 80, 200));
    hexDrawButton(CANVAS_W / 2, 570, "Back", color(120));
  }

  void drawLobby() {
    background(HEX_COLOR_BG);
    drawLobbyUI(game.lobbyState, game.network, game.roomCode, color(140, 80, 200));
  }

  void drawHowTo(int page) {
    drawHowToFrame("Hex - How to Play", page, 2, color(140, 80, 200));

    if (page == 0) {
      drawHowToSubtitle("The Board", 90);

      // Draw a small 5x5 diamond of hexagons
      float miniSize = 14;
      float mHexW = sqrt(3) * miniSize;
      float mHexH = 2 * miniSize;
      int sz = 5;
      float baseX = CANVAS_W / 2 - (sz * mHexW + (sz - 1) * mHexW * 0.5) / 2 + mHexW / 2;
      float baseY = 180;

      // Draw edge colors first
      // Left/right edges = red
      for (int r = 0; r < sz; r++) {
        float lx = baseX + r * mHexW * 0.5;
        float ly = baseY + r * mHexH * 0.75;
        noStroke();
        fill(220, 50, 50, 80);
        ellipse(lx - mHexW * 0.6, ly, 8, 8);

        float rx = baseX + (sz - 1) * mHexW + r * mHexW * 0.5;
        float ry = ly;
        fill(220, 50, 50, 80);
        ellipse(rx + mHexW * 0.6, ry, 8, 8);
      }
      // Top/bottom edges = blue
      for (int c = 0; c < sz; c++) {
        float tx = baseX + c * mHexW;
        float ty = baseY - mHexH * 0.4;
        noStroke();
        fill(50, 100, 220, 80);
        ellipse(tx, ty, 8, 8);

        float bxp = baseX + c * mHexW + (sz - 1) * mHexW * 0.5;
        float byp = baseY + (sz - 1) * mHexH * 0.75 + mHexH * 0.4;
        fill(50, 100, 220, 80);
        ellipse(bxp, byp, 8, 8);
      }

      // Hexagons
      for (int r = 0; r < sz; r++) {
        for (int c = 0; c < sz; c++) {
          float hx = baseX + c * mHexW + r * mHexW * 0.5;
          float hy = baseY + r * mHexH * 0.75;
          stroke(100, 100, 110);
          strokeWeight(1.5);
          fill(200, 200, 210);
          hexDrawHexagon(hx, hy, miniSize - 1);
        }
      }

      // Edge indicator lines
      stroke(220, 50, 50);
      strokeWeight(3);
      float leftX1 = baseX - miniSize * 0.8;
      float leftY1 = baseY;
      float leftX2 = baseX + (sz - 1) * mHexW * 0.5 - miniSize * 0.8;
      float leftY2 = baseY + (sz - 1) * mHexH * 0.75;
      line(leftX1, leftY1, leftX2, leftY2);
      float rightX1 = baseX + (sz - 1) * mHexW + miniSize * 0.8;
      float rightY1 = baseY;
      float rightX2 = baseX + (sz - 1) * mHexW + (sz - 1) * mHexW * 0.5 + miniSize * 0.8;
      float rightY2 = baseY + (sz - 1) * mHexH * 0.75;
      line(rightX1, rightY1, rightX2, rightY2);

      stroke(50, 100, 220);
      strokeWeight(3);
      float topX1 = baseX;
      float topY1 = baseY - miniSize * 0.8;
      float topX2 = baseX + (sz - 1) * mHexW;
      float topY2 = baseY - miniSize * 0.8;
      line(topX1, topY1, topX2, topY2);
      float botX1 = baseX + (sz - 1) * mHexW * 0.5;
      float botY1 = baseY + (sz - 1) * mHexH * 0.75 + miniSize * 0.8;
      float botX2 = baseX + (sz - 1) * mHexW + (sz - 1) * mHexW * 0.5;
      float botY2 = baseY + (sz - 1) * mHexH * 0.75 + miniSize * 0.8;
      line(botX1, botY1, botX2, botY2);

      float ty = baseY + sz * mHexH * 0.75 + 40;
      drawHowToText("11x11 hexagonal grid.", ty);
      fill(220, 50, 50);
      textAlign(CENTER, CENTER);
      textSize(14);
      text("Red connects LEFT to RIGHT edges.", CANVAS_W / 2, ty + 28);
      fill(80, 130, 240);
      text("Blue connects TOP to BOTTOM edges.", CANVAS_W / 2, ty + 56);

    } else if (page == 1) {
      drawHowToSubtitle("How to Play", 90);

      // Small 5x5 hex grid with a connected path
      float miniSize = 14;
      float mHexW = sqrt(3) * miniSize;
      float mHexH = 2 * miniSize;
      int sz = 5;
      float baseX = CANVAS_W / 2 - (sz * mHexW + (sz - 1) * mHexW * 0.5) / 2 + mHexW / 2;
      float baseY = 170;

      // Draw all hexagons
      for (int r = 0; r < sz; r++) {
        for (int c = 0; c < sz; c++) {
          float hx = baseX + c * mHexW + r * mHexW * 0.5;
          float hy = baseY + r * mHexH * 0.75;
          stroke(100, 100, 110);
          strokeWeight(1.5);
          fill(200, 200, 210);
          hexDrawHexagon(hx, hy, miniSize - 1);
        }
      }

      // A connected red path from left to right: (2,0)->(1,1)->(2,2)->(3,2)->(3,3)->(2,4)
      int[][] path = {{2,0},{1,1},{2,2},{3,2},{3,3},{2,4}};
      // Draw path stones
      for (int[] p : path) {
        float hx = baseX + p[1] * mHexW + p[0] * mHexW * 0.5;
        float hy = baseY + p[0] * mHexH * 0.75;
        noStroke();
        fill(220, 50, 50);
        ellipse(hx, hy, miniSize * 1.2, miniSize * 1.2);
      }
      // Draw path connections
      stroke(255, 220, 50);
      strokeWeight(2.5);
      for (int i = 0; i < path.length - 1; i++) {
        float x1 = baseX + path[i][1] * mHexW + path[i][0] * mHexW * 0.5;
        float y1 = baseY + path[i][0] * mHexH * 0.75;
        float x2 = baseX + path[i+1][1] * mHexW + path[i+1][0] * mHexW * 0.5;
        float y2 = baseY + path[i+1][0] * mHexH * 0.75;
        line(x1, y1, x2, y2);
      }

      // A few blue stones scattered
      int[][] blues = {{0,2},{1,3},{4,1}};
      for (int[] b : blues) {
        float hx = baseX + b[1] * mHexW + b[0] * mHexW * 0.5;
        float hy = baseY + b[0] * mHexH * 0.75;
        noStroke();
        fill(50, 100, 220);
        ellipse(hx, hy, miniSize * 1.2, miniSize * 1.2);
      }

      float ty = baseY + sz * mHexH * 0.75 + 40;
      drawHowToText("Take turns placing stones on empty hexagons.", ty);
      drawHowToText("Create a continuous path between your two edges.", ty + 28);
      drawHowToText("There are NO draws - someone always wins!", ty + 56);
      drawHowToText("Each hex has 6 neighbors.", ty + 84);
    }
  }

  void hexDrawButton(float x, float y, String label, color c) {
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
