import processing.net.*;

final int APP_LAUNCHER = 0;
final int APP_INGAME = 1;

final int CANVAS_W = 800;
final int CANVAS_H = 900;
final String VERSION = "v1.3.0";

int appState = APP_LAUNCHER;
GameBase[] games;
GameBase activeGame;

void setup() {
  size(800, 900);
  smooth();
  games = new GameBase[] {
    new SXOGame(),
    new NMMGame(),
    new MNGGame(),
    new REVGame(),
    new C4Game(),
    new DABGame(),
    new GMKGame(),
    new CHKGame(),
    new HEXGame(),
    new QRTGame(),
    new QRDGame(),
    new BSHGame()
  };
}

void draw() {
  if (appState == APP_LAUNCHER) {
    drawLauncher();
  } else if (activeGame != null) {
    activeGame.render();
    drawBackButton();
  }
}

void mousePressed() {
  if (appState == APP_LAUNCHER) {
    handleLauncherClick();
  } else if (activeGame != null) {
    if (isBackButtonClicked()) {
      activeGame.onEscape();
      return;
    }
    activeGame.onMousePressed();
  }
}

void keyPressed() {
  boolean isEsc = (key == ESC);
  if (isEsc) key = 0;

  if (appState == APP_INGAME && activeGame != null) {
    if (isEsc) {
      activeGame.onEscape();
    } else {
      activeGame.onKeyPressed();
    }
  }
}

void launchGame(int index) {
  activeGame = games[index];
  activeGame.init();
  appState = APP_INGAME;
}

// Network callbacks — forwarded to active game
void serverEvent(Server s, Client c) {
  if (activeGame != null) activeGame.onServerEvent(s, c);
}

void disconnectEvent(Client c) {
  if (activeGame != null) activeGame.onDisconnectEvent(c);
}

// Global back button (drawn on top of every game screen)

final float BACK_BTN_X = 8;
final float BACK_BTN_Y = 8;
final float BACK_BTN_W = 60;
final float BACK_BTN_H = 28;

void drawBackButton() {
  boolean hover = mouseX > BACK_BTN_X && mouseX < BACK_BTN_X + BACK_BTN_W &&
                  mouseY > BACK_BTN_Y && mouseY < BACK_BTN_Y + BACK_BTN_H;
  noStroke();
  fill(0, hover ? 160 : 100);
  rect(BACK_BTN_X, BACK_BTN_Y, BACK_BTN_W, BACK_BTN_H, 6);
  textAlign(CENTER, CENTER);
  textSize(14);
  fill(255, hover ? 255 : 180);
  text("\u2190 Back", BACK_BTN_X + BACK_BTN_W / 2, BACK_BTN_Y + BACK_BTN_H / 2);
}

boolean isBackButtonClicked() {
  return mouseX > BACK_BTN_X && mouseX < BACK_BTN_X + BACK_BTN_W &&
         mouseY > BACK_BTN_Y && mouseY < BACK_BTN_Y + BACK_BTN_H;
}

// Launcher UI

final int GRID_COLS = 3;
final int GRID_BTN_W = 210;
final int GRID_BTN_H = 70;
final int GRID_GAP = 16;

void drawLauncher() {
  background(30, 30, 40);

  // Floating decorative marks
  for (int i = 0; i < 12; i++) {
    float x = noise(i * 10 + millis() * 0.0003) * CANVAS_W;
    float y = noise(i * 20 + 500 + millis() * 0.0003) * CANVAS_H;
    stroke(100, 100, 120, 30);
    strokeWeight(2);
    noFill();
    if (i % 3 == 0) {
      float s = 15;
      line(x - s, y - s, x + s, y + s);
      line(x + s, y - s, x - s, y + s);
    } else if (i % 3 == 1) {
      ellipse(x, y, 30, 30);
    } else {
      rect(x - 10, y - 10, 20, 20);
    }
  }

  // Title
  float bounce = sin(millis() * 0.003) * 8;
  textAlign(CENTER, CENTER);
  textSize(56);
  fill(255);
  text("VS GAMES", CANVAS_W / 2, 150 + bounce);

  textSize(16);
  fill(150);
  text("Choose a game", CANVAS_W / 2, 210);

  // Version
  textSize(11);
  fill(80);
  textAlign(RIGHT, BOTTOM);
  text(VERSION, CANVAS_W - 12, CANVAS_H - 8);

  // Game buttons — grid layout
  int rows = (games.length + GRID_COLS - 1) / GRID_COLS;
  float gridW = GRID_COLS * GRID_BTN_W + (GRID_COLS - 1) * GRID_GAP;
  float gridH = rows * GRID_BTN_H + (rows - 1) * GRID_GAP;
  float startX = (CANVAS_W - gridW) / 2 + GRID_BTN_W / 2;
  float startY = 260 + (CANVAS_H - 260 - gridH) / 2 + GRID_BTN_H / 2;

  for (int i = 0; i < games.length; i++) {
    int col = i % GRID_COLS;
    int row = i / GRID_COLS;
    float bx = startX + col * (GRID_BTN_W + GRID_GAP);
    float by = startY + row * (GRID_BTN_H + GRID_GAP);
    drawLauncherButton(bx, by, games[i].getName(), games[i].getColor());
  }
}

void handleLauncherClick() {
  int rows = (games.length + GRID_COLS - 1) / GRID_COLS;
  float gridW = GRID_COLS * GRID_BTN_W + (GRID_COLS - 1) * GRID_GAP;
  float gridH = rows * GRID_BTN_H + (rows - 1) * GRID_GAP;
  float startX = (CANVAS_W - gridW) / 2 + GRID_BTN_W / 2;
  float startY = 260 + (CANVAS_H - 260 - gridH) / 2 + GRID_BTN_H / 2;

  for (int i = 0; i < games.length; i++) {
    int col = i % GRID_COLS;
    int row = i / GRID_COLS;
    float bx = startX + col * (GRID_BTN_W + GRID_GAP);
    float by = startY + row * (GRID_BTN_H + GRID_GAP);
    if (mouseX > bx - GRID_BTN_W / 2 && mouseX < bx + GRID_BTN_W / 2 &&
        mouseY > by - GRID_BTN_H / 2 && mouseY < by + GRID_BTN_H / 2) {
      launchGame(i);
      return;
    }
  }
}

void drawLauncherButton(float x, float y, String label, color c) {
  boolean hover = mouseX > x - GRID_BTN_W/2 && mouseX < x + GRID_BTN_W/2 &&
                  mouseY > y - GRID_BTN_H/2 && mouseY < y + GRID_BTN_H/2;
  noStroke();
  fill(c, hover ? 200 : 120);
  rect(x - GRID_BTN_W/2, y - GRID_BTN_H/2, GRID_BTN_W, GRID_BTN_H, 10);
  textAlign(CENTER, CENTER);
  textSize(20);
  fill(255);
  text(label, x, y);
}
