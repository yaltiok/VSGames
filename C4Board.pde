class C4Board {
  int[][] grid;

  C4Board() {
    grid = new int[C4_ROWS][C4_COLS];
  }

  int dropPiece(int col, int player) {
    for (int r = C4_ROWS - 1; r >= 0; r--) {
      if (grid[r][col] == 0) {
        grid[r][col] = player;
        return r;
      }
    }
    return -1;
  }

  boolean isValidDrop(int col) {
    return col >= 0 && col < C4_COLS && grid[0][col] == 0;
  }

  int checkWin() {
    // Horizontal
    for (int r = 0; r < C4_ROWS; r++) {
      for (int c = 0; c <= C4_COLS - 4; c++) {
        int v = grid[r][c];
        if (v != 0 && v == grid[r][c+1] && v == grid[r][c+2] && v == grid[r][c+3]) return v;
      }
    }
    // Vertical
    for (int r = 0; r <= C4_ROWS - 4; r++) {
      for (int c = 0; c < C4_COLS; c++) {
        int v = grid[r][c];
        if (v != 0 && v == grid[r+1][c] && v == grid[r+2][c] && v == grid[r+3][c]) return v;
      }
    }
    // Diagonal down-right
    for (int r = 0; r <= C4_ROWS - 4; r++) {
      for (int c = 0; c <= C4_COLS - 4; c++) {
        int v = grid[r][c];
        if (v != 0 && v == grid[r+1][c+1] && v == grid[r+2][c+2] && v == grid[r+3][c+3]) return v;
      }
    }
    // Diagonal down-left
    for (int r = 0; r <= C4_ROWS - 4; r++) {
      for (int c = 3; c < C4_COLS; c++) {
        int v = grid[r][c];
        if (v != 0 && v == grid[r+1][c-1] && v == grid[r+2][c-2] && v == grid[r+3][c-3]) return v;
      }
    }
    return 0;
  }

  int[] getWinLine() {
    // Horizontal
    for (int r = 0; r < C4_ROWS; r++) {
      for (int c = 0; c <= C4_COLS - 4; c++) {
        int v = grid[r][c];
        if (v != 0 && v == grid[r][c+1] && v == grid[r][c+2] && v == grid[r][c+3]) {
          return new int[]{r, c, r, c+3};
        }
      }
    }
    // Vertical
    for (int r = 0; r <= C4_ROWS - 4; r++) {
      for (int c = 0; c < C4_COLS; c++) {
        int v = grid[r][c];
        if (v != 0 && v == grid[r+1][c] && v == grid[r+2][c] && v == grid[r+3][c]) {
          return new int[]{r, c, r+3, c};
        }
      }
    }
    // Diagonal down-right
    for (int r = 0; r <= C4_ROWS - 4; r++) {
      for (int c = 0; c <= C4_COLS - 4; c++) {
        int v = grid[r][c];
        if (v != 0 && v == grid[r+1][c+1] && v == grid[r+2][c+2] && v == grid[r+3][c+3]) {
          return new int[]{r, c, r+3, c+3};
        }
      }
    }
    // Diagonal down-left
    for (int r = 0; r <= C4_ROWS - 4; r++) {
      for (int c = 3; c < C4_COLS; c++) {
        int v = grid[r][c];
        if (v != 0 && v == grid[r+1][c-1] && v == grid[r+2][c-2] && v == grid[r+3][c-3]) {
          return new int[]{r, c, r+3, c-3};
        }
      }
    }
    return null;
  }

  boolean isFull() {
    for (int c = 0; c < C4_COLS; c++) {
      if (grid[0][c] == 0) return false;
    }
    return true;
  }

  C4Board copy() {
    C4Board b = new C4Board();
    for (int r = 0; r < C4_ROWS; r++) {
      for (int c = 0; c < C4_COLS; c++) {
        b.grid[r][c] = grid[r][c];
      }
    }
    return b;
  }

  ArrayList<Integer> getValidColumns() {
    ArrayList<Integer> cols = new ArrayList<Integer>();
    for (int c = 0; c < C4_COLS; c++) {
      if (grid[0][c] == 0) cols.add(c);
    }
    return cols;
  }
}
