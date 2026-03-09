// NMM Colors
final color NMM_COLOR_BG = color(62, 43, 35);
final color NMM_COLOR_BOARD = color(210, 190, 160);
final color NMM_COLOR_P1 = color(40, 35, 30);
final color NMM_COLOR_P2 = color(235, 225, 210);
final color NMM_COLOR_HIGHLIGHT = color(46, 204, 113);
final color NMM_COLOR_REMOVE = color(231, 76, 60);
final color NMM_COLOR_MILL = color(241, 196, 15);
final color NMM_COLOR_SELECTED = color(52, 152, 219);

class NMMRenderer {
  NMMGame game;

  // Board geometry
  float boardX, boardY, boardSize;
  float outerMargin;
  float ringGap;

  NMMRenderer(NMMGame game) {
    this.game = game;
    boardSize = 480;
    boardX = (CANVAS_W - boardSize) / 2;
    boardY = 110 + (CANVAS_H - 110 - boardSize) / 2;
    outerMargin = 0;
    ringGap = boardSize / 6;
  }

  float[] nmmGetPos(int index) {
    float x = 0, y = 0;
    float cx = boardX + boardSize / 2;
    float cy = boardY + boardSize / 2;
    float r0 = boardSize / 2;        // outer ring half-size
    float r1 = boardSize / 2 - ringGap;  // middle ring
    float r2 = boardSize / 2 - ringGap * 2; // inner ring

    switch (index) {
      case 0:  x = cx - r0; y = cy - r0; break;
      case 1:  x = cx;      y = cy - r0; break;
      case 2:  x = cx + r0; y = cy - r0; break;
      case 3:  x = cx - r1; y = cy - r1; break;
      case 4:  x = cx;      y = cy - r1; break;
      case 5:  x = cx + r1; y = cy - r1; break;
      case 6:  x = cx - r2; y = cy - r2; break;
      case 7:  x = cx;      y = cy - r2; break;
      case 8:  x = cx + r2; y = cy - r2; break;
      case 9:  x = cx - r0; y = cy;      break;
      case 10: x = cx - r1; y = cy;      break;
      case 11: x = cx - r2; y = cy;      break;
      case 12: x = cx + r2; y = cy;      break;
      case 13: x = cx + r1; y = cy;      break;
      case 14: x = cx + r0; y = cy;      break;
      case 15: x = cx - r2; y = cy + r2; break;
      case 16: x = cx;      y = cy + r2; break;
      case 17: x = cx + r2; y = cy + r2; break;
      case 18: x = cx - r1; y = cy + r1; break;
      case 19: x = cx;      y = cy + r1; break;
      case 20: x = cx + r1; y = cy + r1; break;
      case 21: x = cx - r0; y = cy + r0; break;
      case 22: x = cx;      y = cy + r0; break;
      case 23: x = cx + r0; y = cy + r0; break;
    }
    return new float[]{x, y};
  }

  int getClickedPosition() {
    float threshold = 20;
    for (int i = 0; i < 24; i++) {
      float[] p = nmmGetPos(i);
      if (dist(mouseX, mouseY, p[0], p[1]) < threshold) {
        return i;
      }
    }
    return -1;
  }

  // Game drawing

  void drawGame() {
    background(NMM_COLOR_BG);
    drawTopBar();
    drawBoard();
    drawMillHighlight();
    drawPieces();
    drawValidIndicators();
    drawHover();
    drawParticles(game.particles);
  }

  void drawBoard() {
    stroke(NMM_COLOR_BOARD);
    strokeWeight(3);
    noFill();

    float cx = boardX + boardSize / 2;
    float cy = boardY + boardSize / 2;
    float r0 = boardSize / 2;
    float r1 = boardSize / 2 - ringGap;
    float r2 = boardSize / 2 - ringGap * 2;

    // Three concentric squares
    rect(cx - r0, cy - r0, r0 * 2, r0 * 2);
    rect(cx - r1, cy - r1, r1 * 2, r1 * 2);
    rect(cx - r2, cy - r2, r2 * 2, r2 * 2);

    // Connecting lines at midpoints
    line(cx, cy - r0, cx, cy - r2);     // top
    line(cx, cy + r2, cx, cy + r0);     // bottom
    line(cx - r0, cy, cx - r2, cy);     // left
    line(cx + r2, cy, cx + r0, cy);     // right

    // Draw intersection points
    for (int i = 0; i < 24; i++) {
      float[] p = nmmGetPos(i);
      noStroke();
      fill(NMM_COLOR_BOARD);
      ellipse(p[0], p[1], 10, 10);
    }
  }

  void drawPieces() {
    float pieceSize = 30;
    for (int i = 0; i < 24; i++) {
      if (game.board.positions[i] == 0) continue;
      float[] p = nmmGetPos(i);
      int player = game.board.positions[i];

      // Selected piece glow
      if (i == game.selectedPiece) {
        noFill();
        stroke(NMM_COLOR_SELECTED, 150);
        strokeWeight(3);
        float pulse = map(sin(millis() * 0.006), -1, 1, pieceSize + 6, pieceSize + 14);
        ellipse(p[0], p[1], pulse, pulse);
      }

      // Piece
      stroke(120, 100, 80);
      strokeWeight(2);
      if (player == 1) {
        fill(NMM_COLOR_P1);
      } else {
        fill(NMM_COLOR_P2);
      }
      ellipse(p[0], p[1], pieceSize, pieceSize);

      // Removable highlight
      if (game.removing && game.board.canRemove(i, game.currentPlayer)) {
        noFill();
        stroke(NMM_COLOR_REMOVE, 180);
        strokeWeight(3);
        float pulse = map(sin(millis() * 0.008), -1, 1, pieceSize + 4, pieceSize + 12);
        ellipse(p[0], p[1], pulse, pulse);
      }
    }
  }

  void drawValidIndicators() {
    if (game.state != NMM_PLAYING) return;
    if (game.removing) return;
    if (game.mode == NMM_AI_MODE && game.currentPlayer == 2) return;
    if (game.mode == NMM_ONLINE && game.currentPlayer != game.playerRole) return;

    int phase = game.board.getPhase(game.currentPlayer);

    if (phase == NMM_PHASE_PLACE) {
      for (int i = 0; i < 24; i++) {
        if (game.board.positions[i] == 0) {
          float[] p = nmmGetPos(i);
          noStroke();
          fill(NMM_COLOR_HIGHLIGHT, 80);
          ellipse(p[0], p[1], 14, 14);
        }
      }
    } else if (game.selectedPiece != -1) {
      if (phase == NMM_PHASE_FLY) {
        for (int i = 0; i < 24; i++) {
          if (game.board.positions[i] == 0) {
            float[] p = nmmGetPos(i);
            noStroke();
            fill(NMM_COLOR_HIGHLIGHT, 80);
            ellipse(p[0], p[1], 14, 14);
          }
        }
      } else {
        for (int n : game.board.adjacency[game.selectedPiece]) {
          if (game.board.positions[n] == 0) {
            float[] p = nmmGetPos(n);
            noStroke();
            fill(NMM_COLOR_HIGHLIGHT, 80);
            ellipse(p[0], p[1], 14, 14);
          }
        }
      }
    }
  }

  void drawMillHighlight() {
    if (game.lastMillPositions == null) return;
    float elapsed = (millis() - game.lastMillTime) / 1000.0;
    if (elapsed > 2.0) {
      game.lastMillPositions = null;
      return;
    }
    float alpha = elapsed < 1.5 ? 200 : map(elapsed, 1.5, 2.0, 200, 0);
    float pulse = map(sin(millis() * 0.01), -1, 1, 36, 44);

    for (int pos : game.lastMillPositions) {
      float[] p = nmmGetPos(pos);
      noFill();
      stroke(NMM_COLOR_MILL, alpha);
      strokeWeight(3);
      ellipse(p[0], p[1], pulse, pulse);
    }

    // Draw line connecting mill
    stroke(NMM_COLOR_MILL, alpha * 0.6);
    strokeWeight(4);
    float[] p0 = nmmGetPos(game.lastMillPositions[0]);
    float[] p1 = nmmGetPos(game.lastMillPositions[1]);
    float[] p2 = nmmGetPos(game.lastMillPositions[2]);
    line(p0[0], p0[1], p1[0], p1[1]);
    line(p1[0], p1[1], p2[0], p2[1]);
  }

  void drawHover() {
    if (game.state != NMM_PLAYING) return;
    if (game.mode == NMM_AI_MODE && game.currentPlayer == 2) return;
    if (game.mode == NMM_ONLINE && game.currentPlayer != game.playerRole) return;

    int hovered = getClickedPosition();
    if (hovered == -1) return;

    float[] p = nmmGetPos(hovered);
    noFill();
    stroke(255, 80);
    strokeWeight(2);
    ellipse(p[0], p[1], 26, 26);
  }

  // Top bar

  void drawTopBar() {
    // Background bar
    noStroke();
    fill(0, 40);
    rect(0, 0, CANVAS_W, 100);

    textAlign(CENTER, CENTER);

    if (game.state == NMM_GAMEOVER) {
      drawGameOverUI();
      return;
    }

    // Current player indicator
    String label;
    color c;
    int phase = game.board.getPhase(game.currentPlayer);

    if (game.removing) {
      label = "Player " + game.currentPlayer + " — Remove a piece!";
      c = NMM_COLOR_REMOVE;
    } else if (game.mode == NMM_AI_MODE && game.currentPlayer == 2) {
      label = "AI Thinking...";
      c = NMM_COLOR_P2;
    } else if (game.mode == NMM_ONLINE) {
      String phaseLabel = "";
      if (phase == NMM_PHASE_PLACE) phaseLabel = "Place a piece";
      else if (phase == NMM_PHASE_MOVE) phaseLabel = (game.selectedPiece == -1) ? "Select a piece" : "Move to adjacent";
      else phaseLabel = (game.selectedPiece == -1) ? "Select a piece" : "Fly anywhere";

      if (game.currentPlayer == game.playerRole) {
        label = "Your Turn — " + phaseLabel;
      } else {
        label = "Opponent's Turn";
      }
      c = (game.currentPlayer == 1) ? NMM_COLOR_P1 : NMM_COLOR_P2;
    } else {
      String phaseLabel = "";
      if (phase == NMM_PHASE_PLACE) phaseLabel = "Place a piece";
      else if (phase == NMM_PHASE_MOVE) phaseLabel = (game.selectedPiece == -1) ? "Select a piece" : "Move to adjacent";
      else phaseLabel = (game.selectedPiece == -1) ? "Select a piece" : "Fly anywhere";

      label = "Player " + game.currentPlayer + " — " + phaseLabel;
      c = (game.currentPlayer == 1) ? NMM_COLOR_P1 : NMM_COLOR_P2;
    }

    // Player turn text
    textSize(18);
    fill(game.currentPlayer == 1 ? 200 : 255);
    text(label, CANVAS_W / 2, 25);

    // Piece counts
    textSize(13);

    // P1 info (left)
    fill(NMM_COLOR_P1);
    noStroke();
    ellipse(80, 60, 16, 16);
    fill(200);
    textAlign(LEFT, CENTER);
    text("Hand: " + game.board.piecesInHand[1] + "  Board: " + game.board.piecesOnBoard[1], 95, 60);

    // P2 info (right)
    String p2Label = (game.mode == NMM_AI_MODE) ? "AI" : "P2";
    fill(NMM_COLOR_P2);
    stroke(120, 100, 80);
    strokeWeight(1);
    ellipse(80, 82, 16, 16);
    noStroke();
    fill(200);
    textAlign(LEFT, CENTER);
    text("Hand: " + game.board.piecesInHand[2] + "  Board: " + game.board.piecesOnBoard[2], 95, 82);

    textAlign(CENTER, CENTER);
  }

  void drawGameOverUI() {
    String msg;
    color c;
    if (game.mode == NMM_ONLINE) {
      if (game.winner == game.playerRole) {
        msg = "You Win!";
      } else {
        msg = "You Lose!";
      }
      c = color(255);
    } else if (game.winner == 1) {
      msg = "Player 1 Wins!";
      c = color(255);
    } else {
      msg = (game.mode == NMM_AI_MODE) ? "AI Wins!" : "Player 2 Wins!";
      c = color(255);
    }

    textSize(26);
    fill(c);
    text(msg, CANVAS_W / 2, 30);

    float elapsed = (millis() - game.gameOverTime) / 1000.0;
    if (elapsed > 1.5) {
      nmmDrawButton(CANVAS_W / 2 - 110, 70, "Restart", NMM_COLOR_HIGHLIGHT);
      nmmDrawButton(CANVAS_W / 2 + 110, 70, "Menu", color(150));
    }
  }

  // Menu

  void drawMenu() {
    background(NMM_COLOR_BG);

    // Floating decorative elements - board pattern hints
    for (int i = 0; i < 10; i++) {
      float x = noise(i * 10 + millis() * 0.0002) * CANVAS_W;
      float y = noise(i * 20 + 500 + millis() * 0.0002) * CANVAS_H;
      noFill();
      stroke(NMM_COLOR_BOARD, 25);
      strokeWeight(1.5);
      if (i % 3 == 0) {
        float s = 20;
        rect(x - s, y - s, s * 2, s * 2);
      } else if (i % 3 == 1) {
        float s = 12;
        rect(x - s, y - s, s * 2, s * 2);
      } else {
        ellipse(x, y, 14, 14);
      }
    }

    // Title
    float bounce = sin(millis() * 0.003) * 8;
    textAlign(CENTER, CENTER);
    textSize(40);
    fill(NMM_COLOR_BOARD);
    text("NINE MEN'S MORRIS", CANVAS_W / 2, 180 + bounce);

    textSize(18);
    fill(180, 160, 130);
    text("Dokuz Tas", CANVAS_W / 2, 230);

    // Disconnect message
    if (game.disconnectMessage.length() > 0) {
      float elapsed = (millis() - game.disconnectMessageTime) / 1000.0;
      if (elapsed < 3.0) {
        float alpha = elapsed < 2.0 ? 255 : map(elapsed, 2.0, 3.0, 255, 0);
        textSize(16);
        fill(NMM_COLOR_REMOVE, alpha);
        text(game.disconnectMessage, CANVAS_W / 2, 270);
      } else {
        game.disconnectMessage = "";
      }
    }

    nmmDrawButton(CANVAS_W / 2, 310, "2 Players", NMM_COLOR_HIGHLIGHT);
    nmmDrawButton(CANVAS_W / 2, 375, "vs AI", color(52, 152, 219));
    nmmDrawButton(CANVAS_W / 2, 440, "Online", color(241, 196, 15));
    nmmDrawButton(CANVAS_W / 2, 505, "How to Play", color(160, 120, 60));
    nmmDrawButton(CANVAS_W / 2, 570, "Back", color(120));
  }

  void drawLobby() {
    background(NMM_COLOR_BG);
    drawLobbyUI(game.lobbyState, game.network, game.roomCode, NMM_COLOR_HIGHLIGHT);
  }

  // How to Play

  void drawHowTo(int page) {
    drawHowToFrame("Nine Men's Morris — How to Play", page, 4, color(160, 120, 60));

    switch (page) {
      case 0: drawHowToPage0(); break;
      case 1: drawHowToPage1(); break;
      case 2: drawHowToPage2(); break;
      case 3: drawHowToPage3(); break;
    }
  }

  void drawHowToPage0() {
    drawHowToSubtitle("The Board", 85);

    float cx = CANVAS_W / 2;
    float cy = 260;
    float r0 = 100, r1 = 65, r2 = 30;

    // Three concentric squares
    stroke(NMM_COLOR_BOARD);
    strokeWeight(2);
    noFill();
    rect(cx - r0, cy - r0, r0 * 2, r0 * 2);
    rect(cx - r1, cy - r1, r1 * 2, r1 * 2);
    rect(cx - r2, cy - r2, r2 * 2, r2 * 2);

    // Connecting lines
    line(cx, cy - r0, cx, cy - r2);
    line(cx, cy + r2, cx, cy + r0);
    line(cx - r0, cy, cx - r2, cy);
    line(cx + r2, cy, cx + r0, cy);

    // 24 intersection dots
    float[][] pts = {
      {cx-r0,cy-r0},{cx,cy-r0},{cx+r0,cy-r0},
      {cx-r1,cy-r1},{cx,cy-r1},{cx+r1,cy-r1},
      {cx-r2,cy-r2},{cx,cy-r2},{cx+r2,cy-r2},
      {cx-r0,cy},{cx-r1,cy},{cx-r2,cy},
      {cx+r2,cy},{cx+r1,cy},{cx+r0,cy},
      {cx-r2,cy+r2},{cx,cy+r2},{cx+r2,cy+r2},
      {cx-r1,cy+r1},{cx,cy+r1},{cx+r1,cy+r1},
      {cx-r0,cy+r0},{cx,cy+r0},{cx+r0,cy+r0}
    };
    noStroke();
    fill(NMM_COLOR_BOARD);
    for (float[] p : pts) {
      ellipse(p[0], p[1], 8, 8);
    }

    drawHowToBullet("The board has 24 positions on 3 concentric squares.", 80, 400);
    drawHowToBullet("Each player has 9 pieces.", 80, 430);
  }

  void drawHowToPage1() {
    drawHowToSubtitle("Phase 1: Placing", 85);

    float cx = CANVAS_W / 2;
    float cy = 250;
    float r0 = 80, r1 = 52, r2 = 24;

    stroke(NMM_COLOR_BOARD);
    strokeWeight(2);
    noFill();
    rect(cx - r0, cy - r0, r0 * 2, r0 * 2);
    rect(cx - r1, cy - r1, r1 * 2, r1 * 2);
    rect(cx - r2, cy - r2, r2 * 2, r2 * 2);
    line(cx, cy - r0, cx, cy - r2);
    line(cx, cy + r2, cx, cy + r0);
    line(cx - r0, cy, cx - r2, cy);
    line(cx + r2, cy, cx + r0, cy);

    // A few placed pieces
    float[][] p1Pos = {{cx-r0,cy-r0},{cx,cy-r1},{cx-r2,cy}};
    float[][] p2Pos = {{cx+r0,cy-r0},{cx+r1,cy},{cx,cy+r0}};

    for (float[] p : p1Pos) {
      stroke(120, 100, 80); strokeWeight(1.5);
      fill(NMM_COLOR_P1);
      ellipse(p[0], p[1], 20, 20);
    }
    for (float[] p : p2Pos) {
      stroke(120, 100, 80); strokeWeight(1.5);
      fill(NMM_COLOR_P2);
      ellipse(p[0], p[1], 20, 20);
    }

    drawHowToBullet("Players take turns placing pieces on empty positions.", 80, 390);
    drawHowToBullet("Place all 9 pieces before moving.", 80, 420);
  }

  void drawHowToPage2() {
    drawHowToSubtitle("Mills & Removing", 85);

    float cx = CANVAS_W / 2;
    float cy = 240;

    // Show 3 pieces in a line (a mill) - horizontal top of outer ring
    float r0 = 80;
    float[][] mill = {{cx-r0, cy-r0}, {cx, cy-r0}, {cx+r0, cy-r0}};

    // Draw partial board
    stroke(NMM_COLOR_BOARD);
    strokeWeight(2);
    noFill();
    rect(cx - r0, cy - r0, r0 * 2, r0 * 2);

    // Mill line highlight
    stroke(NMM_COLOR_MILL);
    strokeWeight(3);
    line(mill[0][0], mill[0][1], mill[2][0], mill[2][1]);

    // Mill pieces (P1)
    for (float[] p : mill) {
      noStroke();
      fill(NMM_COLOR_MILL, 60);
      ellipse(p[0], p[1], 30, 30);
      stroke(120, 100, 80); strokeWeight(1.5);
      fill(NMM_COLOR_P1);
      ellipse(p[0], p[1], 22, 22);
    }

    // Opponent piece being removed
    float opX = cx + r0, opY = cy;
    stroke(120, 100, 80); strokeWeight(1.5);
    fill(NMM_COLOR_P2);
    ellipse(opX, opY, 22, 22);
    // Red X over it
    stroke(NMM_COLOR_REMOVE);
    strokeWeight(3);
    float xs = 10;
    line(opX - xs, opY - xs, opX + xs, opY + xs);
    line(opX + xs, opY - xs, opX - xs, opY + xs);

    drawHowToBullet("Form a mill (3 in a line) to remove an opponent's piece.", 60, 380);
    drawHowToBullet("Pieces in a mill can't be removed (unless all are in mills).", 60, 410);
  }

  void drawHowToPage3() {
    drawHowToSubtitle("Moving, Flying & Winning", 85);

    float cx = CANVAS_W / 2;
    float cy = 230;
    float r0 = 70;

    // Show a piece with arrow to adjacent position
    stroke(NMM_COLOR_BOARD);
    strokeWeight(2);
    noFill();
    rect(cx - r0, cy - r0, r0 * 2, r0 * 2);

    float fromX = cx - r0, fromY = cy;
    float toX = cx - r0, toY = cy - r0;
    // Piece at from
    stroke(120, 100, 80); strokeWeight(1.5);
    fill(NMM_COLOR_P1);
    ellipse(fromX, fromY, 20, 20);
    // Ghost at destination
    noStroke();
    fill(NMM_COLOR_P1, 80);
    ellipse(toX, toY, 20, 20);
    // Arrow
    stroke(NMM_COLOR_HIGHLIGHT);
    strokeWeight(2);
    float ax = fromX + 5, ay1 = fromY - 14, ay2 = toY + 14;
    line(ax, ay1, ax, ay2);
    line(ax, ay2, ax - 6, ay2 + 8);
    line(ax, ay2, ax + 6, ay2 + 8);

    drawHowToBullet("After placing all pieces, move to adjacent empty positions.", 50, 360);
    drawHowToBullet("With only 3 pieces left, fly to ANY empty position.", 50, 390);
    drawHowToBullet("Win by reducing opponent to 2 pieces or blocking all moves.", 50, 420);
  }

  // Shared button

  void nmmDrawButton(float x, float y, String label, color c) {
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
