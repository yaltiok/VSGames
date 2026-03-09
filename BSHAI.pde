// Hunt/Target AI for Battleship

int[] bshFindTarget(int[][] attackGrid) {
  // Check for unsunk hits — target mode
  ArrayList<int[]> unsunkHits = new ArrayList<int[]>();
  for (int r = 0; r < 10; r++) {
    for (int c = 0; c < 10; c++) {
      if (attackGrid[r][c] == 2) {
        unsunkHits.add(new int[]{r, c});
      }
    }
  }

  if (unsunkHits.size() > 0) {
    return bshTargetMode(attackGrid, unsunkHits);
  }
  return bshHuntMode(attackGrid);
}

int[] bshTargetMode(int[][] attackGrid, ArrayList<int[]> unsunkHits) {
  // If 2+ hits in a line, prioritize that direction
  if (unsunkHits.size() >= 2) {
    int[] directed = bshDirectedTarget(attackGrid, unsunkHits);
    if (directed != null) return directed;
  }

  // Try adjacent cells of each unsunk hit
  int[][] dirs = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}};
  ArrayList<int[]> candidates = new ArrayList<int[]>();
  for (int[] hit : unsunkHits) {
    for (int[] d : dirs) {
      int nr = hit[0] + d[0];
      int nc = hit[1] + d[1];
      if (nr >= 0 && nr < 10 && nc >= 0 && nc < 10 && attackGrid[nr][nc] == 0) {
        candidates.add(new int[]{nr, nc});
      }
    }
  }

  if (candidates.size() > 0) {
    return candidates.get((int) random(candidates.size()));
  }
  return bshHuntMode(attackGrid);
}

int[] bshDirectedTarget(int[][] attackGrid, ArrayList<int[]> unsunkHits) {
  // Find pairs of hits that are adjacent and try to extend the line
  for (int i = 0; i < unsunkHits.size(); i++) {
    for (int j = i + 1; j < unsunkHits.size(); j++) {
      int[] a = unsunkHits.get(i);
      int[] b = unsunkHits.get(j);
      int dr = b[0] - a[0];
      int dc = b[1] - a[1];

      // Must be in same row or column
      if (dr != 0 && dc != 0) continue;
      if (abs(dr) > 1 && abs(dc) > 1) continue;

      // Normalize direction
      if (dr != 0) dr = dr / abs(dr);
      if (dc != 0) dc = dc / abs(dc);

      // Find endpoints of the line of hits
      int minR = min(a[0], b[0]);
      int maxR = max(a[0], b[0]);
      int minC = min(a[1], b[1]);
      int maxC = max(a[1], b[1]);

      // Extend to find all contiguous hits
      if (dr == 0) {
        // Horizontal line
        while (minC > 0 && attackGrid[a[0]][minC - 1] == 2) minC--;
        while (maxC < 9 && attackGrid[a[0]][maxC + 1] == 2) maxC++;
        // Try extending
        if (minC > 0 && attackGrid[a[0]][minC - 1] == 0) return new int[]{a[0], minC - 1};
        if (maxC < 9 && attackGrid[a[0]][maxC + 1] == 0) return new int[]{a[0], maxC + 1};
      } else {
        // Vertical line
        while (minR > 0 && attackGrid[minR - 1][a[1]] == 2) minR--;
        while (maxR < 9 && attackGrid[maxR + 1][a[1]] == 2) maxR++;
        if (minR > 0 && attackGrid[minR - 1][a[1]] == 0) return new int[]{minR - 1, a[1]};
        if (maxR < 9 && attackGrid[maxR + 1][a[1]] == 0) return new int[]{maxR + 1, a[1]};
      }
    }
  }
  return null;
}

int[] bshHuntMode(int[][] attackGrid) {
  // Checkerboard parity hunting
  ArrayList<int[]> candidates = new ArrayList<int[]>();
  for (int r = 0; r < 10; r++) {
    for (int c = 0; c < 10; c++) {
      if (attackGrid[r][c] == 0 && (r + c) % 2 == 0) {
        candidates.add(new int[]{r, c});
      }
    }
  }
  // If no even parity cells left, try odd
  if (candidates.size() == 0) {
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        if (attackGrid[r][c] == 0) {
          candidates.add(new int[]{r, c});
        }
      }
    }
  }
  if (candidates.size() > 0) {
    return candidates.get((int) random(candidates.size()));
  }
  return new int[]{0, 0};
}

void bshPlaceShipsRandom(BSHBoard board) {
  board.placeShipsRandom();
}
