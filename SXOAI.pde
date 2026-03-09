int[] sxoFindBestMove(SXOBoard b, int player) {
  ArrayList<int[]> moves = b.getValidMoves();
  if (moves.size() == 0) return null;

  sxoSortMoves(moves);

  int bestScore = Integer.MIN_VALUE;
  int[] bestMove = moves.get(0);

  for (int[] m : moves) {
    SXOBoard nb = b.copy();
    nb.makeMove(m[0], m[1], player);
    int score = sxoMinimax(nb, 4, Integer.MIN_VALUE, Integer.MAX_VALUE, false);
    if (score > bestScore) {
      bestScore = score;
      bestMove = m;
    }
  }
  return bestMove;
}

int sxoMinimax(SXOBoard b, int depth, int alpha, int beta, boolean maximizing) {
  if (b.bigWinner != 0 || depth == 0) {
    return sxoEvaluate(b);
  }

  ArrayList<int[]> moves = b.getValidMoves();
  if (moves.size() == 0) return sxoEvaluate(b);
  sxoSortMoves(moves);

  if (maximizing) {
    int maxEval = Integer.MIN_VALUE;
    for (int[] m : moves) {
      SXOBoard nb = b.copy();
      nb.makeMove(m[0], m[1], 2);
      int eval = sxoMinimax(nb, depth - 1, alpha, beta, false);
      maxEval = max(maxEval, eval);
      alpha = max(alpha, eval);
      if (beta <= alpha) break;
    }
    return maxEval;
  } else {
    int minEval = Integer.MAX_VALUE;
    for (int[] m : moves) {
      SXOBoard nb = b.copy();
      nb.makeMove(m[0], m[1], 1);
      int eval = sxoMinimax(nb, depth - 1, alpha, beta, true);
      minEval = min(minEval, eval);
      beta = min(beta, eval);
      if (beta <= alpha) break;
    }
    return minEval;
  }
}

int sxoEvaluate(SXOBoard b) {
  if (b.bigWinner == 2) return 1000;
  if (b.bigWinner == 1) return -1000;
  if (b.bigWinner == 3) return 0;

  int score = 0;

  int[][] lines = {
    {0,1,2}, {3,4,5}, {6,7,8},
    {0,3,6}, {1,4,7}, {2,5,8},
    {0,4,8}, {2,4,6}
  };

  for (int[] l : lines) {
    score += sxoEvaluateLine(b.bigGrid[l[0]], b.bigGrid[l[1]], b.bigGrid[l[2]], 50);
  }

  for (int g = 0; g < 9; g++) {
    if (b.bigGrid[g] != 0) {
      if (b.bigGrid[g] == 2) score += 10;
      else if (b.bigGrid[g] == 1) score -= 10;
      continue;
    }
    for (int[] l : lines) {
      int c0 = b.grids[g].cells[l[0]];
      int c1 = b.grids[g].cells[l[1]];
      int c2 = b.grids[g].cells[l[2]];
      score += sxoEvaluateLine(c0, c1, c2, 2);
    }
  }

  if (b.bigGrid[4] == 2) score += 15;
  else if (b.bigGrid[4] == 1) score -= 15;

  int[] corners = {0, 2, 6, 8};
  for (int c : corners) {
    if (b.bigGrid[c] == 2) score += 5;
    else if (b.bigGrid[c] == 1) score -= 5;
  }

  return score;
}

int sxoEvaluateLine(int a, int b, int c, int weight) {
  int ai = 0, human = 0;
  if (a == 2) ai++; else if (a == 1) human++;
  if (b == 2) ai++; else if (b == 1) human++;
  if (c == 2) ai++; else if (c == 1) human++;

  if (ai > 0 && human > 0) return 0;
  if (ai == 2) return weight;
  if (human == 2) return -weight;
  if (ai == 1) return 1;
  if (human == 1) return -1;
  return 0;
}

void sxoSortMoves(ArrayList<int[]> moves) {
  java.util.Collections.sort(moves, new java.util.Comparator<int[]>() {
    int priority(int[] m) {
      int c = m[1];
      if (c == 4) return 0;
      if (c == 0 || c == 2 || c == 6 || c == 8) return 1;
      return 2;
    }
    public int compare(int[] a, int[] b) {
      return priority(a) - priority(b);
    }
  });
}
