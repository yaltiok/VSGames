int[] chkFindBestMove(CHKBoard board, int player) {
  ArrayList<int[]> moves = board.getValidMoves(player);
  if (moves.size() == 0) return null;

  float bestScore = -99999;
  int[] bestMove = null;

  for (int[] move : moves) {
    CHKBoard sim = board.copy();
    sim.makeMove(move[0], move[1], move[2], move[3]);
    boolean wasJump = abs(move[2] - move[0]) == 2;

    if (wasJump) {
      sim.promoteKings();
      chkExecuteMultiJumps(sim, move[2], move[3], player);
    }
    sim.promoteKings();

    float score = chkMinimax(sim, 6, -99999, 99999, false, player);
    if (score > bestScore) {
      bestScore = score;
      bestMove = move;
    }
  }
  return bestMove;
}

void chkExecuteMultiJumps(CHKBoard board, int row, int col, int player) {
  ArrayList<int[]> jumps = board.getJumps(row, col);
  if (jumps.size() == 0) return;

  float bestScore = -99999;
  int[] bestJump = null;
  for (int[] j : jumps) {
    CHKBoard sim = board.copy();
    sim.makeMove(row, col, j[0], j[1]);
    sim.promoteKings();
    float score = chkEvaluate(sim, player);
    if (score > bestScore) {
      bestScore = score;
      bestJump = j;
    }
  }
  if (bestJump != null) {
    board.makeMove(row, col, bestJump[0], bestJump[1]);
    board.promoteKings();
    chkExecuteMultiJumps(board, bestJump[0], bestJump[1], player);
  }
}

int[] chkBestJumpFrom(CHKBoard board, int row, int col, int player) {
  ArrayList<int[]> jumps = board.getJumps(row, col);
  if (jumps.size() == 0) return null;

  float bestScore = -99999;
  int[] bestJump = null;
  for (int[] j : jumps) {
    CHKBoard sim = board.copy();
    sim.makeMove(row, col, j[0], j[1]);
    sim.promoteKings();
    float score = chkEvaluate(sim, player);
    if (score > bestScore) {
      bestScore = score;
      bestJump = new int[]{j[0], j[1]};
    }
  }
  return bestJump;
}

float chkMinimax(CHKBoard board, int depth, float alpha, float beta, boolean maximizing, int aiPlayer) {
  int w = board.getWinner();
  if (w == aiPlayer) return 1000 + depth;
  if (w != 0) return -1000 - depth;
  if (depth == 0) return chkEvaluate(board, aiPlayer);

  int player = maximizing ? aiPlayer : board.opponent(aiPlayer);
  ArrayList<int[]> moves = board.getValidMoves(player);
  if (moves.size() == 0) {
    return maximizing ? -1000 : 1000;
  }

  if (maximizing) {
    float maxEval = -99999;
    for (int[] move : moves) {
      CHKBoard sim = board.copy();
      sim.makeMove(move[0], move[1], move[2], move[3]);
      boolean wasJump = abs(move[2] - move[0]) == 2;
      if (wasJump) {
        sim.promoteKings();
        chkExecuteMultiJumps(sim, move[2], move[3], player);
      }
      sim.promoteKings();
      float eval = chkMinimax(sim, depth - 1, alpha, beta, false, aiPlayer);
      maxEval = max(maxEval, eval);
      alpha = max(alpha, eval);
      if (beta <= alpha) break;
    }
    return maxEval;
  } else {
    float minEval = 99999;
    for (int[] move : moves) {
      CHKBoard sim = board.copy();
      sim.makeMove(move[0], move[1], move[2], move[3]);
      boolean wasJump = abs(move[2] - move[0]) == 2;
      if (wasJump) {
        sim.promoteKings();
        chkExecuteMultiJumps(sim, move[2], move[3], player);
      }
      sim.promoteKings();
      float eval = chkMinimax(sim, depth - 1, alpha, beta, true, aiPlayer);
      minEval = min(minEval, eval);
      beta = min(beta, eval);
      if (beta <= alpha) break;
    }
    return minEval;
  }
}

float chkEvaluate(CHKBoard board, int aiPlayer) {
  int opp = board.opponent(aiPlayer);
  float score = 0;

  for (int r = 0; r < 8; r++) {
    for (int c = 0; c < 8; c++) {
      int v = board.grid[r][c];
      if (v == 0) continue;

      float pieceVal = 0;
      boolean isAi = (aiPlayer == 1) ? (v == 1 || v == 3) : (v == 2 || v == 4);
      boolean isKing = (v == 3 || v == 4);
      float sign = isAi ? 1 : -1;

      // Base piece value
      pieceVal = isKing ? 1.5 : 1.0;

      // Center control (cols 2-5 are center)
      if (c >= 2 && c <= 5 && r >= 2 && r <= 5) {
        pieceVal += 0.1;
      }

      // Advancement bonus for regular pieces
      if (!isKing) {
        if (isAi) {
          if (aiPlayer == 1) pieceVal += (7 - r) * 0.05;
          else pieceVal += r * 0.05;
        } else {
          if (aiPlayer == 1) pieceVal += r * 0.05;
          else pieceVal += (7 - r) * 0.05;
        }
      }

      // Back row defense
      if (!isKing) {
        if ((v == 1 && r == 7) || (v == 2 && r == 0)) {
          pieceVal += 0.15;
        }
      }

      score += sign * pieceVal;
    }
  }

  // Mobility
  float aiMobility = board.getValidMoves(aiPlayer).size();
  float oppMobility = board.getValidMoves(opp).size();
  score += (aiMobility - oppMobility) * 0.05;

  return score;
}
