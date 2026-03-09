class REVBoard {
  int[][] grid;
  int[][] REV_DIRS = {
    {-1, -1}, {-1, 0}, {-1, 1},
    {0, -1},           {0, 1},
    {1, -1},  {1, 0},  {1, 1}
  };

  REVBoard() {
    grid = new int[8][8];
    grid[3][3] = 2;
    grid[3][4] = 1;
    grid[4][3] = 1;
    grid[4][4] = 2;
  }

  boolean isOnBoard(int r, int c) {
    return r >= 0 && r < 8 && c >= 0 && c < 8;
  }

  ArrayList<int[]> getFlips(int row, int col, int player) {
    ArrayList<int[]> flips = new ArrayList<int[]>();
    if (!isOnBoard(row, col) || grid[row][col] != 0) return flips;

    int opponent = (player == 1) ? 2 : 1;
    for (int[] d : REV_DIRS) {
      ArrayList<int[]> line = new ArrayList<int[]>();
      int r = row + d[0];
      int c = col + d[1];
      while (isOnBoard(r, c) && grid[r][c] == opponent) {
        line.add(new int[]{r, c});
        r += d[0];
        c += d[1];
      }
      if (line.size() > 0 && isOnBoard(r, c) && grid[r][c] == player) {
        flips.addAll(line);
      }
    }
    return flips;
  }

  boolean makeMove(int row, int col, int player) {
    ArrayList<int[]> flips = getFlips(row, col, player);
    if (flips.size() == 0) return false;
    grid[row][col] = player;
    for (int[] f : flips) {
      grid[f[0]][f[1]] = player;
    }
    return true;
  }

  ArrayList<int[]> getValidMoves(int player) {
    ArrayList<int[]> moves = new ArrayList<int[]>();
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (grid[r][c] == 0 && getFlips(r, c, player).size() > 0) {
          moves.add(new int[]{r, c});
        }
      }
    }
    return moves;
  }

  boolean hasValidMoves(int player) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (grid[r][c] == 0 && getFlips(r, c, player).size() > 0) {
          return true;
        }
      }
    }
    return false;
  }

  int[] countDiscs() {
    int b = 0, w = 0;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (grid[r][c] == 1) b++;
        else if (grid[r][c] == 2) w++;
      }
    }
    return new int[]{b, w};
  }

  boolean isGameOver() {
    return !hasValidMoves(1) && !hasValidMoves(2);
  }

  int getWinner() {
    if (!isGameOver()) return 0;
    int[] counts = countDiscs();
    if (counts[0] > counts[1]) return 1;
    if (counts[1] > counts[0]) return 2;
    return 3;
  }

  REVBoard copy() {
    REVBoard b = new REVBoard();
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        b.grid[r][c] = grid[r][c];
      }
    }
    return b;
  }
}
