int[] gmkFindBestMove(GMKBoard board, int aiPlayer) {
  ArrayList<int[]> candidates = gmkGetCandidates(board);
  if (candidates.size() == 0) {
    return new int[] {GMK_BOARD_SIZE / 2, GMK_BOARD_SIZE / 2};
  }

  // Score and sort candidates for move ordering
  float[] scores = new float[candidates.size()];
  for (int i = 0; i < candidates.size(); i++) {
    int[] c = candidates.get(i);
    GMKBoard copy = board.copy();
    copy.placeStone(c[0], c[1], aiPlayer);
    scores[i] = gmkEvaluate(copy, aiPlayer);
  }
  gmkSortCandidates(candidates, scores);

  float bestScore = -1e9;
  int[] bestMove = candidates.get(0);

  for (int i = 0; i < candidates.size(); i++) {
    int[] c = candidates.get(i);
    GMKBoard copy = board.copy();
    copy.placeStone(c[0], c[1], aiPlayer);

    if (copy.checkWin(c[0], c[1]) == aiPlayer) {
      return c;
    }

    float score = gmkMinimax(copy, 3, -1e9, 1e9, false, aiPlayer);
    if (score > bestScore) {
      bestScore = score;
      bestMove = c;
    }
  }
  return bestMove;
}

float gmkMinimax(GMKBoard board, int depth, float alpha, float beta, boolean maximizing, int aiPlayer) {
  if (depth == 0) {
    return gmkEvaluate(board, aiPlayer);
  }

  ArrayList<int[]> candidates = gmkGetCandidates(board);
  if (candidates.size() == 0) {
    return gmkEvaluate(board, aiPlayer);
  }

  if (maximizing) {
    float maxEval = -1e9;
    for (int i = 0; i < candidates.size(); i++) {
      int[] c = candidates.get(i);
      GMKBoard copy = board.copy();
      copy.placeStone(c[0], c[1], aiPlayer);
      if (copy.checkWin(c[0], c[1]) == aiPlayer) return 100000;
      float eval = gmkMinimax(copy, depth - 1, alpha, beta, false, aiPlayer);
      maxEval = max(maxEval, eval);
      alpha = max(alpha, eval);
      if (beta <= alpha) break;
    }
    return maxEval;
  } else {
    int opponent = (aiPlayer == 1) ? 2 : 1;
    float minEval = 1e9;
    for (int i = 0; i < candidates.size(); i++) {
      int[] c = candidates.get(i);
      GMKBoard copy = board.copy();
      copy.placeStone(c[0], c[1], opponent);
      if (copy.checkWin(c[0], c[1]) == opponent) return -100000;
      float eval = gmkMinimax(copy, depth - 1, alpha, beta, true, aiPlayer);
      minEval = min(minEval, eval);
      beta = min(beta, eval);
      if (beta <= alpha) break;
    }
    return minEval;
  }
}

float gmkEvaluate(GMKBoard board, int aiPlayer) {
  int opponent = (aiPlayer == 1) ? 2 : 1;
  float score = 0;

  // Scan all windows of 5 in rows, columns, and diagonals
  for (int r = 0; r < GMK_BOARD_SIZE; r++) {
    for (int c = 0; c < GMK_BOARD_SIZE; c++) {
      // Horizontal
      if (c + 4 < GMK_BOARD_SIZE) {
        score += gmkScoreWindow(board, r, c, 0, 1, aiPlayer, opponent);
      }
      // Vertical
      if (r + 4 < GMK_BOARD_SIZE) {
        score += gmkScoreWindow(board, r, c, 1, 0, aiPlayer, opponent);
      }
      // Diagonal down-right
      if (r + 4 < GMK_BOARD_SIZE && c + 4 < GMK_BOARD_SIZE) {
        score += gmkScoreWindow(board, r, c, 1, 1, aiPlayer, opponent);
      }
      // Diagonal down-left
      if (r + 4 < GMK_BOARD_SIZE && c - 4 >= 0) {
        score += gmkScoreWindow(board, r, c, 1, -1, aiPlayer, opponent);
      }
    }
  }
  return score;
}

float gmkScoreWindow(GMKBoard board, int r, int c, int dr, int dc, int aiPlayer, int opponent) {
  int aiCount = 0;
  int oppCount = 0;

  for (int i = 0; i < 5; i++) {
    int cell = board.grid[r + i * dr][c + i * dc];
    if (cell == aiPlayer) aiCount++;
    else if (cell == opponent) oppCount++;
  }

  if (aiCount > 0 && oppCount > 0) return 0;

  // Check openness (cells before and after the window)
  int beforeR = r - dr;
  int beforeC = c - dc;
  int afterR = r + 5 * dr;
  int afterC = c + 5 * dc;
  boolean openBefore = (beforeR >= 0 && beforeR < GMK_BOARD_SIZE &&
                        beforeC >= 0 && beforeC < GMK_BOARD_SIZE &&
                        board.grid[beforeR][beforeC] == 0);
  boolean openAfter = (afterR >= 0 && afterR < GMK_BOARD_SIZE &&
                       afterC >= 0 && afterC < GMK_BOARD_SIZE &&
                       board.grid[afterR][afterC] == 0);

  if (aiCount > 0) {
    return gmkPatternScore(aiCount, openBefore, openAfter, 1.0);
  } else if (oppCount > 0) {
    return gmkPatternScore(oppCount, openBefore, openAfter, -1.2);
  }
  return 0;
}

float gmkPatternScore(int count, boolean openBefore, boolean openAfter, float multiplier) {
  int openEnds = (openBefore ? 1 : 0) + (openAfter ? 1 : 0);
  if (openEnds == 0 && count < 5) return 0;

  float base = 0;
  if (count == 5) base = 100000;
  else if (count == 4) base = (openEnds == 2) ? 10000 : 5000;
  else if (count == 3) base = (openEnds == 2) ? 1000 : 500;
  else if (count == 2) base = (openEnds == 2) ? 100 : 50;
  else if (count == 1) base = (openEnds == 2) ? 10 : 5;

  return base * multiplier;
}

ArrayList<int[]> gmkGetCandidates(GMKBoard board) {
  boolean[][] seen = new boolean[GMK_BOARD_SIZE][GMK_BOARD_SIZE];
  ArrayList<int[]> candidates = new ArrayList<int[]>();

  for (int r = 0; r < GMK_BOARD_SIZE; r++) {
    for (int c = 0; c < GMK_BOARD_SIZE; c++) {
      if (board.grid[r][c] != 0) {
        for (int dr = -2; dr <= 2; dr++) {
          for (int dc = -2; dc <= 2; dc++) {
            int nr = r + dr;
            int nc = c + dc;
            if (nr >= 0 && nr < GMK_BOARD_SIZE && nc >= 0 && nc < GMK_BOARD_SIZE &&
                board.grid[nr][nc] == 0 && !seen[nr][nc]) {
              seen[nr][nc] = true;
              candidates.add(new int[] {nr, nc});
            }
          }
        }
      }
    }
  }
  return candidates;
}

void gmkSortCandidates(ArrayList<int[]> candidates, float[] scores) {
  int n = candidates.size();
  for (int i = 0; i < n - 1; i++) {
    for (int j = 0; j < n - 1 - i; j++) {
      if (scores[j] < scores[j + 1]) {
        float tmp = scores[j];
        scores[j] = scores[j + 1];
        scores[j + 1] = tmp;
        int[] tmpC = candidates.get(j);
        candidates.set(j, candidates.get(j + 1));
        candidates.set(j + 1, tmpC);
      }
    }
  }
}
