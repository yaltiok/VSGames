int[] qrdFindBestMove(QRDBoard board, int aiPlayer) {
  int opponent = (aiPlayer == 1) ? 2 : 1;
  int aiPI = aiPlayer - 1;

  // Collect all pawn moves
  ArrayList<int[]> pawnMoves = board.getValidPawnMoves(aiPlayer);

  // Check instant win
  int goalRow = (aiPlayer == 1) ? 0 : 8;
  for (int[] m : pawnMoves) {
    if (m[0] == goalRow) {
      return new int[]{0, m[0], m[1]};
    }
  }

  float bestScore = -1e9;
  int[] bestMove = null;

  // Evaluate pawn moves
  for (int[] m : pawnMoves) {
    QRDBoard copy = board.copy();
    copy.movePawn(aiPlayer, m[0], m[1]);
    float score = qrdMinimax(copy, 2, -1e9, 1e9, false, aiPlayer);
    if (score > bestScore) {
      bestScore = score;
      bestMove = new int[]{0, m[0], m[1]};
    }
  }

  // Evaluate wall placements if walls remain
  if (board.wallsLeft[aiPI] > 0) {
    ArrayList<int[]> candidateWalls = qrdGetCandidateWalls(board, opponent);
    for (int[] w : candidateWalls) {
      int wr = w[0], wc = w[1], wo = w[2];
      if (!board.canPlaceWall(wr, wc, wo, aiPlayer)) continue;
      QRDBoard copy = board.copy();
      copy.placeWall(wr, wc, wo);
      copy.wallsLeft[aiPI]--;
      float score = qrdMinimax(copy, 2, -1e9, 1e9, false, aiPlayer);
      if (score > bestScore) {
        bestScore = score;
        bestMove = new int[]{1, wr, wc, wo};
      }
    }
  }

  return bestMove;
}

ArrayList<int[]> qrdGetCandidateWalls(QRDBoard board, int opponent) {
  ArrayList<int[]> candidates = new ArrayList<int[]>();
  ArrayList<int[]> path = board.bfsPath(opponent);
  boolean[][] considered = new boolean[8][8];

  for (int[] step : path) {
    int r = step[0], c = step[1];
    // Try walls at intersections near this cell
    for (int dr = -1; dr <= 0; dr++) {
      for (int dc = -1; dc <= 0; dc++) {
        int wr = r + dr, wc = c + dc;
        if (wr < 0 || wr > 7 || wc < 0 || wc > 7) continue;
        if (considered[wr][wc]) continue;
        considered[wr][wc] = true;
        candidates.add(new int[]{wr, wc, 0});
        candidates.add(new int[]{wr, wc, 1});
      }
    }
  }
  return candidates;
}

float qrdMinimax(QRDBoard board, int depth, float alpha, float beta, boolean maximizing, int aiPlayer) {
  int opponent = (aiPlayer == 1) ? 2 : 1;
  int w = board.checkWin();
  if (w == aiPlayer) return 100000 + depth;
  if (w == opponent) return -100000 - depth;
  if (depth == 0) return qrdEvaluate(board, aiPlayer);

  if (maximizing) {
    float maxEval = -1e9;
    ArrayList<int[]> moves = board.getValidPawnMoves(aiPlayer);
    for (int[] m : moves) {
      QRDBoard copy = board.copy();
      copy.movePawn(aiPlayer, m[0], m[1]);
      float eval = qrdMinimax(copy, depth - 1, alpha, beta, false, aiPlayer);
      maxEval = max(maxEval, eval);
      alpha = max(alpha, eval);
      if (beta <= alpha) break;
    }

    // Consider walls
    if (board.wallsLeft[aiPlayer - 1] > 0) {
      ArrayList<int[]> walls = qrdGetCandidateWalls(board, opponent);
      for (int[] ww : walls) {
        if (!board.canPlaceWall(ww[0], ww[1], ww[2], aiPlayer)) continue;
        QRDBoard copy = board.copy();
        copy.placeWall(ww[0], ww[1], ww[2]);
        copy.wallsLeft[aiPlayer - 1]--;
        float eval = qrdMinimax(copy, depth - 1, alpha, beta, false, aiPlayer);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
    }
    return maxEval;
  } else {
    float minEval = 1e9;
    ArrayList<int[]> moves = board.getValidPawnMoves(opponent);
    for (int[] m : moves) {
      QRDBoard copy = board.copy();
      copy.movePawn(opponent, m[0], m[1]);
      float eval = qrdMinimax(copy, depth - 1, alpha, beta, true, aiPlayer);
      minEval = min(minEval, eval);
      beta = min(beta, eval);
      if (beta <= alpha) break;
    }

    if (board.wallsLeft[opponent - 1] > 0) {
      ArrayList<int[]> walls = qrdGetCandidateWalls(board, aiPlayer);
      for (int[] ww : walls) {
        if (!board.canPlaceWall(ww[0], ww[1], ww[2], opponent)) continue;
        QRDBoard copy = board.copy();
        copy.placeWall(ww[0], ww[1], ww[2]);
        copy.wallsLeft[opponent - 1]--;
        float eval = qrdMinimax(copy, depth - 1, alpha, beta, true, aiPlayer);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
    }
    return minEval;
  }
}

float qrdEvaluate(QRDBoard board, int aiPlayer) {
  int opponent = (aiPlayer == 1) ? 2 : 1;
  int aiDist = board.bfsDistance(aiPlayer);
  int oppDist = board.bfsDistance(opponent);
  float score = (oppDist - aiDist) * 10;
  score += (board.wallsLeft[aiPlayer - 1] - board.wallsLeft[opponent - 1]) * 2;
  return score;
}
