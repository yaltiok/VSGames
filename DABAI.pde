int[] dabFindBestMove(DABBoard board, int player) {
  ArrayList<int[]> moves = board.getAvailableLines();
  if (moves.size() == 0) return null;

  // 1. complete any box immediately
  for (int[] m : moves) {
    DABBoard sim = board.copy();
    int completed = sim.placeLine(m[0], m[1], m[2], player);
    if (completed > 0) return m;
  }

  // 2. safe moves (don't give opponent a 3rd side on any box)
  ArrayList<int[]> safeMoves = new ArrayList<int[]>();
  for (int[] m : moves) {
    if (!dabGivesBox(board, m[0], m[1], m[2])) {
      safeMoves.add(m);
    }
  }
  if (safeMoves.size() > 0) {
    // among safe moves, use minimax for best pick
    int depth = dabChooseDepth(moves.size());
    float bestScore = -100000;
    int[] bestMove = safeMoves.get(0);
    for (int[] m : safeMoves) {
      DABBoard sim = board.copy();
      int completed = sim.placeLine(m[0], m[1], m[2], player);
      int nextPlayer = (completed > 0) ? player : dabOpponent(player);
      float score = dabMinimax(sim, depth - 1, -100000, 100000, nextPlayer != player, player, nextPlayer);
      if (score > bestScore) {
        bestScore = score;
        bestMove = m;
      }
    }
    return bestMove;
  }

  // 3. all moves give opponent a box — pick the one giving shortest chain
  int depth = dabChooseDepth(moves.size());
  float bestScore = -100000;
  int[] bestMove = moves.get(0);
  for (int[] m : moves) {
    DABBoard sim = board.copy();
    int completed = sim.placeLine(m[0], m[1], m[2], player);
    int nextPlayer = (completed > 0) ? player : dabOpponent(player);
    float score = dabMinimax(sim, depth - 1, -100000, 100000, nextPlayer != player, player, nextPlayer);
    if (score > bestScore) {
      bestScore = score;
      bestMove = m;
    }
  }
  return bestMove;
}

int dabChooseDepth(int movesLeft) {
  if (movesLeft <= 8) return movesLeft;
  if (movesLeft <= 14) return 8;
  return 6;
}

float dabMinimax(DABBoard board, int depth, float alpha, float beta, boolean maximizing, int aiPlayer, int currentPlayer) {
  if (board.isGameOver() || depth <= 0) {
    return dabEvaluate(board, aiPlayer);
  }

  ArrayList<int[]> moves = board.getAvailableLines();

  if (maximizing) {
    float best = -100000;
    for (int[] m : moves) {
      DABBoard sim = board.copy();
      int completed = sim.placeLine(m[0], m[1], m[2], currentPlayer);
      int nextPlayer = (completed > 0) ? currentPlayer : dabOpponent(currentPlayer);
      boolean nextMax = (nextPlayer == aiPlayer);
      float score = dabMinimax(sim, depth - 1, alpha, beta, nextMax, aiPlayer, nextPlayer);
      if (score > best) best = score;
      if (best > alpha) alpha = best;
      if (beta <= alpha) break;
    }
    return best;
  } else {
    float best = 100000;
    for (int[] m : moves) {
      DABBoard sim = board.copy();
      int completed = sim.placeLine(m[0], m[1], m[2], currentPlayer);
      int nextPlayer = (completed > 0) ? currentPlayer : dabOpponent(currentPlayer);
      boolean nextMax = (nextPlayer == aiPlayer);
      float score = dabMinimax(sim, depth - 1, alpha, beta, nextMax, aiPlayer, nextPlayer);
      if (score < best) best = score;
      if (best < beta) beta = best;
      if (beta <= alpha) break;
    }
    return best;
  }
}

float dabEvaluate(DABBoard board, int aiPlayer) {
  int opp = dabOpponent(aiPlayer);
  float score = (board.scores[aiPlayer] - board.scores[opp]) * 10;

  // penalize giving opponent boxes with 3 sides
  ArrayList<int[]> moves = board.getAvailableLines();
  int safeCount = 0;
  int dangerCount = 0;
  for (int[] m : moves) {
    if (dabGivesBox(board, m[0], m[1], m[2])) {
      dangerCount++;
    } else {
      safeCount++;
    }
  }

  // having more safe moves is good
  score += safeCount * 0.5;

  // if it's a position where few safe moves remain, that's tricky
  if (safeCount == 0 && moves.size() > 0) {
    score -= 2;
  }

  return score;
}

boolean dabGivesBox(DABBoard board, int type, int row, int col) {
  // check if placing this line would create a box with 3 sides (giving opponent ability to complete)
  // actually: check if any adjacent box would have 3 sides AFTER this line is placed
  // meaning: adjacent box currently has 2 sides, this line makes it 3
  // wait — we want to check if this move gives the OPPONENT a chance to complete
  // so: after placing, check if any adjacent box now has exactly 3 sides

  if (type == 0) {
    // horizontal at (row, col) — adjacent boxes: (row, col) and (row-1, col)
    if (row < 4 && board.boxes[row][col] == 0) {
      int sides = board.countSides(row, col);
      if (sides == 2) return true; // will become 3
    }
    if (row > 0 && board.boxes[row - 1][col] == 0) {
      int sides = board.countSides(row - 1, col);
      if (sides == 2) return true;
    }
  } else {
    // vertical at (row, col) — adjacent boxes: (row, col) and (row, col-1)
    if (col < 4 && board.boxes[row][col] == 0) {
      int sides = board.countSides(row, col);
      if (sides == 2) return true;
    }
    if (col > 0 && board.boxes[row][col - 1] == 0) {
      int sides = board.countSides(row, col - 1);
      if (sides == 2) return true;
    }
  }
  return false;
}

int dabOpponent(int player) {
  return (player == 1) ? 2 : 1;
}
