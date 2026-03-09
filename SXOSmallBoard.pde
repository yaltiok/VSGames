class SXOSmallBoard {
  int[] cells;
  int winner; // 0=ongoing, 1=X, 2=O, 3=draw

  SXOSmallBoard() {
    cells = new int[9];
    winner = 0;
  }

  boolean makeMove(int idx, int player) {
    if (idx < 0 || idx > 8 || cells[idx] != 0 || winner != 0) return false;
    cells[idx] = player;
    checkWinner();
    return true;
  }

  void checkWinner() {
    int[][] lines = {
      {0,1,2}, {3,4,5}, {6,7,8},
      {0,3,6}, {1,4,7}, {2,5,8},
      {0,4,8}, {2,4,6}
    };
    for (int[] l : lines) {
      if (cells[l[0]] != 0 && cells[l[0]] == cells[l[1]] && cells[l[1]] == cells[l[2]]) {
        winner = cells[l[0]];
        return;
      }
    }
    if (isFull()) winner = 3;
  }

  boolean isFull() {
    for (int c : cells) {
      if (c == 0) return false;
    }
    return true;
  }

  SXOSmallBoard copy() {
    SXOSmallBoard sb = new SXOSmallBoard();
    sb.cells = new int[9];
    arrayCopy(this.cells, sb.cells);
    sb.winner = this.winner;
    return sb;
  }
}
