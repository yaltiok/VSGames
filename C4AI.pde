int c4FindBestMove(C4Board board, int aiPlayer) {
  ArrayList<Integer> valid = board.getValidColumns();
  if (valid.size() == 0) return -1;

  // Move ordering: center columns first
  int[] order = {3, 2, 4, 1, 5, 0, 6};

  float bestScore = -1e9;
  int bestCol = valid.get(0);

  for (int i = 0; i < order.length; i++) {
    int col = order[i];
    if (!board.isValidDrop(col)) continue;

    C4Board copy = board.copy();
    copy.dropPiece(col, aiPlayer);

    float score = c4Minimax(copy, 6, -1e9, 1e9, false, aiPlayer);
    if (score > bestScore) {
      bestScore = score;
      bestCol = col;
    }
  }
  return bestCol;
}

float c4Minimax(C4Board board, int depth, float alpha, float beta, boolean maximizing, int aiPlayer) {
  int opponent = (aiPlayer == 1) ? 2 : 1;
  int w = board.checkWin();
  if (w == aiPlayer) return 100000 + depth;
  if (w == opponent) return -100000 - depth;
  if (board.isFull()) return 0;
  if (depth == 0) return c4Evaluate(board, aiPlayer);

  int[] order = {3, 2, 4, 1, 5, 0, 6};

  if (maximizing) {
    float maxEval = -1e9;
    for (int i = 0; i < order.length; i++) {
      int col = order[i];
      if (!board.isValidDrop(col)) continue;
      C4Board copy = board.copy();
      copy.dropPiece(col, aiPlayer);
      float eval = c4Minimax(copy, depth - 1, alpha, beta, false, aiPlayer);
      maxEval = max(maxEval, eval);
      alpha = max(alpha, eval);
      if (beta <= alpha) break;
    }
    return maxEval;
  } else {
    float minEval = 1e9;
    for (int i = 0; i < order.length; i++) {
      int col = order[i];
      if (!board.isValidDrop(col)) continue;
      C4Board copy = board.copy();
      copy.dropPiece(col, opponent);
      float eval = c4Minimax(copy, depth - 1, alpha, beta, true, aiPlayer);
      minEval = min(minEval, eval);
      beta = min(beta, eval);
      if (beta <= alpha) break;
    }
    return minEval;
  }
}

float c4Evaluate(C4Board board, int aiPlayer) {
  int opponent = (aiPlayer == 1) ? 2 : 1;
  float score = 0;

  // Center column preference
  for (int r = 0; r < C4_ROWS; r++) {
    if (board.grid[r][3] == aiPlayer) score += 3;
    else if (board.grid[r][3] == opponent) score -= 3;
  }

  // Evaluate all windows of 4
  // Horizontal
  for (int r = 0; r < C4_ROWS; r++) {
    for (int c = 0; c <= C4_COLS - 4; c++) {
      score += c4ScoreWindow(board.grid[r][c], board.grid[r][c+1], board.grid[r][c+2], board.grid[r][c+3], aiPlayer, opponent);
    }
  }
  // Vertical
  for (int r = 0; r <= C4_ROWS - 4; r++) {
    for (int c = 0; c < C4_COLS; c++) {
      score += c4ScoreWindow(board.grid[r][c], board.grid[r+1][c], board.grid[r+2][c], board.grid[r+3][c], aiPlayer, opponent);
    }
  }
  // Diagonal down-right
  for (int r = 0; r <= C4_ROWS - 4; r++) {
    for (int c = 0; c <= C4_COLS - 4; c++) {
      score += c4ScoreWindow(board.grid[r][c], board.grid[r+1][c+1], board.grid[r+2][c+2], board.grid[r+3][c+3], aiPlayer, opponent);
    }
  }
  // Diagonal down-left
  for (int r = 0; r <= C4_ROWS - 4; r++) {
    for (int c = 3; c < C4_COLS; c++) {
      score += c4ScoreWindow(board.grid[r][c], board.grid[r+1][c-1], board.grid[r+2][c-2], board.grid[r+3][c-3], aiPlayer, opponent);
    }
  }

  return score;
}

float c4ScoreWindow(int a, int b, int c, int d, int ai, int opp) {
  int aiCount = 0, oppCount = 0, empty = 0;
  int[] vals = {a, b, c, d};
  for (int i = 0; i < 4; i++) {
    if (vals[i] == ai) aiCount++;
    else if (vals[i] == opp) oppCount++;
    else empty++;
  }

  if (aiCount == 4) return 1000;
  if (oppCount == 4) return -1000;
  if (aiCount == 3 && empty == 1) return 50;
  if (oppCount == 3 && empty == 1) return -80;
  if (aiCount == 2 && empty == 2) return 10;
  if (oppCount == 2 && empty == 2) return -10;
  return 0;
}
