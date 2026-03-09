int[] qrtFindBestPlacement(QRTBoard board, int aiPlayer) {
  ArrayList<int[]> empty = board.getEmptyCells();
  if (empty.size() == 0) return new int[]{0, 0};

  float bestScore = -1e9;
  int[] bestCell = empty.get(0);

  for (int[] cell : empty) {
    QRTBoard copy = board.copy();
    copy.placePiece(cell[0], cell[1], aiPlayer);
    if (copy.checkWin() == aiPlayer) return cell;

    float score = qrtMinimax(copy, 4, -1e9, 1e9, false, (aiPlayer == 1) ? 2 : 1, aiPlayer);
    if (score > bestScore) {
      bestScore = score;
      bestCell = cell;
    }
  }
  return bestCell;
}

int qrtFindBestPieceToGive(QRTBoard board, int aiPlayer) {
  ArrayList<Integer> pieces = board.getAvailablePieces();
  if (pieces.size() == 0) return -1;

  int opponent = (aiPlayer == 1) ? 2 : 1;
  float bestScore = -1e9;
  int bestPiece = pieces.get(0);

  for (int piece : pieces) {
    QRTBoard copy = board.copy();
    copy.choosePiece(piece);
    float score = qrtMinimax(copy, 4, -1e9, 1e9, true, opponent, aiPlayer);
    if (score > bestScore) {
      bestScore = score;
      bestPiece = piece;
    }
  }
  return bestPiece;
}

float qrtMinimax(QRTBoard board, int depth, float alpha, float beta, boolean isPlacing, int currentPlayer, int aiPlayer) {
  int opponent = (aiPlayer == 1) ? 2 : 1;
  int w = board.checkWin();
  if (w == aiPlayer) return 100000 + depth;
  if (w == opponent) return -100000 - depth;
  if (board.isFull()) return 0;
  if (depth == 0) return qrtEvaluate(board, aiPlayer);

  boolean maximizing = (currentPlayer == aiPlayer);

  if (isPlacing) {
    ArrayList<int[]> empty = board.getEmptyCells();
    if (maximizing) {
      float maxEval = -1e9;
      for (int[] cell : empty) {
        QRTBoard copy = board.copy();
        copy.placePiece(cell[0], cell[1], currentPlayer);
        if (copy.checkWin() == currentPlayer) return 100000 + depth;
        float eval = qrtMinimax(copy, depth - 1, alpha, beta, false, currentPlayer, aiPlayer);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      float minEval = 1e9;
      for (int[] cell : empty) {
        QRTBoard copy = board.copy();
        copy.placePiece(cell[0], cell[1], currentPlayer);
        if (copy.checkWin() == currentPlayer) return -100000 - depth;
        float eval = qrtMinimax(copy, depth - 1, alpha, beta, false, currentPlayer, aiPlayer);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  } else {
    ArrayList<Integer> pieces = board.getAvailablePieces();
    int nextPlayer = (currentPlayer == 1) ? 2 : 1;
    if (maximizing) {
      float maxEval = -1e9;
      for (int piece : pieces) {
        QRTBoard copy = board.copy();
        copy.choosePiece(piece);
        float eval = qrtMinimax(copy, depth - 1, alpha, beta, true, nextPlayer, aiPlayer);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      float minEval = 1e9;
      for (int piece : pieces) {
        QRTBoard copy = board.copy();
        copy.choosePiece(piece);
        float eval = qrtMinimax(copy, depth - 1, alpha, beta, true, nextPlayer, aiPlayer);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }
}

float qrtEvaluate(QRTBoard board, int aiPlayer) {
  float score = 0;
  int[][] lines = {
    {0,0, 0,1, 0,2, 0,3},
    {1,0, 1,1, 1,2, 1,3},
    {2,0, 2,1, 2,2, 2,3},
    {3,0, 3,1, 3,2, 3,3},
    {0,0, 1,0, 2,0, 3,0},
    {0,1, 1,1, 2,1, 3,1},
    {0,2, 1,2, 2,2, 3,2},
    {0,3, 1,3, 2,3, 3,3},
    {0,0, 1,1, 2,2, 3,3},
    {0,3, 1,2, 2,1, 3,0}
  };

  for (int[] line : lines) {
    int[] pieces = new int[4];
    int filled = 0;
    for (int i = 0; i < 4; i++) {
      pieces[i] = board.grid[line[i*2]][line[i*2+1]];
      if (pieces[i] != -1) filled++;
    }
    if (filled == 3) {
      int[] filledPieces = new int[3];
      int idx = 0;
      for (int i = 0; i < 4; i++) {
        if (pieces[i] != -1) filledPieces[idx++] = pieces[i];
      }
      for (int bit = 0; bit < 4; bit++) {
        int mask = 1 << bit;
        if (((filledPieces[0] & mask) == (filledPieces[1] & mask)) &&
            ((filledPieces[1] & mask) == (filledPieces[2] & mask))) {
          score -= 30;
        }
      }
    } else if (filled == 2) {
      score += 5;
    }
  }

  score += board.getAvailablePieces().size() * 0.5;

  return score;
}
