// Lobby sub-states (shared across all games)
final int LOBBY_CHOOSE = 0;
final int LOBBY_HOSTING = 1;
final int LOBBY_JOINING = 2;

// Lobby action codes returned by lobbyHandleClick
final int LOBBY_ACTION_NONE = 0;
final int LOBBY_ACTION_HOST = 1;
final int LOBBY_ACTION_JOIN_SCREEN = 2;
final int LOBBY_ACTION_CONNECT = 3;
final int LOBBY_ACTION_BACK = 4;
final int LOBBY_ACTION_CANCEL = 5;

void drawLobbyUI(int lobbyState, GameNetwork network, String roomCode, color accentColor) {
  textAlign(CENTER, CENTER);

  switch (lobbyState) {
    case LOBBY_CHOOSE:
      textSize(32);
      fill(255);
      text("Online Game", CANVAS_W / 2, 150);
      textSize(14);
      fill(150);
      text("Play over local network", CANVAS_W / 2, 190);
      drawLobbyButton(CANVAS_W / 2, 320, "Host Game", accentColor);
      drawLobbyButton(CANVAS_W / 2, 400, "Join Game", color(52, 152, 219));
      drawLobbyButton(CANVAS_W / 2, 520, "Back", color(120));
      break;

    case LOBBY_HOSTING:
      textSize(24);
      fill(255);
      text("Waiting for opponent...", CANVAS_W / 2, 180);
      textSize(48);
      fill(accentColor);
      text(network.hostRoomCode, CANVAS_W / 2, 290);
      textSize(14);
      fill(150);
      text("Share this room code with your opponent", CANVAS_W / 2, 340);
      int dots = (millis() / 500) % 4;
      String dotStr = "";
      for (int i = 0; i < dots; i++) dotStr += ".";
      textSize(16);
      fill(180);
      text("Waiting" + dotStr, CANVAS_W / 2, 400);
      drawLobbyButton(CANVAS_W / 2, 520, "Cancel", color(120));
      break;

    case LOBBY_JOINING:
      textSize(24);
      fill(255);
      text("Enter Room Code", CANVAS_W / 2, 180);
      drawLobbyCodeInput(CANVAS_W / 2, 290, roomCode);
      textSize(12);
      fill(150);
      text("Type the 8-character hex code and press Enter", CANVAS_W / 2, 350);
      if (network.joining) {
        int jdots = (millis() / 500) % 4;
        String jdotStr = "";
        for (int i = 0; i < jdots; i++) jdotStr += ".";
        textSize(18);
        fill(accentColor);
        text("Connecting" + jdotStr, CANVAS_W / 2, 430);
      } else if (network.joinError.length() > 0) {
        textSize(16);
        fill(color(231, 76, 60));
        text(network.joinError, CANVAS_W / 2, 390);
        if (roomCode.length() == 8) {
          drawLobbyButton(CANVAS_W / 2, 430, "Retry", accentColor);
        }
      } else if (roomCode.length() == 8) {
        drawLobbyButton(CANVAS_W / 2, 430, "Connect", accentColor);
      } else {
        noStroke();
        fill(80, 80, 100, 80);
        rect(CANVAS_W / 2 - 100, 430 - 25, 200, 50, 8);
        textAlign(CENTER, CENTER);
        textSize(20);
        fill(120);
        text("Connect", CANVAS_W / 2, 430);
      }
      drawLobbyButton(CANVAS_W / 2, 520, "Back", color(120));
      break;
  }
}

int lobbyHandleClick(int lobbyState, String roomCode, boolean joining) {
  float bw = 200, bh = 50;
  switch (lobbyState) {
    case LOBBY_CHOOSE:
      if (lobbyButtonHit(CANVAS_W / 2, 320, bw, bh)) return LOBBY_ACTION_HOST;
      if (lobbyButtonHit(CANVAS_W / 2, 400, bw, bh)) return LOBBY_ACTION_JOIN_SCREEN;
      if (lobbyButtonHit(CANVAS_W / 2, 520, bw, bh)) return LOBBY_ACTION_BACK;
      break;
    case LOBBY_HOSTING:
      if (lobbyButtonHit(CANVAS_W / 2, 520, bw, bh)) return LOBBY_ACTION_CANCEL;
      break;
    case LOBBY_JOINING:
      if (!joining && roomCode.length() == 8 && lobbyButtonHit(CANVAS_W / 2, 430, bw, bh))
        return LOBBY_ACTION_CONNECT;
      if (lobbyButtonHit(CANVAS_W / 2, 520, bw, bh)) return LOBBY_ACTION_BACK;
      break;
  }
  return LOBBY_ACTION_NONE;
}

String lobbyHandleKey(String roomCode) {
  if (key == BACKSPACE && roomCode.length() > 0) {
    return roomCode.substring(0, roomCode.length() - 1);
  } else if (roomCode.length() < 8) {
    char k = Character.toUpperCase(key);
    if ((k >= '0' && k <= '9') || (k >= 'A' && k <= 'F')) {
      return roomCode + k;
    }
  }
  return roomCode;
}

boolean lobbyButtonHit(float cx, float cy, float w, float h) {
  return mouseX > cx - w / 2 && mouseX < cx + w / 2 &&
         mouseY > cy - h / 2 && mouseY < cy + h / 2;
}

void drawLobbyButton(float x, float y, String label, color c) {
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

void drawLobbyCodeInput(float x, float y, String code) {
  float boxW = 280, boxH = 60;
  noStroke();
  fill(50, 50, 65);
  rect(x - boxW / 2, y - boxH / 2, boxW, boxH, 8);
  stroke(color(80, 80, 100));
  strokeWeight(2);
  noFill();
  rect(x - boxW / 2, y - boxH / 2, boxW, boxH, 8);

  textAlign(CENTER, CENTER);
  textSize(36);
  fill(255);
  String display = "";
  for (int i = 0; i < 8; i++) {
    if (i < code.length()) {
      display += code.charAt(i);
    } else {
      display += "_";
    }
    if (i == 3) display += " ";
  }
  text(display, x, y);

  if (code.length() < 8 && (millis() / 500) % 2 == 0) {
    float charW = 20;
    float cursorX = x - 80 + code.length() * charW + (code.length() > 3 ? 8 : 0);
    stroke(color(46, 204, 113));
    strokeWeight(2);
    line(cursorX, y - 15, cursorX, y + 15);
  }
}
