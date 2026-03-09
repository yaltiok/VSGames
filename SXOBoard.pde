class SXOBoard {
  SXOSmallBoard[] grids;
  int[] bigGrid; // 0=empty, 1=X, 2=O, 3=draw
  int activeGrid; // -1 = free choice
  int bigWinner; // 0=ongoing, 1=X, 2=O, 3=draw

  SXOBoard() {
    grids = new SXOSmallBoard[9];
    bigGrid = new int[9];
    for (int i = 0; i < 9; i++) {
      grids[i] = new SXOSmallBoard();
    }
    activeGrid = -1;
    bigWinner = 0;
  }

  boolean isValidMove(int gridIdx, int cellIdx) {
    if (gridIdx < 0 || gridIdx > 8 || cellIdx < 0 || cellIdx > 8) return false;
    if (bigWinner != 0) return false;
    if (grids[gridIdx].winner != 0) return false;
    if (grids[gridIdx].cells[cellIdx] != 0) return false;
    if (activeGrid != -1 && activeGrid != gridIdx) return false;
    return true;
  }

  boolean makeMove(int gridIdx, int cellIdx, int player) {
    if (!isValidMove(gridIdx, cellIdx)) return false;
    grids[gridIdx].makeMove(cellIdx, player);

    if (grids[gridIdx].winner != 0) {
      bigGrid[gridIdx] = grids[gridIdx].winner;
      checkBigWinner();
    }

    if (grids[cellIdx].winner != 0) {
      activeGrid = -1;
    } else {
      activeGrid = cellIdx;
    }
    return true;
  }

  void checkBigWinner() {
    int[][] lines = {
      {0,1,2}, {3,4,5}, {6,7,8},
      {0,3,6}, {1,4,7}, {2,5,8},
      {0,4,8}, {2,4,6}
    };
    for (int[] l : lines) {
      if (bigGrid[l[0]] != 0 && bigGrid[l[0]] != 3 &&
          bigGrid[l[0]] == bigGrid[l[1]] && bigGrid[l[1]] == bigGrid[l[2]]) {
        bigWinner = bigGrid[l[0]];
        return;
      }
    }
    boolean allDone = true;
    for (int b : bigGrid) {
      if (b == 0) { allDone = false; break; }
    }
    if (allDone) bigWinner = 3;
  }

  ArrayList<int[]> getValidMoves() {
    ArrayList<int[]> moves = new ArrayList<int[]>();
    for (int g = 0; g < 9; g++) {
      if (activeGrid != -1 && activeGrid != g) continue;
      if (grids[g].winner != 0) continue;
      for (int c = 0; c < 9; c++) {
        if (grids[g].cells[c] == 0) {
          moves.add(new int[]{g, c});
        }
      }
    }
    return moves;
  }

  SXOBoard copy() {
    SXOBoard b = new SXOBoard();
    for (int i = 0; i < 9; i++) {
      b.grids[i] = this.grids[i].copy();
    }
    arrayCopy(this.bigGrid, b.bigGrid);
    b.activeGrid = this.activeGrid;
    b.bigWinner = this.bigWinner;
    return b;
  }
}
