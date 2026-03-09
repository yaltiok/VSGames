final color CHK_COLOR_BG = color(35, 30, 30);
final color CHK_COLOR_LIGHT_SQ = color(235, 220, 195);
final color CHK_COLOR_DARK_SQ = color(65, 100, 60);
final color CHK_COLOR_P1 = color(200, 40, 40);
final color CHK_COLOR_P2 = color(235, 230, 220);
final color CHK_COLOR_KING = color(241, 196, 15);
final color CHK_COLOR_SELECTED = color(241, 196, 15, 100);
final color CHK_COLOR_VALID = color(46, 204, 113, 150);

final int CHK_CELL = 65;
final int CHK_OFFSET_X = (CANVAS_W - CHK_CELL * 8) / 2;
final int CHK_OFFSET_Y = 115;
final int CHK_TOP_BAR = 100;

class CHKRenderer {
  CHKGame game;

  CHKRenderer(CHKGame game) {
    this.game = game;
  }

  void drawGame() {
    background(CHK_COLOR_BG);
    drawTopBar();
    drawBoard();
    drawPieces();
    drawSelection();
    drawValidMoves();
    drawParticles(game.particles);
  }

  void drawTopBar() {
    textAlign(CENTER, CENTER);

    if (game.state == CHK_GAMEOVER) {
      drawGameOverUI();
      return;
    }

    // Current player indicator
    String label;
    color c;
    if (game.currentPlayer == 1) {
      label = "Red's Turn";
      c = CHK_COLOR_P1;
    } else {
      label = "White's Turn";
      c = CHK_COLOR_P2;
    }
    if (game.mode == CHK_AI_MODE && game.currentPlayer == 2) {
      label = "AI Thinking...";
    }
    if (game.mode == CHK_ONLINE) {
      if (game.currentPlayer == game.playerRole) {
        label = "Your Turn (" + (game.playerRole == 1 ? "Red" : "White") + ")";
      } else {
        label = "Opponent's Turn";
      }
    }
    if (game.inMultiJump) {
      label += " (Multi-jump!)";
    }

    textSize(22);
    fill(c);
    text(label, CANVAS_W / 2, 35);

    // Piece counts
    int p1Count = game.board.countPieces(1);
    int p2Count = game.board.countPieces(2);
    textSize(14);
    fill(CHK_COLOR_P1);
    text("Red: " + p1Count, CANVAS_W / 2 - 80, 65);
    fill(CHK_COLOR_P2);
    text("White: " + p2Count, CANVAS_W / 2 + 80, 65);
  }

  void drawGameOverUI() {
    String msg;
    color c;
    if (game.mode == CHK_ONLINE) {
      if (game.winner == game.playerRole) {
        msg = "You Win!";
      } else {
        msg = "You Lose!";
      }
      c = (game.winner == 1) ? CHK_COLOR_P1 : CHK_COLOR_P2;
    } else if (game.winner == 1) {
      msg = (game.mode == CHK_AI_MODE) ? "You Win!" : "Red Wins!";
      c = CHK_COLOR_P1;
    } else {
      msg = (game.mode == CHK_AI_MODE) ? "AI Wins!" : "White Wins!";
      c = CHK_COLOR_P2;
    }
    textSize(28);
    fill(c);
    text(msg, CANVAS_W / 2, 30);

    float elapsed = (millis() - game.gameOverTime) / 1000.0;
    if (elapsed > 1.0) {
      drawButton(CANVAS_W / 2 - 110, 70, "Restart", color(46, 204, 113));
      drawButton(CANVAS_W / 2 + 110, 70, "Menu", color(120));
    }
  }

  void drawBoard() {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        float x = CHK_OFFSET_X + c * CHK_CELL;
        float y = CHK_OFFSET_Y + r * CHK_CELL;
        noStroke();
        if ((r + c) % 2 == 0) {
          fill(CHK_COLOR_LIGHT_SQ);
        } else {
          fill(CHK_COLOR_DARK_SQ);
        }
        rect(x, y, CHK_CELL, CHK_CELL);
      }
    }

    // Board border
    noFill();
    stroke(100, 90, 80);
    strokeWeight(3);
    rect(CHK_OFFSET_X, CHK_OFFSET_Y, CHK_CELL * 8, CHK_CELL * 8);
  }

  void drawPieces() {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        int v = game.board.grid[r][c];
        if (v == 0) continue;
        float cx = CHK_OFFSET_X + c * CHK_CELL + CHK_CELL / 2;
        float cy = CHK_OFFSET_Y + r * CHK_CELL + CHK_CELL / 2;
        float sz = CHK_CELL * 0.38;
        boolean selected = (r == game.selectedRow && c == game.selectedCol);
        if (selected) sz *= 1.08;

        drawPiece(cx, cy, sz, v);
      }
    }
  }

  void drawPiece(float cx, float cy, float sz, int pieceVal) {
    color base = (pieceVal == 1 || pieceVal == 3) ? CHK_COLOR_P1 : CHK_COLOR_P2;
    boolean isKing = (pieceVal == 3 || pieceVal == 4);

    // Shadow
    noStroke();
    fill(0, 40);
    ellipse(cx + 2, cy + 3, sz * 2, sz * 2);

    // Main circle
    fill(base);
    stroke(red(base) * 0.6, green(base) * 0.6, blue(base) * 0.6);
    strokeWeight(2);
    ellipse(cx, cy, sz * 2, sz * 2);

    // 3D highlight
    noStroke();
    fill(255, 50);
    ellipse(cx - sz * 0.25, cy - sz * 0.25, sz * 0.9, sz * 0.7);

    // Inner ring
    noFill();
    stroke(red(base) * 0.7, green(base) * 0.7, blue(base) * 0.7);
    strokeWeight(1.5);
    ellipse(cx, cy, sz * 1.4, sz * 1.4);

    // King crown
    if (isKing) {
      noFill();
      stroke(CHK_COLOR_KING);
      strokeWeight(2.5);
      ellipse(cx, cy, sz * 1.1, sz * 1.1);

      // Crown symbol
      fill(CHK_COLOR_KING);
      noStroke();
      textAlign(CENTER, CENTER);
      textSize(sz * 0.9);
      text("K", cx, cy - 1);
    }
  }

  void drawSelection() {
    if (game.selectedRow == -1) return;
    float x = CHK_OFFSET_X + game.selectedCol * CHK_CELL;
    float y = CHK_OFFSET_Y + game.selectedRow * CHK_CELL;
    noStroke();
    fill(CHK_COLOR_SELECTED);
    rect(x, y, CHK_CELL, CHK_CELL);
  }

  void drawValidMoves() {
    for (int[] dest : game.validDestinations) {
      float cx = CHK_OFFSET_X + dest[1] * CHK_CELL + CHK_CELL / 2;
      float cy = CHK_OFFSET_Y + dest[0] * CHK_CELL + CHK_CELL / 2;
      noStroke();
      fill(CHK_COLOR_VALID);
      ellipse(cx, cy, 18, 18);
    }
  }

  // Menu

  void drawMenu() {
    background(CHK_COLOR_BG);

    // Decorative checkerboard pattern
    for (int i = 0; i < 8; i++) {
      float x = noise(i * 10 + millis() * 0.0003) * CANVAS_W;
      float y = noise(i * 20 + 500 + millis() * 0.0003) * CANVAS_H;
      noStroke();
      fill(CHK_COLOR_DARK_SQ, 30);
      rect(x - 12, y - 12, 24, 24);
      fill(CHK_COLOR_P1, 30);
      ellipse(x + 30, y, 20, 20);
      fill(CHK_COLOR_P2, 30);
      ellipse(x - 30, y, 20, 20);
    }

    // Title
    float bounce = sin(millis() * 0.003) * 8;
    textAlign(CENTER, CENTER);
    textSize(56);
    fill(255);
    text("CHECKERS", CANVAS_W / 2, 180 + bounce);

    textSize(18);
    fill(150);
    text("Dama", CANVAS_W / 2, 230);

    // Disconnect message
    if (game.disconnectMessage.length() > 0) {
      float elapsed = (millis() - game.disconnectMessageTime) / 1000.0;
      if (elapsed < 3.0) {
        float alpha = elapsed < 2.0 ? 255 : map(elapsed, 2.0, 3.0, 255, 0);
        textSize(16);
        fill(CHK_COLOR_P1, alpha);
        text(game.disconnectMessage, CANVAS_W / 2, 270);
      } else {
        game.disconnectMessage = "";
      }
    }

    // Buttons
    drawButton(CANVAS_W / 2, 310, "2 Players", color(46, 204, 113));
    drawButton(CANVAS_W / 2, 375, "vs AI", CHK_COLOR_P1);
    drawButton(CANVAS_W / 2, 440, "Online", color(52, 152, 219));
    drawButton(CANVAS_W / 2, 505, "How to Play", color(180, 50, 50));
    drawButton(CANVAS_W / 2, 570, "Back", color(120));
  }

  void drawLobby() {
    background(CHK_COLOR_BG);
    drawLobbyUI(game.lobbyState, game.network, game.roomCode, color(200, 40, 40));
  }

  void drawHowTo(int page) {
    drawHowToFrame("Checkers - How to Play", page, 3, color(180, 50, 50));

    if (page == 0) {
      drawHowToSubtitle("The Board", 90);

      // Mini 8x8 checkerboard
      float bx = CANVAS_W / 2 - 80;
      float by = 130;
      float cs = 20;
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          noStroke();
          if ((r + c) % 2 == 0) fill(235, 220, 195);
          else fill(65, 100, 60);
          rect(bx + c * cs, by + r * cs, cs, cs);
        }
      }
      // Red pieces on bottom dark squares
      for (int r = 5; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          if ((r + c) % 2 == 1) {
            noStroke();
            fill(200, 40, 40);
            ellipse(bx + c * cs + cs / 2, by + r * cs + cs / 2, 14, 14);
          }
        }
      }
      // White pieces on top dark squares
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 8; c++) {
          if ((r + c) % 2 == 1) {
            noStroke();
            fill(235, 230, 220);
            ellipse(bx + c * cs + cs / 2, by + r * cs + cs / 2, 14, 14);
          }
        }
      }
      // Border
      noFill();
      stroke(150);
      strokeWeight(2);
      rect(bx, by, 8 * cs, 8 * cs);

      float ty = by + 8 * cs + 30;
      drawHowToText("8x8 board, pieces on dark squares only.", ty);
      drawHowToText("Each player starts with 12 pieces.", ty + 28);

    } else if (page == 1) {
      drawHowToSubtitle("Moving & Capturing", 90);

      // Diagonal move arrow
      float bx = CANVAS_W / 2 - 100;
      float by = 140;
      float cs = 40;

      // Draw a small 4x4 board section
      for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
          noStroke();
          if ((r + c) % 2 == 0) fill(235, 220, 195);
          else fill(65, 100, 60);
          rect(bx + c * cs, by + r * cs, cs, cs);
        }
      }

      // Piece moving diagonally
      noStroke();
      fill(200, 40, 40);
      ellipse(bx + 1 * cs + cs / 2, by + 2 * cs + cs / 2, 24, 24);
      // Arrow showing move
      stroke(241, 196, 15);
      strokeWeight(2);
      line(bx + 1 * cs + cs / 2, by + 2 * cs + cs / 2, bx + 2 * cs + cs / 2, by + 1 * cs + cs / 2);
      // Arrowhead
      float ax = bx + 2 * cs + cs / 2;
      float ay = by + 1 * cs + cs / 2;
      fill(241, 196, 15);
      noStroke();
      ellipse(ax, ay, 8, 8);

      // Jump capture diagram (right side)
      float jx = bx + 5 * cs;
      for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
          noStroke();
          if ((r + c) % 2 == 0) fill(235, 220, 195);
          else fill(65, 100, 60);
          rect(jx + c * cs, by + r * cs, cs, cs);
        }
      }
      // Red piece jumps over white
      noStroke();
      fill(200, 40, 40);
      ellipse(jx + 0 * cs + cs / 2, by + 2 * cs + cs / 2, 24, 24);
      fill(235, 230, 220, 120);
      ellipse(jx + 1 * cs + cs / 2, by + 1 * cs + cs / 2, 24, 24);
      // X on captured piece
      stroke(255, 50, 50);
      strokeWeight(2);
      float cx2 = jx + 1 * cs + cs / 2;
      float cy2 = by + 1 * cs + cs / 2;
      line(cx2 - 6, cy2 - 6, cx2 + 6, cy2 + 6);
      line(cx2 - 6, cy2 + 6, cx2 + 6, cy2 - 6);
      // Arrow for jump
      stroke(241, 196, 15);
      strokeWeight(2);
      line(jx + 0 * cs + cs / 2, by + 2 * cs + cs / 2, jx + 2 * cs + cs / 2, by + 0 * cs + cs / 2);
      fill(241, 196, 15);
      noStroke();
      ellipse(jx + 2 * cs + cs / 2, by + 0 * cs + cs / 2, 8, 8);

      float ty = by + 4 * cs + 25;
      drawHowToText("Move diagonally forward one square.", ty);
      drawHowToText("Jump over opponent's piece to capture it.", ty + 26);
      drawHowToText("CAPTURES ARE MANDATORY - you must jump if possible.", ty + 52);
      drawHowToText("Chain jumps: keep jumping if more captures available.", ty + 78);

    } else if (page == 2) {
      drawHowToSubtitle("Kings & Winning", 90);

      // King piece illustration
      float cx = CANVAS_W / 2;
      float ky = 200;
      noStroke();
      fill(0, 40);
      ellipse(cx + 2, ky + 3, 60, 60);
      fill(200, 40, 40);
      stroke(120, 24, 24);
      strokeWeight(2);
      ellipse(cx, ky, 60, 60);
      // Crown ring
      noFill();
      stroke(241, 196, 15);
      strokeWeight(3);
      ellipse(cx, ky, 42, 42);
      // K symbol
      fill(241, 196, 15);
      noStroke();
      textAlign(CENTER, CENTER);
      textSize(24);
      text("K", cx, ky - 1);

      // Bidirectional arrows
      stroke(241, 196, 15);
      strokeWeight(2);
      line(cx - 50, ky - 40, cx - 70, ky - 60);
      line(cx + 50, ky - 40, cx + 70, ky - 60);
      line(cx - 50, ky + 40, cx - 70, ky + 60);
      line(cx + 50, ky + 40, cx + 70, ky + 60);

      float ty = 310;
      drawHowToText("Reach the opposite end to become a KING.", ty);
      drawHowToText("Kings can move and jump backwards too!", ty + 30);
      drawHowToText("Win by capturing all opponent's pieces", ty + 70);
      drawHowToText("or blocking all their moves.", ty + 96);
    }
  }

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
