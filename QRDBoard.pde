class QRDBoard {
  int[] pawnRow = new int[2];
  int[] pawnCol = new int[2];
  boolean[][] hWalls = new boolean[8][8];
  boolean[][] vWalls = new boolean[8][8];
  int[] wallsLeft = {10, 10};

  QRDBoard() {
    pawnRow[0] = 8; pawnCol[0] = 4; // P1 starts bottom
    pawnRow[1] = 0; pawnCol[1] = 4; // P2 starts top
  }

  boolean isBlocked(int r1, int c1, int r2, int c2) {
    int dr = r2 - r1;
    int dc = c2 - c1;

    if (dr == -1 && dc == 0) {
      // Moving up: crosses between row r1-1 and r1
      int minR = r1 - 1;
      if (c1 < 8 && hWalls[minR][c1]) return true;
      if (c1 > 0 && hWalls[minR][c1 - 1]) return true;
      return false;
    }
    if (dr == 1 && dc == 0) {
      // Moving down: crosses between row r1 and r1+1
      int minR = r1;
      if (c1 < 8 && hWalls[minR][c1]) return true;
      if (c1 > 0 && hWalls[minR][c1 - 1]) return true;
      return false;
    }
    if (dc == -1 && dr == 0) {
      // Moving left: crosses between col c1-1 and c1
      int minC = c1 - 1;
      if (r1 < 8 && vWalls[r1][minC]) return true;
      if (r1 > 0 && vWalls[r1 - 1][minC]) return true;
      return false;
    }
    if (dc == 1 && dr == 0) {
      // Moving right: crosses between col c1 and c1+1
      int minC = c1;
      if (r1 < 8 && vWalls[r1][minC]) return true;
      if (r1 > 0 && vWalls[r1 - 1][minC]) return true;
      return false;
    }
    return true;
  }

  boolean hasPawnAt(int r, int c) {
    return (pawnRow[0] == r && pawnCol[0] == c) || (pawnRow[1] == r && pawnCol[1] == c);
  }

  ArrayList<int[]> getValidPawnMoves(int player) {
    ArrayList<int[]> moves = new ArrayList<int[]>();
    int pi = player - 1;
    int oi = (player == 1) ? 1 : 0;
    int pr = pawnRow[pi], pc = pawnCol[pi];
    int or_ = pawnRow[oi], oc = pawnCol[oi];

    int[][] dirs = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}};
    for (int[] d : dirs) {
      int nr = pr + d[0], nc = pc + d[1];
      if (nr < 0 || nr > 8 || nc < 0 || nc > 8) continue;
      if (isBlocked(pr, pc, nr, nc)) continue;

      if (nr == or_ && nc == oc) {
        // Opponent is adjacent, try to jump over
        int jr = nr + d[0], jc = nc + d[1];
        if (jr >= 0 && jr <= 8 && jc >= 0 && jc <= 8 && !isBlocked(nr, nc, jr, jc)) {
          moves.add(new int[]{jr, jc});
        } else {
          // Wall behind opponent or out of bounds: try diagonal jumps
          int[][] sideDirs;
          if (d[0] != 0) {
            sideDirs = new int[][]{{0, -1}, {0, 1}};
          } else {
            sideDirs = new int[][]{{-1, 0}, {1, 0}};
          }
          for (int[] sd : sideDirs) {
            int sr = nr + sd[0], sc = nc + sd[1];
            if (sr >= 0 && sr <= 8 && sc >= 0 && sc <= 8 && !isBlocked(nr, nc, sr, sc)) {
              moves.add(new int[]{sr, sc});
            }
          }
        }
      } else {
        moves.add(new int[]{nr, nc});
      }
    }
    return moves;
  }

  boolean canPlaceWall(int r, int c, int orientation, int player) {
    int pi = player - 1;
    if (wallsLeft[pi] <= 0) return false;
    if (r < 0 || r > 7 || c < 0 || c > 7) return false;

    if (orientation == 0) {
      // Horizontal wall
      if (hWalls[r][c]) return false;
      if (c > 0 && hWalls[r][c - 1]) return false;
      if (c < 7 && hWalls[r][c + 1]) return false;
      if (vWalls[r][c]) return false; // crossing
    } else {
      // Vertical wall
      if (vWalls[r][c]) return false;
      if (r > 0 && vWalls[r - 1][c]) return false;
      if (r < 7 && vWalls[r + 1][c]) return false;
      if (hWalls[r][c]) return false; // crossing
    }

    // Temporarily place wall and check both players can reach goal
    if (orientation == 0) hWalls[r][c] = true;
    else vWalls[r][c] = true;

    boolean p1ok = bfsCanReach(1);
    boolean p2ok = bfsCanReach(2);

    if (orientation == 0) hWalls[r][c] = false;
    else vWalls[r][c] = false;

    return p1ok && p2ok;
  }

  void placeWall(int r, int c, int orientation) {
    if (orientation == 0) hWalls[r][c] = true;
    else vWalls[r][c] = true;
  }

  void movePawn(int player, int row, int col) {
    int pi = player - 1;
    pawnRow[pi] = row;
    pawnCol[pi] = col;
  }

  int checkWin() {
    if (pawnRow[0] == 0) return 1; // P1 reached top
    if (pawnRow[1] == 8) return 2; // P2 reached bottom
    return 0;
  }

  boolean bfsCanReach(int player) {
    int pi = player - 1;
    int goalRow = (player == 1) ? 0 : 8;
    boolean[][] visited = new boolean[9][9];
    ArrayList<int[]> queue = new ArrayList<int[]>();
    queue.add(new int[]{pawnRow[pi], pawnCol[pi]});
    visited[pawnRow[pi]][pawnCol[pi]] = true;

    int[][] dirs = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}};
    int head = 0;
    while (head < queue.size()) {
      int[] cur = queue.get(head++);
      if (cur[0] == goalRow) return true;
      for (int[] d : dirs) {
        int nr = cur[0] + d[0], nc = cur[1] + d[1];
        if (nr < 0 || nr > 8 || nc < 0 || nc > 8) continue;
        if (visited[nr][nc]) continue;
        if (isBlocked(cur[0], cur[1], nr, nc)) continue;
        visited[nr][nc] = true;
        queue.add(new int[]{nr, nc});
      }
    }
    return false;
  }

  int bfsDistance(int player) {
    int pi = player - 1;
    int goalRow = (player == 1) ? 0 : 8;
    int[][] dist = new int[9][9];
    for (int[] row : dist) java.util.Arrays.fill(row, -1);
    ArrayList<int[]> queue = new ArrayList<int[]>();
    queue.add(new int[]{pawnRow[pi], pawnCol[pi]});
    dist[pawnRow[pi]][pawnCol[pi]] = 0;

    int[][] dirs = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}};
    int head = 0;
    while (head < queue.size()) {
      int[] cur = queue.get(head++);
      if (cur[0] == goalRow) return dist[cur[0]][cur[1]];
      for (int[] d : dirs) {
        int nr = cur[0] + d[0], nc = cur[1] + d[1];
        if (nr < 0 || nr > 8 || nc < 0 || nc > 8) continue;
        if (dist[nr][nc] != -1) continue;
        if (isBlocked(cur[0], cur[1], nr, nc)) continue;
        dist[nr][nc] = dist[cur[0]][cur[1]] + 1;
        queue.add(new int[]{nr, nc});
      }
    }
    return 999;
  }

  ArrayList<int[]> bfsPath(int player) {
    int pi = player - 1;
    int goalRow = (player == 1) ? 0 : 8;
    int[][] prevR = new int[9][9];
    int[][] prevC = new int[9][9];
    for (int[] row : prevR) java.util.Arrays.fill(row, -1);
    for (int[] row : prevC) java.util.Arrays.fill(row, -1);
    boolean[][] visited = new boolean[9][9];
    ArrayList<int[]> queue = new ArrayList<int[]>();
    int sr = pawnRow[pi], sc = pawnCol[pi];
    queue.add(new int[]{sr, sc});
    visited[sr][sc] = true;

    int[][] dirs = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}};
    int head = 0;
    int[] goal = null;
    while (head < queue.size()) {
      int[] cur = queue.get(head++);
      if (cur[0] == goalRow) {
        goal = cur;
        break;
      }
      for (int[] d : dirs) {
        int nr = cur[0] + d[0], nc = cur[1] + d[1];
        if (nr < 0 || nr > 8 || nc < 0 || nc > 8) continue;
        if (visited[nr][nc]) continue;
        if (isBlocked(cur[0], cur[1], nr, nc)) continue;
        visited[nr][nc] = true;
        prevR[nr][nc] = cur[0];
        prevC[nr][nc] = cur[1];
        queue.add(new int[]{nr, nc});
      }
    }

    ArrayList<int[]> path = new ArrayList<int[]>();
    if (goal == null) return path;
    int cr = goal[0], cc = goal[1];
    while (cr != sr || cc != sc) {
      path.add(0, new int[]{cr, cc});
      int pr = prevR[cr][cc], pc = prevC[cr][cc];
      cr = pr; cc = pc;
    }
    return path;
  }

  QRDBoard copy() {
    QRDBoard b = new QRDBoard();
    b.pawnRow[0] = pawnRow[0]; b.pawnRow[1] = pawnRow[1];
    b.pawnCol[0] = pawnCol[0]; b.pawnCol[1] = pawnCol[1];
    b.wallsLeft[0] = wallsLeft[0]; b.wallsLeft[1] = wallsLeft[1];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        b.hWalls[r][c] = hWalls[r][c];
        b.vWalls[r][c] = vWalls[r][c];
      }
    }
    return b;
  }
}
