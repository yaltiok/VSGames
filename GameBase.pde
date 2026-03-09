abstract class GameBase {
  abstract String getName();
  abstract color getColor();
  abstract void init();
  abstract void render();
  abstract void onMousePressed();
  abstract void onKeyPressed();

  void onEscape() {
    returnToLauncher();
  }

  void returnToLauncher() {
    activeGame = null;
    appState = APP_LAUNCHER;
  }

  void onServerEvent(Server s, Client c) {}
  void onDisconnectEvent(Client c) {}
}
