final color QRT_COLOR_BG = color(45, 30, 60);
final color QRT_COLOR_BOARD = color(160, 130, 90);
final color QRT_COLOR_BOARD_DARK = color(130, 100, 70);
final color QRT_COLOR_P1 = color(100, 180, 255);
final color QRT_COLOR_P2 = color(255, 120, 80);
final color QRT_COLOR_LIGHT = color(240, 220, 180);
final color QRT_COLOR_DARK = color(100, 60, 40);
final color QRT_COLOR_HIGHLIGHT = color(255, 255, 100, 150);

class QRTRenderer {
  QRTGame game;
  int cellSize = 110;
  int boardW = cellSize * 4;
  int boardH = cellSize * 4;
  int offsetX = (CANVAS_W - cellSize * 4) / 2;
  int offsetY = 120;
  int paletteY = 600;
  int palettePieceSize = 40;

  QRTRenderer(QRTGame game) {
    this.game = game;
  }

  int[] getCellAtMouse() {
    if (mouseX < offsetX || mouseX > offsetX + boardW) return null;
    if (mouseY < offsetY || mouseY > offsetY + boardH) return null;
    int col = (mouseX - offsetX) / cellSize;
    int row = (mouseY - offsetY) / cellSize;
    if (row < 0 || row >= 4 || col < 0 || col >= 4) return null;
    return new int[]{row, col};
  }

  int getPaletteAtMouse() {
    float startX = offsetX;
    float spacing = (float)boardW / 8;
    for (int i = 0; i < 16; i++) {
      int pr = i / 8;
      int pc = i % 8;
      float px = startX + pc * spacing + spacing / 2;
      float py = paletteY + pr * 60 + 30;
      if (dist(mouseX, mouseY, px, py) < palettePieceSize * 0.6) {
        return i;
      }
    }
    return -1;
  }

  // Game drawing

  void drawGame() {
    background(QRT_COLOR_BG);
    drawTopBar();
    drawBoard();
    drawHoverPreview();
    drawPalette();
    drawParticles(game.particles);
  }

  void drawBoard() {
    // Board background
    noStroke();
    fill(QRT_COLOR_BOARD_DARK);
    rect(offsetX - 10, offsetY - 10, boardW + 20, boardH + 20, 12);
    fill(QRT_COLOR_BOARD);
    rect(offsetX - 6, offsetY - 6, boardW + 12, boardH + 12, 10);

    // Grid lines
    stroke(QRT_COLOR_BOARD_DARK);
    strokeWeight(2);
    for (int i = 0; i <= 4; i++) {
      line(offsetX + i * cellSize, offsetY, offsetX + i * cellSize, offsetY + boardH);
      line(offsetX, offsetY + i * cellSize, offsetX + boardW, offsetY + i * cellSize);
    }

    // Cells
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        float cx = offsetX + c * cellSize + cellSize / 2.0;
        float cy = offsetY + r * cellSize + cellSize / 2.0;
        int val = game.board.grid[r][c];

        if (val == -1) {
          // Empty cell highlight
          noStroke();
          fill(QRT_COLOR_BOARD, 80);
          rect(offsetX + c * cellSize + 4, offsetY + r * cellSize + 4, cellSize - 8, cellSize - 8, 6);
        } else {
          drawQRTPiece(cx, cy, cellSize * 0.7, val, false);
        }
      }
    }
  }

  void drawHoverPreview() {
    if (game.state != QRT_PLAYING) return;
    if (game.turnPhase != QRT_PHASE_PLACING) return;
    if (game.board.selectedPiece < 0) return;
    if (game.mode == QRT_AI_MODE && game.currentPlayer == 2) return;
    if (game.mode == QRT_ONLINE && game.currentPlayer != game.playerRole) return;

    int[] cell = getCellAtMouse();
    if (cell == null) return;
    if (game.board.grid[cell[0]][cell[1]] != -1) return;

    float cx = offsetX + cell[1] * cellSize + cellSize / 2.0;
    float cy = offsetY + cell[0] * cellSize + cellSize / 2.0;
    drawQRTPiece(cx, cy, cellSize * 0.7, game.board.selectedPiece, true);
  }

  void drawPalette() {
    float startX = offsetX;
    float spacing = (float)boardW / 8;

    // Label
    textAlign(CENTER, CENTER);
    textSize(14);
    fill(180);
    text("Available Pieces", CANVAS_W / 2, paletteY - 15);

    for (int i = 0; i < 16; i++) {
      int pr = i / 8;
      int pc = i % 8;
      float px = startX + pc * spacing + spacing / 2;
      float py = paletteY + pr * 60 + 30;

      if (!game.board.available[i]) {
        // Used piece - dim
        noStroke();
        fill(60, 40, 70, 80);
        ellipse(px, py, palettePieceSize * 0.5, palettePieceSize * 0.5);
        continue;
      }

      // Highlight selected piece
      if (game.board.selectedPiece == i) {
        noFill();
        stroke(QRT_COLOR_HIGHLIGHT);
        strokeWeight(3);
        ellipse(px, py, palettePieceSize + 10, palettePieceSize + 10);
      }

      // Highlight hoverable pieces during choosing phase
      if (game.state == QRT_PLAYING && game.turnPhase == QRT_PHASE_CHOOSING) {
        if (dist(mouseX, mouseY, px, py) < palettePieceSize * 0.6) {
          noFill();
          stroke(255, 255, 255, 100);
          strokeWeight(2);
          ellipse(px, py, palettePieceSize + 6, palettePieceSize + 6);
        }
      }

      drawQRTPiece(px, py, palettePieceSize, i, false);
    }
  }

  void drawQRTPiece(float cx, float cy, float size, int pieceId, boolean ghost) {
    boolean tall = (pieceId & 1) != 0;
    boolean round = (pieceId & 2) != 0;
    boolean hollow = (pieceId & 4) != 0;
    boolean light = (pieceId & 8) != 0;

    float h = tall ? size * 1.0 : size * 0.6;
    float w = tall ? size * 0.7 : size * 0.6;

    color baseColor = light ? QRT_COLOR_LIGHT : QRT_COLOR_DARK;
    int alpha = ghost ? 90 : 255;

    if (hollow) {
      noFill();
      stroke(baseColor, alpha);
      strokeWeight(3);
    } else {
      fill(baseColor, alpha);
      noStroke();
      // Shadow
      if (!ghost) {
        fill(0, 30);
        if (round) {
          ellipse(cx + 2, cy + 2, w, h);
        } else {
          rectMode(CENTER);
          rect(cx + 2, cy + 2, w, h, 4);
        }
        fill(baseColor, alpha);
      }
    }

    if (round) {
      ellipse(cx, cy, w, h);
    } else {
      rectMode(CENTER);
      rect(cx, cy, w, h, 4);
    }

    // Highlight dot for 3D effect on solid pieces
    if (!hollow && !ghost) {
      fill(255, 60);
      noStroke();
      ellipse(cx - w * 0.15, cy - h * 0.15, w * 0.25, h * 0.25);
    }

    rectMode(CORNER);
  }

  void drawTopBar() {
    textAlign(CENTER, CENTER);

    if (game.state == QRT_GAMEOVER) {
      drawGameOverUI();
      return;
    }

    String label;
    color c;
    if (game.currentPlayer == 1) {
      c = QRT_COLOR_P1;
    } else {
      c = QRT_COLOR_P2;
    }

    if (game.turnPhase == QRT_PHASE_CHOOSING) {
      if (game.firstTurn) {
        label = "Player 1 — Choose a piece to give";
      } else {
        label = "Player " + game.currentPlayer + " — Choose a piece to give";
      }
    } else {
      label = "Player " + game.currentPlayer + " — Place the piece";
    }

    if (game.mode == QRT_AI_MODE) {
      if (game.currentPlayer == 2) {
        label = "AI Thinking...";
      } else {
        label = (game.turnPhase == QRT_PHASE_CHOOSING) ? "Choose a piece for AI" : "Place the piece";
      }
    }

    if (game.mode == QRT_ONLINE) {
      if (game.currentPlayer == game.playerRole) {
        label = (game.turnPhase == QRT_PHASE_CHOOSING) ? "Choose a piece to give" : "Place the piece";
        label = "Your Turn — " + label;
      } else {
        label = "Opponent's Turn";
      }
      c = (game.currentPlayer == 1) ? QRT_COLOR_P1 : QRT_COLOR_P2;
    }

    // Selected piece indicator
    if (game.turnPhase == QRT_PHASE_PLACING && game.board.selectedPiece >= 0) {
      drawQRTPiece(CANVAS_W / 2 - 130, 45, 30, game.board.selectedPiece, false);
    }

    // Player color indicator
    noStroke();
    fill(c);
    ellipse(CANVAS_W / 2 - 100, 45, 16, 16);

    textSize(18);
    fill(255);
    text(label, CANVAS_W / 2 + 20, 45);
  }

  void drawGameOverUI() {
    String msg;
    color c;
    if (game.winner == 3) {
      msg = "Draw!";
      c = color(180);
    } else if (game.mode == QRT_ONLINE) {
      if (game.winner == game.playerRole) {
        msg = "You Win!";
      } else {
        msg = "You Lose!";
      }
      c = (game.winner == 1) ? QRT_COLOR_P1 : QRT_COLOR_P2;
    } else if (game.winner == 1) {
      msg = "Player 1 Wins!";
      c = QRT_COLOR_P1;
    } else {
      msg = (game.mode == QRT_AI_MODE) ? "AI Wins!" : "Player 2 Wins!";
      c = QRT_COLOR_P2;
    }

    textSize(28);
    fill(c);
    text(msg, CANVAS_W / 2, 30);

    float elapsed = (millis() - game.gameOverTime) / 1000.0;
    if (elapsed > 1.0) {
      qrtDrawButton(CANVAS_W / 2 - 110, 60, "Restart", color(46, 204, 113));
      qrtDrawButton(CANVAS_W / 2 + 110, 60, "Menu", color(120));
    }
  }

  // Menu

  void drawMenu() {
    background(QRT_COLOR_BG);

    // Floating decorative shapes
    for (int i = 0; i < 12; i++) {
      float x = noise(i * 10 + millis() * 0.0003) * CANVAS_W;
      float y = noise(i * 20 + 500 + millis() * 0.0003) * CANVAS_H;
      noStroke();
      boolean isRound = (i % 3 != 0);
      boolean isHollow = (i % 4 == 0);
      color shapeColor = (i % 2 == 0) ? QRT_COLOR_P1 : QRT_COLOR_P2;

      if (isHollow) {
        noFill();
        stroke(shapeColor, 30);
        strokeWeight(2);
      } else {
        fill(shapeColor, 25);
        noStroke();
      }

      if (isRound) {
        ellipse(x, y, 30, 30);
      } else {
        rectMode(CENTER);
        rect(x, y, 25, 25, 3);
        rectMode(CORNER);
      }
    }

    // Title
    float bounce = sin(millis() * 0.003) * 8;
    textAlign(CENTER, CENTER);
    textSize(52);
    fill(255);
    text("QUARTO", CANVAS_W / 2, 180 + bounce);

    textSize(18);
    fill(150);
    text("D\u00f6rtl\u00fc Strateji", CANVAS_W / 2, 230);

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

    qrtDrawButton(CANVAS_W / 2, 310, "2 Players", color(46, 204, 113));
    qrtDrawButton(CANVAS_W / 2, 375, "vs AI", QRT_COLOR_P2);
    qrtDrawButton(CANVAS_W / 2, 440, "Online", color(140, 70, 180));
    qrtDrawButton(CANVAS_W / 2, 505, "How to Play", color(241, 196, 15));
    qrtDrawButton(CANVAS_W / 2, 570, "Back", color(120));
  }

  void drawLobby() {
    background(QRT_COLOR_BG);
    drawLobbyUI(game.lobbyState, game.network, game.roomCode, color(140, 70, 180));
  }

  void drawHowTo(int page) {
    color accent = color(140, 70, 180);
    drawHowToFrame("QUARTO - How to Play", page, 2, accent);

    if (page == 0) {
      drawHowToSubtitle("How to Play", 90);

      float y = 130;
      drawHowToBullet("Quarto has 16 unique pieces with 4 attributes:", 100, y);
      y += 25;
      drawHowToBullet("Tall / Short,  Round / Square", 120, y);
      y += 22;
      drawHowToBullet("Hollow / Solid,  Light / Dark", 120, y);
      y += 35;

      // Show example pieces
      float exX = 180;
      drawQRTPiece(exX, y + 20, 35, 0, false);
      textAlign(CENTER, CENTER); textSize(10); fill(150);
      text("short\nsquare\nsolid\ndark", exX, y + 60);

      drawQRTPiece(exX + 80, y + 15, 35, 0b1111, false);
      textAlign(CENTER, CENTER); textSize(10); fill(150);
      text("tall\nround\nhollow\nlight", exX + 80, y + 60);

      drawQRTPiece(exX + 160, y + 20, 35, 0b0101, false);
      textAlign(CENTER, CENTER); textSize(10); fill(150);
      text("tall\nsquare\nhollow\ndark", exX + 160, y + 60);

      drawQRTPiece(exX + 240, y + 15, 35, 0b1010, false);
      textAlign(CENTER, CENTER); textSize(10); fill(150);
      text("short\nround\nsolid\nlight", exX + 240, y + 60);

      y += 110;
      drawHowToBullet("Each turn has two phases:", 100, y);
      y += 25;
      drawHowToBullet("1. Place the piece your opponent chose for you", 120, y);
      y += 22;
      drawHowToBullet("2. Choose a piece for your opponent to place next", 120, y);
      y += 35;
      drawHowToBullet("First turn: Player 1 only chooses a piece (no placing).", 100, y);

    } else if (page == 1) {
      drawHowToSubtitle("Winning", 90);

      float y = 130;
      drawHowToBullet("Get 4 pieces in a row, column, or diagonal", 100, y);
      y += 22;
      drawHowToBullet("that share at least one common attribute.", 100, y);
      y += 40;

      drawHowToBullet("Example winning lines:", 100, y);
      y += 30;

      // All tall
      float exX = 160;
      for (int i = 0; i < 4; i++) {
        drawQRTPiece(exX + i * 50, y + 20, 30, 1 + i * 4, false);
      }
      textAlign(LEFT, CENTER); textSize(12); fill(180);
      text("All tall", exX + 220, y + 20);

      y += 55;
      // All round
      for (int i = 0; i < 4; i++) {
        drawQRTPiece(exX + i * 50, y + 20, 30, 2 + i * 4, false);
      }
      textAlign(LEFT, CENTER); textSize(12); fill(180);
      text("All round", exX + 220, y + 20);

      y += 55;
      // All light
      for (int i = 0; i < 4; i++) {
        drawQRTPiece(exX + i * 50, y + 20, 30, 8 + i, false);
      }
      textAlign(LEFT, CENTER); textSize(12); fill(180);
      text("All light", exX + 220, y + 20);

      y += 70;
      drawHowToText("All 16 pieces placed with no winner = Draw!", y);
    }
  }

  void qrtDrawButton(float x, float y, String label, color c) {
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
