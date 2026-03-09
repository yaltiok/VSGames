final color DAB_COLOR_BG = color(20, 25, 50);
final color DAB_COLOR_DOT = color(220, 220, 230);
final color DAB_COLOR_LINE = color(180, 180, 200);
final color DAB_COLOR_P1 = color(231, 76, 60);
final color DAB_COLOR_P2 = color(52, 152, 219);
final color DAB_COLOR_HOVER = color(255, 255, 255, 80);
final color DAB_COLOR_LAST = color(46, 204, 113);

class DABRenderer {
  DABGame game;

  DABRenderer(DABGame game) {
    this.game = game;
  }

  void drawGame() {
    background(DAB_COLOR_BG);
    drawTopBar();
    drawBoxFills();
    drawLines();
    drawHoverLine();
    drawLastLine();
    drawDots();
    drawParticles(game.particles);
  }

  void drawTopBar() {
    textAlign(CENTER, CENTER);

    if (game.state == DAB_GAMEOVER) {
      drawGameOverUI();
      return;
    }

    // scores
    textSize(18);
    fill(DAB_COLOR_P1);
    text("P1: " + game.board.scores[1], 120, 35);
    fill(DAB_COLOR_P2);
    String p2Label = (game.mode == DAB_AI_MODE) ? "AI: " : "P2: ";
    text(p2Label + game.board.scores[2], CANVAS_W - 120, 35);

    // score boxes visual
    noStroke();
    fill(DAB_COLOR_P1, 60);
    rect(60, 50, 120, 6, 3);
    fill(DAB_COLOR_P1);
    float p1w = map(game.board.scores[1], 0, 16, 0, 120);
    rect(60, 50, p1w, 6, 3);

    fill(DAB_COLOR_P2, 60);
    rect(CANVAS_W - 180, 50, 120, 6, 3);
    fill(DAB_COLOR_P2);
    float p2w = map(game.board.scores[2], 0, 16, 0, 120);
    rect(CANVAS_W - 180, 50, p2w, 6, 3);

    // turn indicator
    textSize(16);
    String turnLabel;
    color turnColor;
    if (game.currentPlayer == 1) {
      turnLabel = "Player 1's Turn";
      turnColor = DAB_COLOR_P1;
    } else {
      if (game.mode == DAB_AI_MODE) {
        turnLabel = "AI Thinking...";
      } else {
        turnLabel = "Player 2's Turn";
      }
      turnColor = DAB_COLOR_P2;
    }
    if (game.mode == DAB_ONLINE) {
      if (game.currentPlayer == game.playerRole) {
        turnLabel = "Your Turn";
      } else {
        turnLabel = "Opponent's Turn";
      }
    }
    fill(turnColor);
    text(turnLabel, CANVAS_W / 2, 80);
  }

  void drawGameOverUI() {
    String msg;
    color c;
    if (game.winner == 3) {
      msg = "Draw!";
      c = color(180);
    } else if (game.mode == DAB_ONLINE) {
      if (game.winner == game.playerRole) {
        msg = "You Win!";
      } else {
        msg = "You Lose!";
      }
      c = (game.winner == 1) ? DAB_COLOR_P1 : DAB_COLOR_P2;
    } else if (game.winner == 1) {
      msg = "Player 1 Wins!";
      c = DAB_COLOR_P1;
    } else {
      msg = (game.mode == DAB_AI_MODE) ? "AI Wins!" : "Player 2 Wins!";
      c = DAB_COLOR_P2;
    }

    textSize(22);
    fill(c);
    text(msg, CANVAS_W / 2, 25);

    textSize(14);
    fill(200);
    text(game.board.scores[1] + " - " + game.board.scores[2], CANVAS_W / 2, 48);

    float elapsed = (millis() - game.gameOverTime) / 1000.0;
    if (elapsed > 1.0) {
      dabDrawButton(CANVAS_W / 2 - 110, 80, "Restart", DAB_COLOR_LAST);
      dabDrawButton(CANVAS_W / 2 + 110, 80, "Menu", color(120));
    }
  }

  void drawBoxFills() {
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (game.board.boxes[r][c] == 0) continue;
        float x = DAB_OFFSET_X + c * DAB_SPACING;
        float y = DAB_OFFSET_Y + r * DAB_SPACING;
        noStroke();
        if (game.board.boxes[r][c] == 1) {
          fill(DAB_COLOR_P1, 80);
        } else {
          fill(DAB_COLOR_P2, 80);
        }
        rect(x + 2, y + 2, DAB_SPACING - 4, DAB_SPACING - 4, 4);

        // player label
        textAlign(CENTER, CENTER);
        textSize(24);
        if (game.board.boxes[r][c] == 1) {
          fill(DAB_COLOR_P1, 180);
          text("1", x + DAB_SPACING / 2, y + DAB_SPACING / 2);
        } else {
          fill(DAB_COLOR_P2, 180);
          text(game.mode == DAB_AI_MODE ? "A" : "2", x + DAB_SPACING / 2, y + DAB_SPACING / 2);
        }
      }
    }
  }

  void drawLines() {
    strokeWeight(4);
    stroke(DAB_COLOR_LINE);

    // horizontal lines
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 4; c++) {
        if (!game.board.hLines[r][c]) continue;
        // skip last line — drawn separately
        if (game.lastLineType == 0 && game.lastLineRow == r && game.lastLineCol == c &&
            millis() - game.lastLineTime < 500) continue;
        float x1 = DAB_OFFSET_X + c * DAB_SPACING;
        float y = DAB_OFFSET_Y + r * DAB_SPACING;
        float x2 = x1 + DAB_SPACING;
        stroke(DAB_COLOR_LINE);
        line(x1, y, x2, y);
      }
    }

    // vertical lines
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 5; c++) {
        if (!game.board.vLines[r][c]) continue;
        if (game.lastLineType == 1 && game.lastLineRow == r && game.lastLineCol == c &&
            millis() - game.lastLineTime < 500) continue;
        float x = DAB_OFFSET_X + c * DAB_SPACING;
        float y1 = DAB_OFFSET_Y + r * DAB_SPACING;
        float y2 = y1 + DAB_SPACING;
        stroke(DAB_COLOR_LINE);
        line(x, y1, x, y2);
      }
    }
  }

  void drawLastLine() {
    if (game.lastLineType < 0) return;
    if (millis() - game.lastLineTime > 500) return;

    float alpha = map(millis() - game.lastLineTime, 0, 500, 255, 0);
    strokeWeight(5);

    if (game.lastLineType == 0) {
      float x1 = DAB_OFFSET_X + game.lastLineCol * DAB_SPACING;
      float y = DAB_OFFSET_Y + game.lastLineRow * DAB_SPACING;
      float x2 = x1 + DAB_SPACING;
      stroke(DAB_COLOR_LAST, alpha);
      line(x1, y, x2, y);
      // also draw normal on top
      strokeWeight(4);
      stroke(DAB_COLOR_LINE);
      line(x1, y, x2, y);
    } else {
      float x = DAB_OFFSET_X + game.lastLineCol * DAB_SPACING;
      float y1 = DAB_OFFSET_Y + game.lastLineRow * DAB_SPACING;
      float y2 = y1 + DAB_SPACING;
      stroke(DAB_COLOR_LAST, alpha);
      line(x, y1, x, y2);
      strokeWeight(4);
      stroke(DAB_COLOR_LINE);
      line(x, y1, x, y2);
    }
  }

  void drawHoverLine() {
    if (game.hoverType < 0) return;
    if (game.state != DAB_PLAYING) return;
    if (game.mode == DAB_ONLINE && game.currentPlayer != game.playerRole) return;

    strokeWeight(4);
    stroke(DAB_COLOR_HOVER);

    if (game.hoverType == 0) {
      float x1 = DAB_OFFSET_X + game.hoverCol * DAB_SPACING;
      float y = DAB_OFFSET_Y + game.hoverRow * DAB_SPACING;
      float x2 = x1 + DAB_SPACING;
      line(x1, y, x2, y);
    } else {
      float x = DAB_OFFSET_X + game.hoverCol * DAB_SPACING;
      float y1 = DAB_OFFSET_Y + game.hoverRow * DAB_SPACING;
      float y2 = y1 + DAB_SPACING;
      line(x, y1, x, y2);
    }
  }

  void drawDots() {
    noStroke();
    fill(DAB_COLOR_DOT);
    for (int r = 0; r < DAB_GRID_DOTS; r++) {
      for (int c = 0; c < DAB_GRID_DOTS; c++) {
        float x = DAB_OFFSET_X + c * DAB_SPACING;
        float y = DAB_OFFSET_Y + r * DAB_SPACING;
        ellipse(x, y, 8, 8);
      }
    }
  }

  void drawLobby() {
    background(DAB_COLOR_BG);
    drawLobbyUI(game.lobbyState, game.network, game.roomCode, DAB_COLOR_LAST);
  }

  // Menu

  void drawMenu() {
    background(DAB_COLOR_BG);

    // decorative dots and lines
    for (int i = 0; i < 10; i++) {
      float x = noise(i * 10 + millis() * 0.0003) * CANVAS_W;
      float y = noise(i * 20 + 500 + millis() * 0.0003) * CANVAS_H;
      noStroke();
      fill(DAB_COLOR_DOT, 30);
      ellipse(x, y, 6, 6);
      if (i < 8) {
        float x2 = noise(i * 10 + 100 + millis() * 0.0003) * CANVAS_W;
        float y2 = noise(i * 20 + 600 + millis() * 0.0003) * CANVAS_H;
        stroke(DAB_COLOR_LINE, 20);
        strokeWeight(2);
        line(x, y, x2, y2);
      }
    }

    float bounce = sin(millis() * 0.003) * 8;
    textAlign(CENTER, CENTER);
    textSize(52);
    fill(255);
    text("DOTS & BOXES", CANVAS_W / 2, 200 + bounce);

    textSize(16);
    fill(150);
    text("Nokta Cizgi", CANVAS_W / 2, 250);

    // Disconnect message
    if (game.disconnectMessage.length() > 0) {
      float elapsed = (millis() - game.disconnectMessageTime) / 1000.0;
      if (elapsed < 3.0) {
        float alpha = elapsed < 2.0 ? 255 : map(elapsed, 2.0, 3.0, 255, 0);
        textSize(16);
        fill(DAB_COLOR_P1, alpha);
        text(game.disconnectMessage, CANVAS_W / 2, 280);
      } else {
        game.disconnectMessage = "";
      }
    }

    dabDrawButton(CANVAS_W / 2, 310, "2 Players", DAB_COLOR_LAST);
    dabDrawButton(CANVAS_W / 2, 375, "vs AI", DAB_COLOR_P2);
    dabDrawButton(CANVAS_W / 2, 440, "Online", DAB_COLOR_P1);
    dabDrawButton(CANVAS_W / 2, 505, "How to Play", color(30, 60, 120));
    dabDrawButton(CANVAS_W / 2, 570, "Back", color(120));
  }

  void drawHowTo(int page) {
    color accent = color(30, 60, 120);
    drawHowToFrame("DOTS & BOXES - How to Play", page, 2, accent);

    if (page == 0) {
      drawHowToSubtitle("Drawing Lines", 90);

      // Mini 4x4 dot grid
      float gx = CANVAS_W / 2 - 90;
      float gy = 160;
      float sp = 60;
      int dots = 4;

      // Draw some lines already placed
      stroke(180, 180, 200); strokeWeight(3);
      // horizontal lines
      line(gx, gy, gx + sp, gy);
      line(gx + sp, gy, gx + sp * 2, gy);
      line(gx, gy + sp, gx + sp, gy + sp);
      line(gx + sp, gy + sp * 2, gx + sp * 2, gy + sp * 2);
      // vertical lines
      line(gx, gy, gx, gy + sp);
      line(gx + sp * 2, gy, gx + sp * 2, gy + sp);
      line(gx + sp, gy + sp, gx + sp, gy + sp * 2);

      // A hover line (dashed style with different color)
      stroke(255, 255, 255, 120); strokeWeight(3);
      line(gx + sp, gy, gx + sp, gy + sp);

      // Dots
      noStroke();
      fill(220, 220, 230);
      for (int r = 0; r < dots; r++) {
        for (int c = 0; c < dots; c++) {
          ellipse(gx + c * sp, gy + r * sp, 10, 10);
        }
      }

      drawHowToText("Take turns drawing lines between adjacent dots.", gy + sp * 3 + 40);
      drawHowToText("Click near a line to draw it.", gy + sp * 3 + 65);

    } else if (page == 1) {
      drawHowToSubtitle("Scoring", 90);

      // Draw a completed box
      float gx = CANVAS_W / 2 - 60;
      float gy = 150;
      float sp = 70;

      // Filled box
      noStroke();
      fill(231, 76, 60, 80);
      rect(gx + 2, gy + 2, sp - 4, sp - 4, 4);
      // Player initial
      textAlign(CENTER, CENTER); textSize(24);
      fill(231, 76, 60, 180);
      text("1", gx + sp / 2, gy + sp / 2);

      // 4 sides of box
      stroke(180, 180, 200); strokeWeight(4);
      line(gx, gy, gx + sp, gy);
      line(gx, gy + sp, gx + sp, gy + sp);
      line(gx, gy, gx, gy + sp);
      line(gx + sp, gy, gx + sp, gy + sp);

      // Dots at corners
      noStroke();
      fill(220, 220, 230);
      ellipse(gx, gy, 10, 10);
      ellipse(gx + sp, gy, 10, 10);
      ellipse(gx, gy + sp, 10, 10);
      ellipse(gx + sp, gy + sp, 10, 10);

      // The completing line highlighted
      stroke(46, 204, 113, 200); strokeWeight(5);
      line(gx + sp, gy, gx + sp, gy + sp);

      // Arrow pointing to it
      noStroke();
      fill(241, 196, 15); textAlign(LEFT, CENTER); textSize(12);
      text("\u2190 completing line", gx + sp + 15, gy + sp / 2);

      float ty = gy + sp + 50;
      drawHowToBullet("Complete a box (4 sides) to score a point.", 80, ty);
      drawHowToBullet("Completing a box gives you an EXTRA TURN!", 80, ty + 30);
      drawHowToBullet("One line can complete 2 boxes at once.", 80, ty + 60);
      drawHowToBullet("Most boxes when all lines are drawn wins!", 80, ty + 90);
    }
  }

  void dabDrawButton(float x, float y, String label, color c) {
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
