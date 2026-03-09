final int BSH_MENU = 0;
final int BSH_PLACING = 1;
final int BSH_PASS_SCREEN = 2;
final int BSH_PLAYING = 3;
final int BSH_GAMEOVER = 4;
final int BSH_HOWTO = 5;
final int BSH_LOBBY = 6;

final int BSH_TWO_PLAYER = 0;
final int BSH_AI_MODE = 1;
final int BSH_ONLINE = 2;

class BSHGame extends GameBase {
  int state;
  int mode;
  int currentPlayer;
  int winner;
  int howToPage;
  BSHBoard[] boards;
  BSHRenderer renderer;
  ArrayList<Particle> particles;

  // Placement phase
  int placingPlayer;
  int placingShipIdx;
  boolean placingHorizontal;

  // Attack result display
  int lastAttackRow, lastAttackCol;
  int lastAttackResult; // 0=miss, 1=hit, 2=sunk
  String lastSunkName;
  int lastAttackTime;

  // AI
  boolean aiThinking;
  int aiMoveTime;
  int[] aiTarget;

  // Online
  boolean opponentReady;
  boolean selfReady;

  // Game over
  int gameOverTime;

  // Network
  GameNetwork network;
  int lobbyState;
  int playerRole;
  String roomCode = "";
  String disconnectMessage = "";
  int disconnectMessageTime = 0;

  BSHGame() {
    particles = new ArrayList<Particle>();
    renderer = new BSHRenderer(this);
    network = new GameNetwork();
  }

  String getName() { return "Battleship"; }
  color getColor() { return color(30, 80, 140); }

  void init() {
    state = BSH_MENU;
    particles.clear();
    aiThinking = false;
    disconnectMessage = "";
  }

  void startPlacement(int m) {
    mode = m;
    boards = new BSHBoard[2];
    boards[0] = new BSHBoard();
    boards[1] = new BSHBoard();
    currentPlayer = 1;
    winner = 0;
    particles.clear();
    placingPlayer = 1;
    placingShipIdx = 0;
    placingHorizontal = true;
    lastAttackResult = -1;
    lastSunkName = "";
    opponentReady = false;
    selfReady = false;
    aiThinking = false;

    if (mode == BSH_ONLINE) {
      placingPlayer = playerRole;
      state = BSH_PLACING;
    } else {
      state = BSH_PLACING;
    }
  }

  void startPlay() {
    currentPlayer = 1;
    state = BSH_PLAYING;
    lastAttackResult = -1;
  }

  void render() {
    updateParticles(particles);

    switch (state) {
      case BSH_MENU:
        renderer.drawMenu();
        break;
      case BSH_LOBBY:
        if (network.connected && !network.isHost) {
          playerRole = 2;
          startPlacement(BSH_ONLINE);
          break;
        }
        renderer.drawLobby();
        break;
      case BSH_PLACING:
        if (mode == BSH_ONLINE) bshReceive();
        renderer.drawPlacement();
        break;
      case BSH_PASS_SCREEN:
        renderer.drawPassScreen();
        break;
      case BSH_PLAYING:
        if (mode == BSH_AI_MODE && currentPlayer == 2 && !aiThinking) {
          startAIMove();
        }
        if (aiThinking) updateAI();
        if (mode == BSH_ONLINE) bshReceive();
        renderer.drawGame();
        break;
      case BSH_GAMEOVER:
        if (mode == BSH_ONLINE) bshReceive();
        renderer.drawGameOver();
        break;
      case BSH_HOWTO:
        renderer.drawHowTo(howToPage);
        break;
    }
  }

  void executeAttack(int row, int col) {
    int defenderIdx = (currentPlayer == 1) ? 1 : 0;
    int attackerIdx = (currentPlayer == 1) ? 0 : 1;
    BSHBoard defenderBoard = boards[defenderIdx];
    BSHBoard attackerBoard = boards[attackerIdx];

    int result = defenderBoard.attack(row, col);
    String sunkName = "";
    if (result == 2) {
      sunkName = defenderBoard.getSunkShipName(row, col);
    }
    attackerBoard.markAttack(row, col, result, sunkName);

    lastAttackRow = row;
    lastAttackCol = col;
    lastAttackResult = result;
    lastSunkName = sunkName;
    lastAttackTime = millis();

    if (result == 1 || result == 2) {
      spawnHitParticles(row, col);
    }

    if (defenderBoard.allSunk()) {
      winner = currentPlayer;
      state = BSH_GAMEOVER;
      gameOverTime = millis();
      spawnWinParticles(winner);
      return;
    }

    currentPlayer = (currentPlayer == 1) ? 2 : 1;
  }

  // AI

  void startAIMove() {
    aiThinking = true;
    aiMoveTime = millis();
    aiTarget = bshFindTarget(boards[1].attackGrid);
  }

  void updateAI() {
    if (!aiThinking) return;
    if (millis() - aiMoveTime < 500) return;
    aiThinking = false;
    if (aiTarget != null) {
      executeAttack(aiTarget[0], aiTarget[1]);
    }
  }

  // Input

  void onMousePressed() {
    switch (state) {
      case BSH_MENU:
        handleMenuClick();
        break;
      case BSH_LOBBY:
        handleLobbyClick();
        break;
      case BSH_PLACING:
        handlePlacementClick();
        break;
      case BSH_PASS_SCREEN:
        handlePassScreenClick();
        break;
      case BSH_PLAYING:
        handlePlayClick();
        break;
      case BSH_GAMEOVER:
        handleGameOverClick();
        break;
      case BSH_HOWTO:
        int nav = handleHowToNav(howToPage, 3);
        if (nav == -1) state = BSH_MENU;
        else howToPage = nav;
        break;
    }
  }

  void onKeyPressed() {
    if (state == BSH_PLACING) {
      if (key == 'r' || key == 'R') {
        placingHorizontal = !placingHorizontal;
      }
    }
    if (state == BSH_LOBBY && lobbyState == LOBBY_JOINING) {
      if (key == ENTER || key == RETURN) {
        if (roomCode.length() == 8) network.joinGame(roomCode);
        return;
      }
      roomCode = lobbyHandleKey(roomCode);
    }
  }

  void onEscape() {
    switch (state) {
      case BSH_MENU:
        returnToLauncher();
        break;
      case BSH_LOBBY:
        network.stop();
        state = BSH_MENU;
        break;
      case BSH_PLACING:
      case BSH_PASS_SCREEN:
      case BSH_PLAYING:
      case BSH_GAMEOVER:
        if (mode == BSH_ONLINE) network.stop();
        state = BSH_MENU;
        particles.clear();
        break;
      case BSH_HOWTO:
        state = BSH_MENU;
        break;
    }
  }

  void handleMenuClick() {
    float bw = 200, bh = 50;
    float cx = CANVAS_W / 2;
    if (mouseX > cx - bw/2 && mouseX < cx + bw/2) {
      if (mouseY > 310 - bh/2 && mouseY < 310 + bh/2) {
        startPlacement(BSH_TWO_PLAYER);
      } else if (mouseY > 375 - bh/2 && mouseY < 375 + bh/2) {
        startPlacement(BSH_AI_MODE);
      } else if (mouseY > 440 - bh/2 && mouseY < 440 + bh/2) {
        state = BSH_LOBBY;
        lobbyState = LOBBY_CHOOSE;
        roomCode = "";
      } else if (mouseY > 505 - bh/2 && mouseY < 505 + bh/2) {
        state = BSH_HOWTO;
        howToPage = 0;
      } else if (mouseY > 570 - bh/2 && mouseY < 570 + bh/2) {
        returnToLauncher();
      }
    }
  }

  void handlePlacementClick() {
    int boardIdx = placingPlayer - 1;
    BSHBoard board = boards[boardIdx];
    int[] cell = renderer.getPlacementCellAtMouse();
    if (cell == null) return;
    int row = cell[0];
    int col = cell[1];

    if (!board.canPlaceShip(placingShipIdx, row, col, placingHorizontal)) return;

    board.placeShip(placingShipIdx, row, col, placingHorizontal);

    if (mode == BSH_ONLINE) {
      String orient = placingHorizontal ? "0" : "1";
      network.send("PLACE:" + placingShipIdx + ":" + row + ":" + col + ":" + orient);
    }

    placingShipIdx++;
    if (placingShipIdx >= 5) {
      if (mode == BSH_ONLINE) {
        network.send("READY");
        selfReady = true;
        if (opponentReady) {
          startPlay();
        }
        // else wait for opponent ready
      } else if (mode == BSH_AI_MODE) {
        boards[1].placeShipsRandom();
        startPlay();
      } else {
        // Two player: switch to pass screen
        if (placingPlayer == 1) {
          placingPlayer = 2;
          placingShipIdx = 0;
          placingHorizontal = true;
          state = BSH_PASS_SCREEN;
        } else {
          startPlay();
        }
      }
    }
  }

  // Check if "Ready" button is clicked after all ships placed (online waiting)
  void handleReadyButtonClick() {
    float bw = 200, bh = 50;
    float bx = CANVAS_W / 2;
    float by = 770;
    if (mouseX > bx - bw/2 && mouseX < bx + bw/2 && mouseY > by - bh/2 && mouseY < by + bh/2) {
      // Already handled in placement flow
    }
  }

  void handlePassScreenClick() {
    float bw = 200, bh = 50;
    float bx = CANVAS_W / 2;
    float by = 500;
    if (mouseX > bx - bw/2 && mouseX < bx + bw/2 && mouseY > by - bh/2 && mouseY < by + bh/2) {
      state = BSH_PLACING;
    }
  }

  void handlePlayClick() {
    if (mode == BSH_AI_MODE && currentPlayer == 2) return;
    if (mode == BSH_ONLINE && currentPlayer != playerRole) return;

    int[] cell = renderer.getAttackCellAtMouse();
    if (cell == null) return;
    int row = cell[0];
    int col = cell[1];

    int attackerIdx = (currentPlayer == 1) ? 0 : 1;
    if (boards[attackerIdx].attackGrid[row][col] != 0) return;

    if (mode == BSH_ONLINE) {
      network.send("ATTACK:" + row + ":" + col);
      // Don't process locally — wait for RESULT from opponent
    } else {
      executeAttack(row, col);
    }
  }

  void handleGameOverClick() {
    float elapsed = (millis() - gameOverTime) / 1000.0;
    if (elapsed < 1.0) return;

    float bw = 200, bh = 50;
    float rx = CANVAS_W / 2 - 110;
    float ry = 850;
    if (mouseX > rx - bw/2 && mouseX < rx + bw/2 && mouseY > ry - bh/2 && mouseY < ry + bh/2) {
      if (mode == BSH_ONLINE) network.send("REMATCH");
      startPlacement(mode);
    }
    float mx = CANVAS_W / 2 + 110;
    if (mouseX > mx - bw/2 && mouseX < mx + bw/2 && mouseY > ry - bh/2 && mouseY < ry + bh/2) {
      if (mode == BSH_ONLINE) network.stop();
      state = BSH_MENU;
      particles.clear();
    }
  }

  // Network

  void bshReceive() {
    if (!network.isPeerConnected()) {
      network.stop();
      disconnectMessage = "Opponent disconnected";
      disconnectMessageTime = millis();
      state = BSH_MENU;
      particles.clear();
      return;
    }
    String data = network.receiveNext();
    while (data != null) {
      if (data.startsWith("PLACE:")) {
        // Opponent placed a ship (we don't need to process this for gameplay)
      } else if (data.equals("READY")) {
        opponentReady = true;
        if (selfReady) {
          startPlay();
        }
      } else if (data.startsWith("ATTACK:")) {
        String[] parts = data.split(":");
        if (parts.length == 3) {
          try {
            int row = Integer.parseInt(parts[1]);
            int col = Integer.parseInt(parts[2]);
            // Process attack on our board
            int defenderIdx = (currentPlayer == 1) ? 1 : 0;
            int attackerIdx = (currentPlayer == 1) ? 0 : 1;
            BSHBoard defenderBoard = boards[defenderIdx];
            int result = defenderBoard.attack(row, col);
            String sunkName = "";
            if (result == 2) {
              sunkName = defenderBoard.getSunkShipName(row, col);
            }
            boards[attackerIdx].markAttack(row, col, result, sunkName);

            String resultStr;
            if (result == 2) {
              resultStr = "2:" + sunkName;
            } else {
              resultStr = "" + result;
            }
            network.send("RESULT:" + row + ":" + col + ":" + resultStr);

            lastAttackRow = row;
            lastAttackCol = col;
            lastAttackResult = result;
            lastSunkName = sunkName;
            lastAttackTime = millis();

            if (result == 1 || result == 2) {
              spawnHitParticles(row, col);
            }

            if (defenderBoard.allSunk()) {
              winner = currentPlayer;
              state = BSH_GAMEOVER;
              gameOverTime = millis();
              spawnWinParticles(winner);
            } else {
              currentPlayer = (currentPlayer == 1) ? 2 : 1;
            }
          } catch (Exception e) {}
        }
      } else if (data.startsWith("RESULT:")) {
        String[] parts = data.split(":");
        if (parts.length >= 4) {
          try {
            int row = Integer.parseInt(parts[1]);
            int col = Integer.parseInt(parts[2]);
            int result;
            String sunkName = "";
            if (parts[3].equals("2")) {
              result = 2;
              if (parts.length >= 5) sunkName = parts[4];
            } else {
              result = Integer.parseInt(parts[3]);
            }
            // Mark on our attack grid
            int myIdx = playerRole - 1;
            boards[myIdx].markAttack(row, col, result, sunkName);

            lastAttackRow = row;
            lastAttackCol = col;
            lastAttackResult = result;
            lastSunkName = sunkName;
            lastAttackTime = millis();

            if (result == 1 || result == 2) {
              spawnHitParticles(row, col);
            }

            // Check if opponent's fleet is sunk
            // We count sunk markers on our attack grid
            int sunkCount = 0;
            for (int r2 = 0; r2 < 10; r2++)
              for (int c2 = 0; c2 < 10; c2++)
                if (boards[myIdx].attackGrid[r2][c2] == 3) sunkCount++;
            // 5+4+3+3+2 = 17 total ship cells
            if (sunkCount >= 17) {
              winner = playerRole;
              state = BSH_GAMEOVER;
              gameOverTime = millis();
              spawnWinParticles(winner);
            } else {
              currentPlayer = (currentPlayer == 1) ? 2 : 1;
            }
          } catch (Exception e) {}
        }
      } else if (data.equals("REMATCH")) {
        startPlacement(BSH_ONLINE);
      }
      data = network.receiveNext();
    }
  }

  void handleLobbyClick() {
    int action = lobbyHandleClick(lobbyState, roomCode, network.joining);
    switch (action) {
      case LOBBY_ACTION_HOST:
        network.startHosting();
        lobbyState = LOBBY_HOSTING;
        break;
      case LOBBY_ACTION_JOIN_SCREEN:
        lobbyState = LOBBY_JOINING;
        roomCode = "";
        break;
      case LOBBY_ACTION_CONNECT:
        network.joinGame(roomCode);
        break;
      case LOBBY_ACTION_BACK:
      case LOBBY_ACTION_CANCEL:
        network.stop();
        state = BSH_MENU;
        break;
    }
  }

  void onServerEvent(Server s, Client c) {
    network.onServerEvent(s, c);
    playerRole = 1;
    startPlacement(BSH_ONLINE);
  }

  void onDisconnectEvent(Client c) {
    network.onDisconnectEvent(c);
    state = BSH_MENU;
    particles.clear();
  }

  // Particles

  void spawnWinParticles(int w) {
    color c = (w == 1) ? BSH_COLOR_P1 : BSH_COLOR_P2;
    for (int i = 0; i < 100; i++) {
      Particle p = new Particle(random(CANVAS_W), random(-20, 20), c);
      p.vy = random(1, 4);
      p.vx = random(-2, 2);
      p.sz = random(4, 10);
      p.life = random(80, 150);
      p.maxLife = p.life;
      particles.add(p);
    }
  }

  void spawnHitParticles(int row, int col) {
    float cx = renderer.atkOffsetX + col * renderer.atkCellSize + renderer.atkCellSize / 2.0;
    float cy = renderer.atkOffsetY + row * renderer.atkCellSize + renderer.atkCellSize / 2.0;
    for (int i = 0; i < 15; i++) {
      Particle p = new Particle(cx, cy, BSH_COLOR_HIT);
      p.vx = random(-3, 3);
      p.vy = random(-3, 3);
      p.sz = random(3, 7);
      p.life = random(20, 50);
      p.maxLife = p.life;
      particles.add(p);
    }
  }
}
