int mngFindBestMove(MNGBoard board, int player) {
  ArrayList<Integer> moves = board.getValidMoves(player);
  if (moves.size() == 0) return -1;

  int bestMove = moves.get(0);
  float bestScore = -100000;

  for (int move : moves) {
    MNGBoard sim = board.copy();
    boolean extraTurn = sim.sow(move);

    float score;
    if (extraTurn) {
      score = mngMinimax(sim, 9, -100000, 100000, true, player);
    } else {
      sim.currentPlayer = (player == 1) ? 2 : 1;
      score = mngMinimax(sim, 9, -100000, 100000, false, player);
    }

    if (score > bestScore) {
      bestScore = score;
      bestMove = move;
    }
  }

  return bestMove;
}

float mngMinimax(MNGBoard board, int depth, float alpha, float beta, boolean maximizing, int aiPlayer) {
  if (board.isGameOver() || depth == 0) {
    return mngEvaluate(board, aiPlayer);
  }

  int player = maximizing ? aiPlayer : (aiPlayer == 1 ? 2 : 1);
  ArrayList<Integer> moves = board.getValidMoves(player);

  if (moves.size() == 0) {
    return mngEvaluate(board, aiPlayer);
  }

  if (maximizing) {
    float maxEval = -100000;
    for (int move : moves) {
      MNGBoard sim = board.copy();
      boolean extraTurn = sim.sow(move);

      float eval;
      if (extraTurn) {
        eval = mngMinimax(sim, depth - 1, alpha, beta, true, aiPlayer);
      } else {
        sim.currentPlayer = (player == 1) ? 2 : 1;
        eval = mngMinimax(sim, depth - 1, alpha, beta, false, aiPlayer);
      }

      maxEval = max(maxEval, eval);
      alpha = max(alpha, eval);
      if (beta <= alpha) break;
    }
    return maxEval;
  } else {
    float minEval = 100000;
    for (int move : moves) {
      MNGBoard sim = board.copy();
      boolean extraTurn = sim.sow(move);

      float eval;
      if (extraTurn) {
        eval = mngMinimax(sim, depth - 1, alpha, beta, false, aiPlayer);
      } else {
        sim.currentPlayer = (player == 1) ? 2 : 1;
        eval = mngMinimax(sim, depth - 1, alpha, beta, true, aiPlayer);
      }

      minEval = min(minEval, eval);
      beta = min(beta, eval);
      if (beta <= alpha) break;
    }
    return minEval;
  }
}

float mngEvaluate(MNGBoard board, int aiPlayer) {
  int oppPlayer = (aiPlayer == 1) ? 2 : 1;
  int aiStore = (aiPlayer == 1) ? 6 : 13;
  int oppStore = (oppPlayer == 1) ? 6 : 13;

  float score = (board.pits[aiStore] - board.pits[oppStore]) * 10;

  // Stones on own side
  int aiStones = 0;
  int oppStones = 0;
  if (aiPlayer == 1) {
    for (int i = 0; i < 6; i++) aiStones += board.pits[i];
    for (int i = 7; i < 13; i++) oppStones += board.pits[i];
  } else {
    for (int i = 7; i < 13; i++) aiStones += board.pits[i];
    for (int i = 0; i < 6; i++) oppStones += board.pits[i];
  }
  score += (aiStones - oppStones) * 1;

  // Extra turn potential (Turkish rules: stones-1 steps since 1 stays in pit)
  int aiStoreIdx = (aiPlayer == 1) ? 6 : 13;
  ArrayList<Integer> aiMoves = board.getValidMoves(aiPlayer);
  for (int move : aiMoves) {
    int dist = 0;
    if (aiPlayer == 1) {
      dist = aiStoreIdx - move;
    } else {
      dist = aiStoreIdx - move;
    }
    // stones-1 steps are taken (1 stays in the pit)
    if (dist > 0 && board.pits[move] > 1 && board.pits[move] - 1 == dist) {
      score += 5;
    }
  }

  // Capture opportunities (simulate Turkish sowing: 1 stays, rest distributed)
  int skipStore = (aiPlayer == 1) ? 13 : 6;
  for (int move : aiMoves) {
    int stones = board.pits[move];
    if (stones <= 1) continue; // single stone has no capture
    int remaining = stones - 1;
    int idx = move;
    for (int i = 0; i < remaining; i++) {
      idx = (idx + 1) % 14;
      if (idx == skipStore) idx = (idx + 1) % 14;
    }
    // Own-side empty pit capture
    if (board.pits[idx] == 0 && board.isOwnSide(idx, aiPlayer)) {
      int opp = board.getOppositePit(idx);
      if (board.pits[opp] > 0) {
        score += board.pits[opp] * 2;
      }
    }
    // Even capture on opponent's side
    if (!board.isOwnSide(idx, aiPlayer) && idx != skipStore) {
      int newCount = board.pits[idx] + 1; // after dropping last stone
      if (newCount % 2 == 0) {
        score += newCount * 2;
      }
    }
  }

  // Game over bonus
  if (board.isGameOver()) {
    MNGBoard sim = board.copy();
    sim.captureRemaining();
    if (sim.pits[aiStore] > 24) score += 1000;
    else if (sim.pits[oppStore] > 24) score -= 1000;
  }

  return score;
}
