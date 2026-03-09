// NMM Game States
final int NMM_MENU = 0;
final int NMM_PLAYING = 1;
final int NMM_GAMEOVER = 2;
final int NMM_HOWTO = 3;
final int NMM_LOBBY = 4;

// NMM Game Modes
final int NMM_TWO_PLAYER = 0;
final int NMM_AI_MODE = 1;
final int NMM_ONLINE = 2;

class NMMGame extends GameBase {
  int state;
  int mode;
  int currentPlayer;
  int winner; // 0=none, 1=P1, 2=P2
  NMMBoard board;
  NMMRenderer renderer;
  ArrayList<Particle> particles;
  int howToPage;

  boolean removing;
  int selectedPiece; // -1 if none

  // Mill highlight
  int[] lastMillPositions;
  int lastMillTime;

  // AI
  int[] aiMove;
  int aiMoveTime;
  boolean aiThinking;

  // Game over
  int gameOverTime;

  // Online
  GameNetwork network;
  int lobbyState;
  int playerRole;
  String roomCode = "";
  String disconnectMessage = "";
  int disconnectMessageTime = 0;

  NMMGame() {
    particles = new ArrayList<Particle>();
    renderer = new NMMRenderer(this);
    network = new GameNetwork();
  }

  String getName() { return "Nine Men's Morris"; }
  color getColor() { return color(160, 120, 60); }

  void init() {
    state = NMM_MENU;
    particles.clear();
    aiThinking = false;
    disconnectMessage = "";
  }

  void startPlay(int m) {
    mode = m;
    board = new NMMBoard();
    currentPlayer = 1;
    winner = 0;
    removing = false;
    selectedPiece = -1;
    state = NMM_PLAYING;
    particles.clear();
    lastMillPositions = null;
    lastMillTime = 0;
    aiThinking = false;
  }

  void render() {
    updateParticles(particles);

    switch (state) {
      case NMM_MENU:
        renderer.drawMenu();
        if (disconnectMessage.length() > 0 && millis() - disconnectMessageTime < 3000) {
          textAlign(CENTER, CENTER);
          textSize(16);
          fill(231, 76, 60);
          text(disconnectMessage, CANVAS_W / 2, CANVAS_H - 40);
        }
        break;
      case NMM_LOBBY:
        if (network.connected && !network.isHost) {
          playerRole = 2;
          startPlay(NMM_ONLINE);
          break;
        }
        renderer.drawLobby();
        break;
      case NMM_PLAYING:
        if (mode == NMM_AI_MODE && currentPlayer == 2 && !aiThinking) {
          startAIMove();
        }
        if (aiThinking) updateAI();
        if (mode == NMM_ONLINE) nmmReceive();
        renderer.drawGame();
        break;
      case NMM_GAMEOVER:
        if (mode == NMM_ONLINE) nmmReceive();
        renderer.drawGame();
        break;
      case NMM_HOWTO:
        renderer.drawHowTo(howToPage);
        break;
    }
  }

  void onMousePressed() {
    switch (state) {
      case NMM_MENU:
        handleMenuClick();
        break;
      case NMM_LOBBY:
        handleLobbyClick();
        break;
      case NMM_PLAYING:
        handlePlayClick();
        break;
      case NMM_GAMEOVER:
        handleGameOverClick();
        break;
      case NMM_HOWTO:
        int nav = handleHowToNav(howToPage, 4);
        if (nav == -1) state = NMM_MENU;
        else howToPage = nav;
        break;
    }
  }

  void onKeyPressed() {
    if (state == NMM_LOBBY && lobbyState == LOBBY_JOINING) {
      if (key == ENTER || key == RETURN) {
        if (roomCode.length() == 8) network.joinGame(roomCode);
        return;
      }
      roomCode = lobbyHandleKey(roomCode);
    }
  }

  void onEscape() {
    switch (state) {
      case NMM_MENU:
        returnToLauncher();
        break;
      case NMM_LOBBY:
        network.stop();
        state = NMM_MENU;
        break;
      case NMM_PLAYING:
      case NMM_GAMEOVER:
        if (mode == NMM_ONLINE) network.stop();
        state = NMM_MENU;
        particles.clear();
        break;
      case NMM_HOWTO:
        state = NMM_MENU;
        break;
    }
  }

  void handleMenuClick() {
    float bw = 200, bh = 50;
    if (mouseX > CANVAS_W/2 - bw/2 && mouseX < CANVAS_W/2 + bw/2) {
      if (mouseY > 310 - bh/2 && mouseY < 310 + bh/2) {
        startPlay(NMM_TWO_PLAYER);
      }
      if (mouseY > 375 - bh/2 && mouseY < 375 + bh/2) {
        startPlay(NMM_AI_MODE);
      }
      if (mouseY > 440 - bh/2 && mouseY < 440 + bh/2) {
        state = NMM_LOBBY;
        lobbyState = LOBBY_CHOOSE;
        roomCode = "";
      }
      if (mouseY > 505 - bh/2 && mouseY < 505 + bh/2) {
        state = NMM_HOWTO;
        howToPage = 0;
      }
      if (mouseY > 570 - bh/2 && mouseY < 570 + bh/2) {
        returnToLauncher();
      }
    }
  }

  void handlePlayClick() {
    if (mode == NMM_AI_MODE && currentPlayer == 2) return;
    if (mode == NMM_ONLINE && currentPlayer != playerRole) return;

    int clickedPos = renderer.getClickedPosition();
    if (clickedPos == -1) return;

    if (removing) {
      handleRemoval(clickedPos);
      return;
    }

    int phase = board.getPhase(currentPlayer);
    if (phase == NMM_PHASE_PLACE) {
      handlePlacement(clickedPos);
    } else {
      handleMovement(clickedPos);
    }
  }

  void handlePlacement(int pos) {
    if (board.positions[pos] != 0) return;
    board.placePiece(pos, currentPlayer);
    if (mode == NMM_ONLINE) network.send("PLACE:" + pos);
    spawnPlaceParticles(pos);

    if (board.formsMill(pos, currentPlayer)) {
      lastMillPositions = board.getMillPositions(pos, currentPlayer);
      lastMillTime = millis();
      removing = true;
      return;
    }
    endTurn();
  }

  void handleMovement(int clickedPos) {
    if (selectedPiece == -1) {
      if (board.positions[clickedPos] == currentPlayer) {
        int phase = board.getPhase(currentPlayer);
        boolean canMove = false;
        if (phase == NMM_PHASE_FLY) {
          for (int j = 0; j < 24; j++) {
            if (board.positions[j] == 0) { canMove = true; break; }
          }
        } else {
          for (int n : board.adjacency[clickedPos]) {
            if (board.positions[n] == 0) { canMove = true; break; }
          }
        }
        if (canMove) selectedPiece = clickedPos;
      }
    } else {
      if (clickedPos == selectedPiece) {
        selectedPiece = -1;
        return;
      }
      if (board.positions[clickedPos] == currentPlayer) {
        int phase = board.getPhase(currentPlayer);
        boolean canMove = false;
        if (phase == NMM_PHASE_FLY) {
          for (int j = 0; j < 24; j++) {
            if (board.positions[j] == 0) { canMove = true; break; }
          }
        } else {
          for (int n : board.adjacency[clickedPos]) {
            if (board.positions[n] == 0) { canMove = true; break; }
          }
        }
        if (canMove) {
          selectedPiece = clickedPos;
        }
        return;
      }
      if (board.positions[clickedPos] != 0) return;

      int phase = board.getPhase(currentPlayer);
      if (phase == NMM_PHASE_MOVE && !board.isAdjacent(selectedPiece, clickedPos)) return;

      int fromPos = selectedPiece;
      board.movePiece(selectedPiece, clickedPos, currentPlayer);
      if (mode == NMM_ONLINE) network.send("MOVE:" + fromPos + ":" + clickedPos);
      spawnPlaceParticles(clickedPos);
      selectedPiece = -1;

      if (board.formsMill(clickedPos, currentPlayer)) {
        lastMillPositions = board.getMillPositions(clickedPos, currentPlayer);
        lastMillTime = millis();
        removing = true;
        return;
      }
      endTurn();
    }
  }

  void handleRemoval(int pos) {
    if (!board.canRemove(pos, currentPlayer)) return;
    board.removePiece(pos);
    if (mode == NMM_ONLINE) network.send("REMOVE:" + pos);
    spawnRemoveParticles(pos);
    removing = false;
    endTurn();
  }

  void endTurn() {
    selectedPiece = -1;
    int opponent = (currentPlayer == 1) ? 2 : 1;

    // Check win conditions
    int oppPhase = board.getPhase(opponent);
    if (oppPhase != NMM_PHASE_PLACE) {
      if (board.piecesOnBoard[opponent] < 3) {
        winner = currentPlayer;
        state = NMM_GAMEOVER;
        gameOverTime = millis();
        spawnWinParticles();
        return;
      }
      if (!board.hasValidMoves(opponent, oppPhase)) {
        winner = currentPlayer;
        state = NMM_GAMEOVER;
        gameOverTime = millis();
        spawnWinParticles();
        return;
      }
    }

    currentPlayer = opponent;
  }

  void handleGameOverClick() {
    float elapsed = (millis() - gameOverTime) / 1000.0;
    if (elapsed < 1.5) return;

    float bw = 200, bh = 50;
    float rx = CANVAS_W/2 - 110;
    float ry = 70;
    if (mouseX > rx - bw/2 && mouseX < rx + bw/2 && mouseY > ry - bh/2 && mouseY < ry + bh/2) {
      if (mode == NMM_ONLINE) network.send("REMATCH");
      startPlay(mode);
    }
    float mx = CANVAS_W/2 + 110;
    float my = 70;
    if (mouseX > mx - bw/2 && mouseX < mx + bw/2 && mouseY > my - bh/2 && mouseY < my + bh/2) {
      if (mode == NMM_ONLINE) network.stop();
      state = NMM_MENU;
      particles.clear();
    }
  }

  // AI

  void startAIMove() {
    aiThinking = true;
    aiMoveTime = millis();
    int phase = board.getPhase(2);
    aiMove = nmmFindBestMove(board, 2, removing, selectedPiece);
  }

  void updateAI() {
    if (!aiThinking) return;
    if (millis() - aiMoveTime < 500) return;

    if (aiMove != null) {
      if (removing) {
        handleRemoval(aiMove[0]);
      } else {
        int phase = board.getPhase(2);
        if (phase == NMM_PHASE_PLACE) {
          handlePlacement(aiMove[0]);
        } else {
          board.movePiece(aiMove[0], aiMove[1], 2);
          spawnPlaceParticles(aiMove[1]);
          selectedPiece = -1;
          if (board.formsMill(aiMove[1], 2)) {
            lastMillPositions = board.getMillPositions(aiMove[1], 2);
            lastMillTime = millis();
            removing = true;
            // Need to find removal move
            aiThinking = false;
            startAIMove();
            return;
          }
          endTurn();
        }
      }
    }
    aiThinking = false;
  }

  // Particles

  void spawnPlaceParticles(int pos) {
    float[] xy = renderer.nmmGetPos(pos);
    color c = (currentPlayer == 1) ? NMM_COLOR_P1 : NMM_COLOR_P2;
    for (int i = 0; i < 8; i++) {
      particles.add(new Particle(xy[0] + random(-5, 5), xy[1] + random(-5, 5), c));
    }
  }

  void spawnRemoveParticles(int pos) {
    float[] xy = renderer.nmmGetPos(pos);
    for (int i = 0; i < 15; i++) {
      particles.add(new Particle(xy[0] + random(-8, 8), xy[1] + random(-8, 8), NMM_COLOR_REMOVE));
    }
  }

  void spawnWinParticles() {
    color c = (winner == 1) ? NMM_COLOR_P1 : NMM_COLOR_P2;
    for (int i = 0; i < 80; i++) {
      Particle p = new Particle(random(CANVAS_W), random(-20, 20), c);
      p.vy = random(1, 4);
      p.vx = random(-2, 2);
      p.sz = random(4, 10);
      p.life = random(60, 120);
      p.maxLife = p.life;
      particles.add(p);
    }
  }

  // Network

  void nmmReceive() {
    if (!network.isPeerConnected()) {
      network.stop();
      disconnectMessage = "Opponent disconnected";
      disconnectMessageTime = millis();
      state = NMM_MENU;
      particles.clear();
      return;
    }
    String data = network.receiveNext();
    while (data != null) {
      if (data.startsWith("PLACE:")) {
        try {
          int pos = Integer.parseInt(data.split(":")[1]);
          if (board.positions[pos] == 0) {
            board.placePiece(pos, currentPlayer);
            spawnPlaceParticles(pos);
            if (board.formsMill(pos, currentPlayer)) {
              lastMillPositions = board.getMillPositions(pos, currentPlayer);
              lastMillTime = millis();
              removing = true;
            } else {
              endTurn();
            }
          }
        } catch (Exception e) {}
      } else if (data.startsWith("MOVE:")) {
        String[] parts = data.split(":");
        if (parts.length == 3) {
          try {
            int fromPos = Integer.parseInt(parts[1]);
            int toPos = Integer.parseInt(parts[2]);
            board.movePiece(fromPos, toPos, currentPlayer);
            spawnPlaceParticles(toPos);
            selectedPiece = -1;
            if (board.formsMill(toPos, currentPlayer)) {
              lastMillPositions = board.getMillPositions(toPos, currentPlayer);
              lastMillTime = millis();
              removing = true;
            } else {
              endTurn();
            }
          } catch (Exception e) {}
        }
      } else if (data.startsWith("REMOVE:")) {
        try {
          int pos = Integer.parseInt(data.split(":")[1]);
          board.removePiece(pos);
          spawnRemoveParticles(pos);
          removing = false;
          endTurn();
        } catch (Exception e) {}
      } else if (data.equals("REMATCH")) {
        startPlay(NMM_ONLINE);
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
        state = NMM_MENU;
        break;
    }
  }

  void onServerEvent(Server s, Client c) {
    network.onServerEvent(s, c);
    playerRole = 1;
    startPlay(NMM_ONLINE);
  }

  void onDisconnectEvent(Client c) {
    network.onDisconnectEvent(c);
    state = NMM_MENU;
    particles.clear();
  }
}
