final color BSH_COLOR_BG = color(15, 25, 50);
final color BSH_COLOR_WATER = color(40, 80, 130);
final color BSH_COLOR_WATER_LIGHT = color(50, 100, 160);
final color BSH_COLOR_SHIP = color(140, 140, 150);
final color BSH_COLOR_HIT = color(220, 50, 40);
final color BSH_COLOR_MISS = color(200, 200, 210);
final color BSH_COLOR_SUNK = color(160, 30, 20);
final color BSH_COLOR_P1 = color(70, 150, 255);
final color BSH_COLOR_P2 = color(255, 100, 70);

class BSHRenderer {
  BSHGame game;

  // Placement grid
  int placeCellSize = 55;
  int placeGridW = 550;
  int placeOffsetX = (CANVAS_W - 550) / 2;
  int placeOffsetY = 120;

  // Attack phase — top grid (opponent)
  int atkCellSize = 42;
  int atkGridW = 420;
  int atkOffsetX = (CANVAS_W - 420) / 2;
  int atkOffsetY = 80;

  // Attack phase — bottom grid (own)
  int defCellSize = 30;
  int defGridW = 300;
  int defOffsetX = (CANVAS_W - 300) / 2;
  int defOffsetY = 560;

  BSHRenderer(BSHGame game) {
    this.game = game;
  }

  int[] getPlacementCellAtMouse() {
    if (mouseX < placeOffsetX || mouseX > placeOffsetX + placeGridW) return null;
    if (mouseY < placeOffsetY || mouseY > placeOffsetY + placeCellSize * 10) return null;
    int col = (mouseX - placeOffsetX) / placeCellSize;
    int row = (mouseY - placeOffsetY) / placeCellSize;
    if (row < 0 || row >= 10 || col < 0 || col >= 10) return null;
    return new int[]{row, col};
  }

  int[] getAttackCellAtMouse() {
    if (mouseX < atkOffsetX || mouseX > atkOffsetX + atkGridW) return null;
    if (mouseY < atkOffsetY || mouseY > atkOffsetY + atkCellSize * 10) return null;
    int col = (mouseX - atkOffsetX) / atkCellSize;
    int row = (mouseY - atkOffsetY) / atkCellSize;
    if (row < 0 || row >= 10 || col < 0 || col >= 10) return null;
    return new int[]{row, col};
  }

  // Menu

  void drawMenu() {
    background(BSH_COLOR_BG);

    // Floating decorative waves
    for (int i = 0; i < 10; i++) {
      float x = noise(i * 10 + millis() * 0.0003) * CANVAS_W;
      float y = noise(i * 20 + 500 + millis() * 0.0003) * CANVAS_H;
      noStroke();
      fill(BSH_COLOR_WATER, 25);
      ellipse(x, y, 30, 12);
    }

    // Anchor decorations
    for (int i = 0; i < 4; i++) {
      float x = noise(i * 30 + 100 + millis() * 0.0002) * CANVAS_W;
      float y = noise(i * 40 + 300 + millis() * 0.0002) * CANVAS_H;
      stroke(BSH_COLOR_WATER_LIGHT, 30);
      strokeWeight(2);
      noFill();
      // Anchor ring
      ellipse(x, y - 8, 10, 10);
      // Anchor shaft
      line(x, y - 3, x, y + 12);
      // Anchor arms
      line(x - 8, y + 8, x, y + 12);
      line(x + 8, y + 8, x, y + 12);
    }

    // Title
    float bounce = sin(millis() * 0.003) * 8;
    textAlign(CENTER, CENTER);
    textSize(52);
    fill(255);
    text("BATTLESHIP", CANVAS_W / 2, 180 + bounce);

    textSize(18);
    fill(150);
    text("Sava\u015f Gemileri", CANVAS_W / 2, 230);

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

    bshDrawButton(CANVAS_W / 2, 310, "2 Players", color(46, 204, 113));
    bshDrawButton(CANVAS_W / 2, 375, "vs AI", BSH_COLOR_P2);
    bshDrawButton(CANVAS_W / 2, 440, "Online", color(30, 80, 140));
    bshDrawButton(CANVAS_W / 2, 505, "How to Play", color(241, 196, 15));
    bshDrawButton(CANVAS_W / 2, 570, "Back", color(120));
  }

  void drawLobby() {
    background(BSH_COLOR_BG);
    drawLobbyUI(game.lobbyState, game.network, game.roomCode, color(30, 80, 140));
  }

  // Placement

  void drawPlacement() {
    background(BSH_COLOR_BG);

    int boardIdx = game.placingPlayer - 1;
    BSHBoard board = game.boards[boardIdx];

    // Title
    textAlign(CENTER, CENTER);
    textSize(24);
    color pc = (game.placingPlayer == 1) ? BSH_COLOR_P1 : BSH_COLOR_P2;
    fill(pc);
    if (game.mode == BSH_ONLINE) {
      text("Place Your Ships", CANVAS_W / 2, 40);
    } else {
      text("Player " + game.placingPlayer + " - Place Your Ships", CANVAS_W / 2, 40);
    }

    textSize(14);
    fill(180);
    text("Press R to rotate  |  Click to place", CANVAS_W / 2, 70);

    // Grid labels
    drawGridLabels(placeOffsetX, placeOffsetY, placeCellSize, 10);

    // Grid
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        float x = placeOffsetX + c * placeCellSize;
        float y = placeOffsetY + r * placeCellSize;

        // Water
        noStroke();
        fill(BSH_COLOR_WATER);
        rect(x, y, placeCellSize, placeCellSize);

        // Grid line
        stroke(BSH_COLOR_WATER_LIGHT);
        strokeWeight(1);
        noFill();
        rect(x, y, placeCellSize, placeCellSize);

        // Ship
        if (board.ownGrid[r][c] != 0) {
          noStroke();
          fill(BSH_COLOR_SHIP);
          rect(x + 2, y + 2, placeCellSize - 4, placeCellSize - 4, 4);
        }
      }
    }

    // Ghost ship preview
    if (game.placingShipIdx < 5) {
      int[] cell = getPlacementCellAtMouse();
      if (cell != null) {
        boolean valid = board.canPlaceShip(game.placingShipIdx, cell[0], cell[1], game.placingHorizontal);
        int len = board.ships[game.placingShipIdx].length;
        color ghostColor = valid ? color(100, 200, 100, 100) : color(220, 50, 40, 100);
        noStroke();
        fill(ghostColor);
        if (game.placingHorizontal) {
          for (int i = 0; i < len; i++) {
            int cc = cell[1] + i;
            if (cc < 10) {
              rect(placeOffsetX + cc * placeCellSize + 2, placeOffsetY + cell[0] * placeCellSize + 2,
                   placeCellSize - 4, placeCellSize - 4, 4);
            }
          }
        } else {
          for (int i = 0; i < len; i++) {
            int rr = cell[0] + i;
            if (rr < 10) {
              rect(placeOffsetX + cell[1] * placeCellSize + 2, placeOffsetY + rr * placeCellSize + 2,
                   placeCellSize - 4, placeCellSize - 4, 4);
            }
          }
        }
      }
    }

    // Ship list
    float listY = 700;
    textAlign(CENTER, CENTER);
    textSize(16);
    fill(200);
    text("Ships to Place:", CANVAS_W / 2, listY);
    listY += 25;

    for (int i = 0; i < 5; i++) {
      float sx = CANVAS_W / 2 - 120;
      float sy = listY + i * 28;
      boolean isCurrent = (i == game.placingShipIdx);
      boolean isPlaced = (i < game.placingShipIdx);

      textAlign(LEFT, CENTER);
      textSize(14);
      if (isCurrent) {
        fill(241, 196, 15);
        text("> " + board.ships[i].name + " (" + board.ships[i].length + ")", sx, sy);
        // Draw length indicator
        for (int j = 0; j < board.ships[i].length; j++) {
          noStroke();
          fill(241, 196, 15, 150);
          rect(sx + 180 + j * 20, sy - 7, 16, 14, 3);
        }
      } else if (isPlaced) {
        fill(100, 180, 100);
        text("  " + board.ships[i].name + " (" + board.ships[i].length + ")", sx, sy);
      } else {
        fill(120);
        text("  " + board.ships[i].name + " (" + board.ships[i].length + ")", sx, sy);
      }
    }

    // Online waiting state
    if (game.mode == BSH_ONLINE && game.selfReady && !game.opponentReady) {
      textAlign(CENTER, CENTER);
      textSize(20);
      fill(BSH_COLOR_P1);
      int dots = (millis() / 500) % 4;
      String dotStr = "";
      for (int d = 0; d < dots; d++) dotStr += ".";
      text("Waiting for opponent" + dotStr, CANVAS_W / 2, 860);
    }
  }

  // Pass screen

  void drawPassScreen() {
    background(BSH_COLOR_BG);

    textAlign(CENTER, CENTER);
    textSize(28);
    fill(255);
    text("Pass the device to", CANVAS_W / 2, 350);

    color pc = (game.placingPlayer == 1) ? BSH_COLOR_P1 : BSH_COLOR_P2;
    fill(pc);
    textSize(36);
    text("Player " + game.placingPlayer, CANVAS_W / 2, 410);

    bshDrawButton(CANVAS_W / 2, 500, "Ready", color(46, 204, 113));
  }

  // Game (attack phase)

  void drawGame() {
    background(BSH_COLOR_BG);
    drawTopBar();

    int attackerIdx = (game.currentPlayer == 1) ? 0 : 1;
    int defenderIdx = (game.currentPlayer == 1) ? 1 : 0;

    // For display: always show from current viewer's perspective
    int viewerIdx;
    if (game.mode == BSH_ONLINE) {
      viewerIdx = game.playerRole - 1;
    } else if (game.mode == BSH_AI_MODE) {
      viewerIdx = 0;
    } else {
      viewerIdx = game.currentPlayer - 1;
    }

    int opponentIdx = (viewerIdx == 0) ? 1 : 0;

    // Top: opponent's grid (attack view)
    textAlign(CENTER, CENTER);
    textSize(14);
    fill(BSH_COLOR_HIT);
    text("Enemy Waters", CANVAS_W / 2, atkOffsetY - 15);

    drawGridLabels(atkOffsetX, atkOffsetY, atkCellSize, 10);
    drawAttackGrid(game.boards[viewerIdx].attackGrid, atkOffsetX, atkOffsetY, atkCellSize);

    // Bottom: own grid (defense view)
    textSize(14);
    fill(BSH_COLOR_P1);
    text("Your Fleet", CANVAS_W / 2, defOffsetY - 15);

    drawGridLabels(defOffsetX, defOffsetY, defCellSize, 10);
    drawDefenseGrid(game.boards[viewerIdx], defOffsetX, defOffsetY, defCellSize);

    drawParticles(game.particles);
  }

  void drawTopBar() {
    textAlign(CENTER, CENTER);

    String label;
    color c;
    if (game.currentPlayer == 1) {
      c = BSH_COLOR_P1;
    } else {
      c = BSH_COLOR_P2;
    }

    if (game.mode == BSH_AI_MODE) {
      if (game.currentPlayer == 1) {
        label = "Your Turn";
      } else {
        label = "AI Thinking...";
      }
    } else if (game.mode == BSH_ONLINE) {
      if (game.currentPlayer == game.playerRole) {
        label = "Your Turn";
      } else {
        label = "Opponent's Turn";
      }
    } else {
      label = "Player " + game.currentPlayer + "'s Turn";
    }

    // Status indicator
    noStroke();
    fill(c);
    ellipse(CANVAS_W / 2 - 80, 40, 16, 16);
    textSize(22);
    fill(255);
    text(label, CANVAS_W / 2 + 5, 40);

    // Last attack result
    if (game.lastAttackResult >= 0) {
      float elapsed = (millis() - game.lastAttackTime) / 1000.0;
      if (elapsed < 2.0) {
        float alpha = elapsed < 1.5 ? 255 : map(elapsed, 1.5, 2.0, 255, 0);
        textSize(16);
        if (game.lastAttackResult == 0) {
          fill(BSH_COLOR_MISS, alpha);
          text("Miss!", CANVAS_W / 2, 60);
        } else if (game.lastAttackResult == 1) {
          fill(BSH_COLOR_HIT, alpha);
          text("Hit!", CANVAS_W / 2, 60);
        } else {
          fill(BSH_COLOR_HIT, alpha);
          text(game.lastSunkName + " Sunk!", CANVAS_W / 2, 60);
        }
      }
    }
  }

  void drawAttackGrid(int[][] attackGrid, int ox, int oy, int cs) {
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        float x = ox + c * cs;
        float y = oy + r * cs;

        noStroke();
        fill(BSH_COLOR_WATER);
        rect(x, y, cs, cs);
        stroke(BSH_COLOR_WATER_LIGHT);
        strokeWeight(1);
        noFill();
        rect(x, y, cs, cs);

        int val = attackGrid[r][c];
        float cx = x + cs / 2.0;
        float cy = y + cs / 2.0;

        if (val == 1) {
          // Miss — white dot
          noStroke();
          fill(BSH_COLOR_MISS);
          ellipse(cx, cy, cs * 0.3, cs * 0.3);
        } else if (val == 2) {
          // Hit — red X
          stroke(BSH_COLOR_HIT);
          strokeWeight(3);
          float s = cs * 0.25;
          line(cx - s, cy - s, cx + s, cy + s);
          line(cx + s, cy - s, cx - s, cy + s);
        } else if (val == 3) {
          // Sunk — dark red filled
          noStroke();
          fill(BSH_COLOR_SUNK);
          rect(x + 2, y + 2, cs - 4, cs - 4, 3);
          stroke(BSH_COLOR_HIT);
          strokeWeight(2);
          float s = cs * 0.2;
          line(cx - s, cy - s, cx + s, cy + s);
          line(cx + s, cy - s, cx - s, cy + s);
        }
      }
    }

    // Hover highlight
    if (game.state == BSH_PLAYING) {
      boolean canClick = true;
      if (game.mode == BSH_AI_MODE && game.currentPlayer == 2) canClick = false;
      if (game.mode == BSH_ONLINE && game.currentPlayer != game.playerRole) canClick = false;

      if (canClick) {
        int[] cell = getAttackCellAtMouse();
        if (cell != null && attackGrid[cell[0]][cell[1]] == 0) {
          float hx = ox + cell[1] * cs;
          float hy = oy + cell[0] * cs;
          noStroke();
          fill(255, 255, 255, 40);
          rect(hx, hy, cs, cs);
          // Crosshair
          stroke(255, 80, 80, 150);
          strokeWeight(1);
          float chx = hx + cs / 2.0;
          float chy = hy + cs / 2.0;
          line(chx - cs * 0.35, chy, chx + cs * 0.35, chy);
          line(chx, chy - cs * 0.35, chx, chy + cs * 0.35);
          noFill();
          ellipse(chx, chy, cs * 0.5, cs * 0.5);
        }
      }
    }
  }

  void drawDefenseGrid(BSHBoard board, int ox, int oy, int cs) {
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        float x = ox + c * cs;
        float y = oy + r * cs;

        noStroke();
        fill(BSH_COLOR_WATER);
        rect(x, y, cs, cs);
        stroke(BSH_COLOR_WATER_LIGHT);
        strokeWeight(1);
        noFill();
        rect(x, y, cs, cs);

        // Show own ships
        if (board.ownGrid[r][c] != 0) {
          noStroke();
          fill(BSH_COLOR_SHIP);
          rect(x + 1, y + 1, cs - 2, cs - 2, 2);
        }

        // Show hits on own ships
        float cx = x + cs / 2.0;
        float cy = y + cs / 2.0;

        // Check if this cell was attacked — look at opponent's attack grid
        // We need to check: was this cell hit?
        // If own ship is here and it was hit, show red X
        // If water and it was attacked, show miss dot
        // We can infer from ship hits, but simpler: track in board
        // For now, check opponent's attack grid
        int opponentIdx = (board == game.boards[0]) ? 1 : 0;
        if (opponentIdx < 2) {
          int oppAttack = game.boards[opponentIdx].attackGrid[r][c];
          if (oppAttack == 1) {
            // Miss on our waters
            noStroke();
            fill(BSH_COLOR_MISS, 150);
            ellipse(cx, cy, cs * 0.25, cs * 0.25);
          } else if (oppAttack == 2) {
            // Hit on our ship
            stroke(BSH_COLOR_HIT);
            strokeWeight(2);
            float s = cs * 0.2;
            line(cx - s, cy - s, cx + s, cy + s);
            line(cx + s, cy - s, cx - s, cy + s);
          } else if (oppAttack == 3) {
            // Sunk
            noStroke();
            fill(BSH_COLOR_SUNK, 100);
            rect(x + 1, y + 1, cs - 2, cs - 2, 2);
            stroke(BSH_COLOR_HIT);
            strokeWeight(2);
            float s = cs * 0.15;
            line(cx - s, cy - s, cx + s, cy + s);
            line(cx + s, cy - s, cx - s, cy + s);
          }
        }
      }
    }
  }

  void drawGridLabels(int ox, int oy, int cs, int size) {
    textAlign(CENTER, CENTER);
    textSize(cs > 35 ? 12 : 9);
    fill(150);
    String[] colLabels = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J"};
    for (int c = 0; c < size; c++) {
      text(colLabels[c], ox + c * cs + cs / 2, oy - (cs > 35 ? 12 : 9));
    }
    for (int r = 0; r < size; r++) {
      text("" + (r + 1), ox - (cs > 35 ? 14 : 10), oy + r * cs + cs / 2);
    }
  }

  // Game over

  void drawGameOver() {
    background(BSH_COLOR_BG);

    textAlign(CENTER, CENTER);

    // Winner text
    String msg;
    color c;
    if (game.mode == BSH_ONLINE) {
      if (game.winner == game.playerRole) {
        msg = "You Win!";
      } else {
        msg = "You Lose!";
      }
      c = (game.winner == 1) ? BSH_COLOR_P1 : BSH_COLOR_P2;
    } else if (game.mode == BSH_AI_MODE) {
      if (game.winner == 1) {
        msg = "You Win!";
      } else {
        msg = "AI Wins!";
      }
      c = (game.winner == 1) ? BSH_COLOR_P1 : BSH_COLOR_P2;
    } else {
      msg = "Player " + game.winner + " Wins!";
      c = (game.winner == 1) ? BSH_COLOR_P1 : BSH_COLOR_P2;
    }
    textSize(32);
    fill(c);
    text(msg, CANVAS_W / 2, 30);

    // Show both boards revealed — side by side
    int revCS = 28;
    int revGridW = revCS * 10;

    // P1 board
    int p1ox = CANVAS_W / 2 - revGridW - 20;
    int p1oy = 80;
    textSize(14);
    fill(BSH_COLOR_P1);
    text("Player 1", p1ox + revGridW / 2, p1oy - 18);
    drawRevealedBoard(game.boards[0], p1ox, p1oy, revCS);

    // P2 board
    int p2ox = CANVAS_W / 2 + 20;
    int p2oy = 80;
    textSize(14);
    fill(BSH_COLOR_P2);
    String p2Label = (game.mode == BSH_AI_MODE) ? "AI" : "Player 2";
    text(p2Label, p2ox + revGridW / 2, p2oy - 18);
    drawRevealedBoard(game.boards[1], p2ox, p2oy, revCS);

    // Ship status lists
    drawShipStatus(game.boards[0], p1ox, p1oy + revCS * 10 + 15, BSH_COLOR_P1);
    drawShipStatus(game.boards[1], p2ox, p2oy + revCS * 10 + 15, BSH_COLOR_P2);

    drawParticles(game.particles);

    float elapsed = (millis() - game.gameOverTime) / 1000.0;
    if (elapsed > 1.0) {
      bshDrawButton(CANVAS_W / 2 - 110, 850, "Restart", color(46, 204, 113));
      bshDrawButton(CANVAS_W / 2 + 110, 850, "Menu", color(120));
    }
  }

  void drawRevealedBoard(BSHBoard board, int ox, int oy, int cs) {
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        float x = ox + c * cs;
        float y = oy + r * cs;

        noStroke();
        fill(BSH_COLOR_WATER);
        rect(x, y, cs, cs);
        stroke(BSH_COLOR_WATER_LIGHT);
        strokeWeight(1);
        noFill();
        rect(x, y, cs, cs);

        // Show ships
        if (board.ownGrid[r][c] != 0) {
          noStroke();
          int shipIdx = board.ownGrid[r][c] - 1;
          if (board.ships[shipIdx].isSunk()) {
            fill(BSH_COLOR_SUNK);
          } else {
            fill(BSH_COLOR_SHIP);
          }
          rect(x + 1, y + 1, cs - 2, cs - 2, 2);
        }
      }
    }
  }

  void drawShipStatus(BSHBoard board, int ox, int oy, color c) {
    textAlign(LEFT, CENTER);
    textSize(11);
    for (int i = 0; i < 5; i++) {
      float sy = oy + i * 16;
      BSHShip ship = board.ships[i];
      if (ship.isSunk()) {
        fill(BSH_COLOR_SUNK);
        text(ship.name + " - SUNK", ox, sy);
      } else {
        fill(c);
        text(ship.name + " - " + ship.hits + "/" + ship.length, ox, sy);
      }
    }
  }

  // How to play

  void drawHowTo(int page) {
    color accent = color(30, 80, 140);
    drawHowToFrame("BATTLESHIP - How to Play", page, 3, accent);

    if (page == 0) {
      drawHowToSubtitle("Ship Placement", 90);

      // Ship list
      String[][] shipInfo = {
        {"Carrier", "5"}, {"Battleship", "4"}, {"Cruiser", "3"},
        {"Submarine", "3"}, {"Destroyer", "2"}
      };
      float listX = CANVAS_W / 2 - 100;
      float listY = 130;
      for (int i = 0; i < 5; i++) {
        textAlign(LEFT, CENTER);
        textSize(14);
        fill(200);
        text(shipInfo[i][0], listX, listY + i * 35);
        int len = Integer.parseInt(shipInfo[i][1]);
        for (int j = 0; j < len; j++) {
          noStroke();
          fill(BSH_COLOR_SHIP);
          rect(listX + 110 + j * 22, listY + i * 35 - 8, 18, 16, 3);
        }
      }

      drawHowToText("Each player places 5 ships on their 10x10 grid.", listY + 5 * 35 + 10);
      drawHowToText("Ships cannot overlap or go off the board.", listY + 5 * 35 + 35);
      drawHowToText("Press R to rotate between horizontal and vertical.", listY + 5 * 35 + 60);
      drawHowToText("Click on the grid to place the current ship.", listY + 5 * 35 + 85);

    } else if (page == 1) {
      drawHowToSubtitle("Battle", 90);

      // Mini grids showing hit/miss/sunk
      float gx = CANVAS_W / 2 - 80;
      float gy = 140;
      float cs = 28;

      // Miss example
      noStroke();
      fill(BSH_COLOR_WATER);
      rect(gx, gy, cs, cs);
      fill(BSH_COLOR_MISS);
      ellipse(gx + cs / 2, gy + cs / 2, cs * 0.3, cs * 0.3);
      textAlign(LEFT, CENTER); textSize(14); fill(200);
      text("= Miss", gx + cs + 10, gy + cs / 2);

      // Hit example
      gy += 45;
      noStroke();
      fill(BSH_COLOR_WATER);
      rect(gx, gy, cs, cs);
      stroke(BSH_COLOR_HIT); strokeWeight(3);
      float s = cs * 0.25;
      float ccx = gx + cs / 2; float ccy = gy + cs / 2;
      line(ccx - s, ccy - s, ccx + s, ccy + s);
      line(ccx + s, ccy - s, ccx - s, ccy + s);
      textAlign(LEFT, CENTER); textSize(14); fill(200);
      text("= Hit", gx + cs + 10, gy + cs / 2);

      // Sunk example
      gy += 45;
      noStroke();
      fill(BSH_COLOR_SUNK);
      rect(gx, gy, cs, cs);
      rect(gx + cs, gy, cs, cs);
      rect(gx + cs * 2, gy, cs, cs);
      textAlign(LEFT, CENTER); textSize(14); fill(200);
      text("= Sunk ship", gx + cs * 3 + 10, gy + cs / 2);

      gy += 60;
      drawHowToText("Players take turns attacking the opponent's grid.", gy);
      drawHowToText("Click a cell in 'Enemy Waters' to fire.", gy + 25);
      drawHowToText("Hit all cells of a ship to sink it.", gy + 50);
      drawHowToText("Sink all 5 ships to win!", gy + 75);

    } else if (page == 2) {
      drawHowToSubtitle("Strategy Tips", 90);

      float ty = 140;
      drawHowToBullet("Use a checkerboard pattern to hunt efficiently.", CANVAS_W / 2 - 180, ty);
      ty += 35;
      drawHowToBullet("When you get a hit, try all 4 adjacent cells.", CANVAS_W / 2 - 180, ty);
      ty += 35;
      drawHowToBullet("Two hits in a line? Continue that direction.", CANVAS_W / 2 - 180, ty);
      ty += 35;
      drawHowToBullet("Don't forget to try both ends of a hit line.", CANVAS_W / 2 - 180, ty);
      ty += 35;
      drawHowToBullet("Place ships away from edges for harder targeting.", CANVAS_W / 2 - 180, ty);
      ty += 35;
      drawHowToBullet("Smallest ship (Destroyer) is 2 cells - hardest to find!", CANVAS_W / 2 - 180, ty);

      // Mini checkerboard illustration
      float gx = CANVAS_W / 2 - 70;
      float gy = ty + 50;
      float cs = 20;
      for (int r = 0; r < 6; r++) {
        for (int c2 = 0; c2 < 7; c2++) {
          noStroke();
          if ((r + c2) % 2 == 0) {
            fill(BSH_COLOR_WATER_LIGHT, 100);
          } else {
            fill(BSH_COLOR_WATER, 60);
          }
          rect(gx + c2 * cs, gy + r * cs, cs, cs);
        }
      }
      textAlign(CENTER, CENTER);
      textSize(11);
      fill(150);
      text("Checkerboard hunting pattern", CANVAS_W / 2, gy + 6 * cs + 12);
    }
  }

  void bshDrawButton(float x, float y, String label, color c) {
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
