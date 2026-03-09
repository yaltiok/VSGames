int[][] REV_WEIGHTS = {
  {100, -20,  10,  5,  5,  10, -20, 100},
  {-20, -50,  -2, -2, -2,  -2, -50, -20},
  { 10,  -2,   1,  1,  1,   1,  -2,  10},
  {  5,  -2,   1,  0,  0,   1,  -2,   5},
  {  5,  -2,   1,  0,  0,   1,  -2,   5},
  { 10,  -2,   1,  1,  1,   1,  -2,  10},
  {-20, -50,  -2, -2, -2,  -2, -50, -20},
  {100, -20,  10,  5,  5,  10, -20, 100}
};

final int REV_AI_DEPTH = 6;

int[] revFindBestMove(REVBoard board, int player) {
  ArrayList<int[]> moves = board.getValidMoves(player);
  if (moves.size() == 0) return null;

  float bestScore = -1e9;
  int[] bestMove = moves.get(0);

  for (int[] m : moves) {
    REVBoard copy = board.copy();
    copy.makeMove(m[0], m[1], player);
    float score = revMinimax(copy, REV_AI_DEPTH - 1, -1e9, 1e9, false, player);
    if (score > bestScore) {
      bestScore = score;
      bestMove = m;
    }
  }
  return bestMove;
}

float revMinimax(REVBoard board, int depth, float alpha, float beta, boolean maximizing, int aiPlayer) {
  if (depth == 0 || board.isGameOver()) {
    return revEvaluate(board, aiPlayer);
  }

  int current = maximizing ? aiPlayer : ((aiPlayer == 1) ? 2 : 1);
  ArrayList<int[]> moves = board.getValidMoves(current);

  if (moves.size() == 0) {
    return revMinimax(board, depth - 1, alpha, beta, !maximizing, aiPlayer);
  }

  if (maximizing) {
    float maxEval = -1e9;
    for (int[] m : moves) {
      REVBoard copy = board.copy();
      copy.makeMove(m[0], m[1], current);
      float eval = revMinimax(copy, depth - 1, alpha, beta, false, aiPlayer);
      maxEval = max(maxEval, eval);
      alpha = max(alpha, eval);
      if (beta <= alpha) break;
    }
    return maxEval;
  } else {
    float minEval = 1e9;
    for (int[] m : moves) {
      REVBoard copy = board.copy();
      copy.makeMove(m[0], m[1], current);
      float eval = revMinimax(copy, depth - 1, alpha, beta, true, aiPlayer);
      minEval = min(minEval, eval);
      beta = min(beta, eval);
      if (beta <= alpha) break;
    }
    return minEval;
  }
}

float revEvaluate(REVBoard board, int aiPlayer) {
  int opponent = (aiPlayer == 1) ? 2 : 1;
  int[] counts = board.countDiscs();
  int totalDiscs = counts[0] + counts[1];
  int aiDiscs = (aiPlayer == 1) ? counts[0] : counts[1];
  int oppDiscs = (aiPlayer == 1) ? counts[1] : counts[0];

  if (board.isGameOver()) {
    if (aiDiscs > oppDiscs) return 10000 + (aiDiscs - oppDiscs);
    if (oppDiscs > aiDiscs) return -10000 - (oppDiscs - aiDiscs);
    return 0;
  }

  float score = 0;

  // positional weights
  float posScore = 0;
  for (int r = 0; r < 8; r++) {
    for (int c = 0; c < 8; c++) {
      if (board.grid[r][c] == aiPlayer) posScore += REV_WEIGHTS[r][c];
      else if (board.grid[r][c] == opponent) posScore -= REV_WEIGHTS[r][c];
    }
  }
  score += posScore;

  // mobility
  int aiMobility = board.getValidMoves(aiPlayer).size();
  int oppMobility = board.getValidMoves(opponent).size();
  if (aiMobility + oppMobility > 0) {
    score += 10.0 * (aiMobility - oppMobility) / (aiMobility + oppMobility + 1);
  }

  // corner occupancy
  int[][] corners = {{0,0},{0,7},{7,0},{7,7}};
  for (int[] corner : corners) {
    if (board.grid[corner[0]][corner[1]] == aiPlayer) score += 25;
    else if (board.grid[corner[0]][corner[1]] == opponent) score -= 25;
  }

  // endgame: disc count matters more
  if (totalDiscs > 50) {
    score += 3.0 * (aiDiscs - oppDiscs);
  }

  return score;
}
