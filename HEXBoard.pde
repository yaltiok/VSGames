class HEXBoard {
  int[][] grid;
  int moveCount;

  HEXBoard() {
    grid = new int[HEX_BOARD_SIZE][HEX_BOARD_SIZE];
    moveCount = 0;
  }

  boolean placeStone(int row, int col, int player) {
    if (!isOnBoard(row, col) || grid[row][col] != 0) return false;
    grid[row][col] = player;
    moveCount++;
    return true;
  }

  boolean isOnBoard(int row, int col) {
    return row >= 0 && row < HEX_BOARD_SIZE && col >= 0 && col < HEX_BOARD_SIZE;
  }

  ArrayList<int[]> getNeighbors(int row, int col) {
    ArrayList<int[]> neighbors = new ArrayList<int[]>();
    int[][] deltas;
    if (row % 2 == 0) {
      deltas = new int[][] {
        {-1, -1}, {-1, 0},
        {0, -1}, {0, 1},
        {1, -1}, {1, 0}
      };
    } else {
      deltas = new int[][] {
        {-1, 0}, {-1, 1},
        {0, -1}, {0, 1},
        {1, 0}, {1, 1}
      };
    }
    for (int[] d : deltas) {
      int nr = row + d[0];
      int nc = col + d[1];
      if (isOnBoard(nr, nc)) {
        neighbors.add(new int[] {nr, nc});
      }
    }
    return neighbors;
  }

  boolean checkWin(int player) {
    boolean[][] visited = new boolean[HEX_BOARD_SIZE][HEX_BOARD_SIZE];
    ArrayList<int[]> queue = new ArrayList<int[]>();

    if (player == 1) {
      for (int r = 0; r < HEX_BOARD_SIZE; r++) {
        if (grid[r][0] == player) {
          queue.add(new int[] {r, 0});
          visited[r][0] = true;
        }
      }
    } else {
      for (int c = 0; c < HEX_BOARD_SIZE; c++) {
        if (grid[0][c] == player) {
          queue.add(new int[] {0, c});
          visited[0][c] = true;
        }
      }
    }

    int idx = 0;
    while (idx < queue.size()) {
      int[] cur = queue.get(idx);
      idx++;
      if (player == 1 && cur[1] == HEX_BOARD_SIZE - 1) return true;
      if (player == 2 && cur[0] == HEX_BOARD_SIZE - 1) return true;

      ArrayList<int[]> nbrs = getNeighbors(cur[0], cur[1]);
      for (int[] n : nbrs) {
        if (!visited[n[0]][n[1]] && grid[n[0]][n[1]] == player) {
          visited[n[0]][n[1]] = true;
          queue.add(n);
        }
      }
    }
    return false;
  }

  int[] getWinPath(int player) {
    boolean[][] visited = new boolean[HEX_BOARD_SIZE][HEX_BOARD_SIZE];
    int[][] parentR = new int[HEX_BOARD_SIZE][HEX_BOARD_SIZE];
    int[][] parentC = new int[HEX_BOARD_SIZE][HEX_BOARD_SIZE];
    for (int r = 0; r < HEX_BOARD_SIZE; r++) {
      for (int c = 0; c < HEX_BOARD_SIZE; c++) {
        parentR[r][c] = -1;
        parentC[r][c] = -1;
      }
    }

    ArrayList<int[]> queue = new ArrayList<int[]>();

    if (player == 1) {
      for (int r = 0; r < HEX_BOARD_SIZE; r++) {
        if (grid[r][0] == player) {
          queue.add(new int[] {r, 0});
          visited[r][0] = true;
        }
      }
    } else {
      for (int c = 0; c < HEX_BOARD_SIZE; c++) {
        if (grid[0][c] == player) {
          queue.add(new int[] {0, c});
          visited[0][c] = true;
        }
      }
    }

    int idx = 0;
    while (idx < queue.size()) {
      int[] cur = queue.get(idx);
      idx++;

      boolean reached = (player == 1 && cur[1] == HEX_BOARD_SIZE - 1) ||
                         (player == 2 && cur[0] == HEX_BOARD_SIZE - 1);
      if (reached) {
        ArrayList<int[]> path = new ArrayList<int[]>();
        int cr = cur[0], cc = cur[1];
        while (cr != -1) {
          path.add(new int[] {cr, cc});
          int pr = parentR[cr][cc];
          int pc = parentC[cr][cc];
          cr = pr;
          cc = pc;
        }
        int[] result = new int[path.size() * 2];
        for (int i = 0; i < path.size(); i++) {
          result[i * 2] = path.get(i)[0];
          result[i * 2 + 1] = path.get(i)[1];
        }
        return result;
      }

      ArrayList<int[]> nbrs = getNeighbors(cur[0], cur[1]);
      for (int[] n : nbrs) {
        if (!visited[n[0]][n[1]] && grid[n[0]][n[1]] == player) {
          visited[n[0]][n[1]] = true;
          parentR[n[0]][n[1]] = cur[0];
          parentC[n[0]][n[1]] = cur[1];
          queue.add(n);
        }
      }
    }
    return null;
  }

  HEXBoard copy() {
    HEXBoard b = new HEXBoard();
    for (int r = 0; r < HEX_BOARD_SIZE; r++) {
      for (int c = 0; c < HEX_BOARD_SIZE; c++) {
        b.grid[r][c] = grid[r][c];
      }
    }
    b.moveCount = moveCount;
    return b;
  }

  ArrayList<int[]> getEmptyCells() {
    ArrayList<int[]> cells = new ArrayList<int[]>();
    for (int r = 0; r < HEX_BOARD_SIZE; r++) {
      for (int c = 0; c < HEX_BOARD_SIZE; c++) {
        if (grid[r][c] == 0) cells.add(new int[] {r, c});
      }
    }
    return cells;
  }
}
