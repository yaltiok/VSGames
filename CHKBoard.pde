class CHKBoard {
  int[][] grid;

  CHKBoard() {
    grid = new int[8][8];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if ((r + c) % 2 == 1) {
          if (r <= 2) grid[r][c] = 2;
          else if (r >= 5) grid[r][c] = 1;
        }
      }
    }
  }

  boolean isPlayerPiece(int row, int col, int player) {
    int v = grid[row][col];
    if (player == 1) return v == 1 || v == 3;
    if (player == 2) return v == 2 || v == 4;
    return false;
  }

  int opponent(int player) {
    return (player == 1) ? 2 : 1;
  }

  int[][] getDiagDirs(int pieceVal) {
    if (pieceVal == 1) return new int[][]{{-1, -1}, {-1, 1}};
    if (pieceVal == 2) return new int[][]{{1, -1}, {1, 1}};
    return new int[][]{{-1, -1}, {-1, 1}, {1, -1}, {1, 1}};
  }

  ArrayList<int[]> getSimpleMoves(int row, int col) {
    ArrayList<int[]> moves = new ArrayList<int[]>();
    int v = grid[row][col];
    if (v == 0) return moves;
    int[][] dirs = getDiagDirs(v);
    for (int[] d : dirs) {
      int nr = row + d[0];
      int nc = col + d[1];
      if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8 && grid[nr][nc] == 0) {
        moves.add(new int[]{nr, nc});
      }
    }
    return moves;
  }

  ArrayList<int[]> getJumps(int row, int col) {
    ArrayList<int[]> jumps = new ArrayList<int[]>();
    int v = grid[row][col];
    if (v == 0) return jumps;
    int player = (v == 1 || v == 3) ? 1 : 2;
    int opp = opponent(player);
    int[][] dirs = getDiagDirs(v);
    for (int[] d : dirs) {
      int mr = row + d[0];
      int mc = col + d[1];
      int lr = row + d[0] * 2;
      int lc = col + d[1] * 2;
      if (lr >= 0 && lr < 8 && lc >= 0 && lc < 8) {
        if (isPlayerPiece(mr, mc, opp) && grid[lr][lc] == 0) {
          jumps.add(new int[]{lr, lc, mr, mc});
        }
      }
    }
    return jumps;
  }

  boolean hasJumps(int player) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (isPlayerPiece(r, c, player) && getJumps(r, c).size() > 0) {
          return true;
        }
      }
    }
    return false;
  }

  ArrayList<int[]> getValidMoves(int player) {
    ArrayList<int[]> moves = new ArrayList<int[]>();
    boolean jumpsExist = hasJumps(player);
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (!isPlayerPiece(r, c, player)) continue;
        if (jumpsExist) {
          ArrayList<int[]> jumps = getJumps(r, c);
          for (int[] j : jumps) {
            moves.add(new int[]{r, c, j[0], j[1]});
          }
        } else {
          ArrayList<int[]> simple = getSimpleMoves(r, c);
          for (int[] s : simple) {
            moves.add(new int[]{r, c, s[0], s[1]});
          }
        }
      }
    }
    return moves;
  }

  void makeMove(int fromR, int fromC, int toR, int toC) {
    grid[toR][toC] = grid[fromR][fromC];
    grid[fromR][fromC] = 0;
    if (abs(toR - fromR) == 2) {
      int capR = (fromR + toR) / 2;
      int capC = (fromC + toC) / 2;
      grid[capR][capC] = 0;
    }
  }

  void promoteKings() {
    for (int c = 0; c < 8; c++) {
      if (grid[0][c] == 1) grid[0][c] = 3;
      if (grid[7][c] == 2) grid[7][c] = 4;
    }
  }

  int countPieces(int player) {
    int count = 0;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (isPlayerPiece(r, c, player)) count++;
      }
    }
    return count;
  }

  int getWinner() {
    int p1 = countPieces(1);
    int p2 = countPieces(2);
    if (p2 == 0 || (p1 > 0 && getValidMoves(2).size() == 0)) return 1;
    if (p1 == 0 || (p2 > 0 && getValidMoves(1).size() == 0)) return 2;
    return 0;
  }

  CHKBoard copy() {
    CHKBoard b = new CHKBoard();
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        b.grid[r][c] = this.grid[r][c];
      }
    }
    return b;
  }
}
