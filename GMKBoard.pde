class GMKBoard {
  int[][] grid;
  int moveCount;

  GMKBoard() {
    grid = new int[GMK_BOARD_SIZE][GMK_BOARD_SIZE];
    moveCount = 0;
  }

  boolean placeStone(int row, int col, int player) {
    if (row < 0 || row >= GMK_BOARD_SIZE || col < 0 || col >= GMK_BOARD_SIZE) return false;
    if (grid[row][col] != 0) return false;
    grid[row][col] = player;
    moveCount++;
    return true;
  }

  int checkWin(int row, int col) {
    int player = grid[row][col];
    if (player == 0) return 0;

    int[][] dirs = {{0, 1}, {1, 0}, {1, 1}, {1, -1}};
    for (int[] d : dirs) {
      int count = 1;
      for (int sign = -1; sign <= 1; sign += 2) {
        int r = row + d[0] * sign;
        int c = col + d[1] * sign;
        while (r >= 0 && r < GMK_BOARD_SIZE && c >= 0 && c < GMK_BOARD_SIZE && grid[r][c] == player) {
          count++;
          r += d[0] * sign;
          c += d[1] * sign;
        }
      }
      if (count >= 5) return player;
    }
    return 0;
  }

  int[] getWinLine(int row, int col) {
    int player = grid[row][col];
    if (player == 0) return null;

    int[][] dirs = {{0, 1}, {1, 0}, {1, 1}, {1, -1}};
    for (int[] d : dirs) {
      int r1 = row, c1 = col;
      int r2 = row, c2 = col;

      int nr = row - d[0];
      int nc = col - d[1];
      while (nr >= 0 && nr < GMK_BOARD_SIZE && nc >= 0 && nc < GMK_BOARD_SIZE && grid[nr][nc] == player) {
        r1 = nr;
        c1 = nc;
        nr -= d[0];
        nc -= d[1];
      }

      nr = row + d[0];
      nc = col + d[1];
      while (nr >= 0 && nr < GMK_BOARD_SIZE && nc >= 0 && nc < GMK_BOARD_SIZE && grid[nr][nc] == player) {
        r2 = nr;
        c2 = nc;
        nr += d[0];
        nc += d[1];
      }

      int count = max(abs(r2 - r1), abs(c2 - c1)) + 1;
      if (count >= 5) {
        return new int[] {r1, c1, r2, c2};
      }
    }
    return null;
  }

  boolean isFull() {
    return moveCount >= GMK_BOARD_SIZE * GMK_BOARD_SIZE;
  }

  GMKBoard copy() {
    GMKBoard b = new GMKBoard();
    for (int r = 0; r < GMK_BOARD_SIZE; r++) {
      for (int c = 0; c < GMK_BOARD_SIZE; c++) {
        b.grid[r][c] = grid[r][c];
      }
    }
    b.moveCount = moveCount;
    return b;
  }
}
