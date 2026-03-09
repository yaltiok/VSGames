int[] nmmFindBestMove(NMMBoard board, int player, boolean removing, int selectedPiece) {
  if (removing) {
    return nmmFindBestRemoval(board, player);
  }

  int phase = board.getPhase(player);
  if (phase == NMM_PHASE_PLACE) {
    return nmmFindBestPlacement(board, player);
  } else {
    return nmmFindBestMovement(board, player, phase);
  }
}

int[] nmmFindBestRemoval(NMMBoard board, int player) {
  int opponent = (player == 1) ? 2 : 1;
  int bestPos = -1;
  float bestScore = -99999;

  for (int i = 0; i < 24; i++) {
    if (!board.canRemove(i, player)) continue;
    NMMBoard nb = board.copy();
    nb.removePiece(i);
    float score = nmmEvaluate(nb, player);
    if (score > bestScore) {
      bestScore = score;
      bestPos = i;
    }
  }
  if (bestPos == -1) return null;
  return new int[]{bestPos};
}

int[] nmmFindBestPlacement(NMMBoard board, int player) {
  ArrayList<int[]> moves = board.getValidMoves(player, NMM_PHASE_PLACE);
  if (moves.size() == 0) return null;

  float bestScore = -99999;
  int[] bestMove = moves.get(0);
  int depth = 4;

  for (int[] m : moves) {
    NMMBoard nb = board.copy();
    nb.placePiece(m[0], player);

    float score;
    if (nb.formsMill(m[0], player)) {
      // Try each removal and pick best
      score = -99999;
      int opponent = (player == 1) ? 2 : 1;
      for (int r = 0; r < 24; r++) {
        if (!nb.canRemove(r, player)) continue;
        NMMBoard nr = nb.copy();
        nr.removePiece(r);
        float rs = nmmMinimax(nr, depth - 1, -99999, 99999, false, player, false);
        score = max(score, rs);
      }
      if (score == -99999) score = nmmMinimax(nb, depth - 1, -99999, 99999, false, player, false);
    } else {
      score = nmmMinimax(nb, depth - 1, -99999, 99999, false, player, false);
    }

    if (score > bestScore) {
      bestScore = score;
      bestMove = m;
    }
  }
  return bestMove;
}

int[] nmmFindBestMovement(NMMBoard board, int player, int phase) {
  ArrayList<int[]> moves = board.getValidMoves(player, phase);
  if (moves.size() == 0) return null;

  float bestScore = -99999;
  int[] bestMove = moves.get(0);
  int depth = 5;

  // Limit search if too many moves
  if (moves.size() > 40) depth = 3;

  for (int[] m : moves) {
    NMMBoard nb = board.copy();
    nb.movePiece(m[0], m[1], player);

    float score;
    if (nb.formsMill(m[1], player)) {
      score = -99999;
      int opponent = (player == 1) ? 2 : 1;
      for (int r = 0; r < 24; r++) {
        if (!nb.canRemove(r, player)) continue;
        NMMBoard nr = nb.copy();
        nr.removePiece(r);
        float rs = nmmMinimax(nr, depth - 1, -99999, 99999, false, player, false);
        score = max(score, rs);
      }
      if (score == -99999) score = nmmMinimax(nb, depth - 1, -99999, 99999, false, player, false);
    } else {
      score = nmmMinimax(nb, depth - 1, -99999, 99999, false, player, false);
    }

    if (score > bestScore) {
      bestScore = score;
      bestMove = m;
    }
  }
  return bestMove;
}

float nmmMinimax(NMMBoard board, int depth, float alpha, float beta, boolean maximizing, int aiPlayer, boolean removing) {
  int opponent = (aiPlayer == 1) ? 2 : 1;
  int currentP = maximizing ? aiPlayer : opponent;

  // Terminal checks
  int curPhase = board.getPhase(currentP);
  if (curPhase != NMM_PHASE_PLACE) {
    if (board.piecesOnBoard[currentP] < 3) {
      return maximizing ? -5000 : 5000;
    }
    if (!board.hasValidMoves(currentP, curPhase)) {
      return maximizing ? -5000 : 5000;
    }
  }

  if (depth == 0) return nmmEvaluate(board, aiPlayer);

  int phase = board.getPhase(currentP);
  ArrayList<int[]> moves;
  if (phase == NMM_PHASE_PLACE) {
    moves = board.getValidMoves(currentP, NMM_PHASE_PLACE);
  } else {
    moves = board.getValidMoves(currentP, phase);
  }

  if (moves.size() == 0) return nmmEvaluate(board, aiPlayer);

  if (maximizing) {
    float maxEval = -99999;
    for (int[] m : moves) {
      NMMBoard nb = board.copy();
      if (phase == NMM_PHASE_PLACE) {
        nb.placePiece(m[0], currentP);
        if (nb.formsMill(m[0], currentP)) {
          float best = nmmBestRemovalScore(nb, currentP, depth, alpha, beta, true, aiPlayer);
          maxEval = max(maxEval, best);
        } else {
          maxEval = max(maxEval, nmmMinimax(nb, depth - 1, alpha, beta, false, aiPlayer, false));
        }
      } else {
        nb.movePiece(m[0], m[1], currentP);
        if (nb.formsMill(m[1], currentP)) {
          float best = nmmBestRemovalScore(nb, currentP, depth, alpha, beta, true, aiPlayer);
          maxEval = max(maxEval, best);
        } else {
          maxEval = max(maxEval, nmmMinimax(nb, depth - 1, alpha, beta, false, aiPlayer, false));
        }
      }
      alpha = max(alpha, maxEval);
      if (beta <= alpha) break;
    }
    return maxEval;
  } else {
    float minEval = 99999;
    for (int[] m : moves) {
      NMMBoard nb = board.copy();
      if (phase == NMM_PHASE_PLACE) {
        nb.placePiece(m[0], currentP);
        if (nb.formsMill(m[0], currentP)) {
          float best = nmmBestRemovalScore(nb, currentP, depth, alpha, beta, false, aiPlayer);
          minEval = min(minEval, best);
        } else {
          minEval = min(minEval, nmmMinimax(nb, depth - 1, alpha, beta, true, aiPlayer, false));
        }
      } else {
        nb.movePiece(m[0], m[1], currentP);
        if (nb.formsMill(m[1], currentP)) {
          float best = nmmBestRemovalScore(nb, currentP, depth, alpha, beta, false, aiPlayer);
          minEval = min(minEval, best);
        } else {
          minEval = min(minEval, nmmMinimax(nb, depth - 1, alpha, beta, true, aiPlayer, false));
        }
      }
      beta = min(beta, minEval);
      if (beta <= alpha) break;
    }
    return minEval;
  }
}

float nmmBestRemovalScore(NMMBoard board, int removingPlayer, int depth, float alpha, float beta, boolean wasMaximizing, int aiPlayer) {
  float best = wasMaximizing ? -99999 : 99999;
  boolean found = false;
  for (int r = 0; r < 24; r++) {
    if (!board.canRemove(r, removingPlayer)) continue;
    found = true;
    NMMBoard nr = board.copy();
    nr.removePiece(r);
    float score = nmmMinimax(nr, depth - 1, alpha, beta, !wasMaximizing, aiPlayer, false);
    if (wasMaximizing) {
      best = max(best, score);
      alpha = max(alpha, best);
    } else {
      best = min(best, score);
      beta = min(beta, best);
    }
    if (beta <= alpha) break;
  }
  if (!found) return nmmEvaluate(board, aiPlayer);
  return best;
}

float nmmEvaluate(NMMBoard board, int aiPlayer) {
  int opponent = (aiPlayer == 1) ? 2 : 1;
  float score = 0;

  // Piece count difference (most important)
  int aiTotal = board.piecesOnBoard[aiPlayer] + board.piecesInHand[aiPlayer];
  int oppTotal = board.piecesOnBoard[opponent] + board.piecesInHand[opponent];
  score += (aiTotal - oppTotal) * 100;

  // On-board pieces
  score += (board.piecesOnBoard[aiPlayer] - board.piecesOnBoard[opponent]) * 20;

  // Mill count
  int aiMills = 0, oppMills = 0;
  for (int[] mill : board.mills) {
    if (board.positions[mill[0]] == aiPlayer && board.positions[mill[1]] == aiPlayer && board.positions[mill[2]] == aiPlayer) aiMills++;
    if (board.positions[mill[0]] == opponent && board.positions[mill[1]] == opponent && board.positions[mill[2]] == opponent) oppMills++;
  }
  score += (aiMills - oppMills) * 50;

  // Potential mills (2 of 3 with empty third)
  int aiPotential = 0, oppPotential = 0;
  for (int[] mill : board.mills) {
    int ai = 0, opp = 0, empty = 0;
    for (int m : mill) {
      if (board.positions[m] == aiPlayer) ai++;
      else if (board.positions[m] == opponent) opp++;
      else empty++;
    }
    if (ai == 2 && empty == 1) aiPotential++;
    if (opp == 2 && empty == 1) oppPotential++;
  }
  score += (aiPotential - oppPotential) * 25;

  // Mobility (in move/fly phase)
  int aiPhase = board.getPhase(aiPlayer);
  int oppPhase = board.getPhase(opponent);
  if (aiPhase != NMM_PHASE_PLACE) {
    int aiMob = board.getValidMoves(aiPlayer, aiPhase).size();
    score += aiMob * 5;
  }
  if (oppPhase != NMM_PHASE_PLACE) {
    int oppMob = board.getValidMoves(opponent, oppPhase).size();
    score -= oppMob * 5;
  }

  // Blocked pieces penalty
  if (oppPhase == NMM_PHASE_MOVE && !board.hasValidMoves(opponent, oppPhase)) {
    score += 2000;
  }
  if (aiPhase == NMM_PHASE_MOVE && !board.hasValidMoves(aiPlayer, aiPhase)) {
    score -= 2000;
  }

  // Losing condition
  if (oppPhase != NMM_PHASE_PLACE && board.piecesOnBoard[opponent] < 3) {
    score += 5000;
  }
  if (aiPhase != NMM_PHASE_PLACE && board.piecesOnBoard[aiPlayer] < 3) {
    score -= 5000;
  }

  return score;
}
