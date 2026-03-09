int[] hexFindBestMove(HEXBoard board, int player) {
  ArrayList<int[]> candidates = hexGetCandidates(board);
  if (candidates.size() == 0) return null;

  // First move: play center
  if (board.moveCount <= 1) {
    return new int[] {HEX_BOARD_SIZE / 2, HEX_BOARD_SIZE / 2};
  }

  float bestScore = -999999;
  int[] bestMove = candidates.get(0);

  for (int[] move : candidates) {
    HEXBoard copy = board.copy();
    copy.placeStone(move[0], move[1], player);
    if (copy.checkWin(player)) return move;
    float score = hexMinimax(copy, 2, -999999, 999999, false, player);
    if (score > bestScore) {
      bestScore = score;
      bestMove = move;
    }
  }
  return bestMove;
}

float hexMinimax(HEXBoard board, int depth, float alpha, float beta, boolean maximizing, int aiPlayer) {
  int opponent = (aiPlayer == 1) ? 2 : 1;

  if (board.checkWin(aiPlayer)) return 10000 + depth;
  if (board.checkWin(opponent)) return -10000 - depth;
  if (depth == 0) return hexEvaluate(board, aiPlayer);

  ArrayList<int[]> candidates = hexGetCandidates(board);
  if (candidates.size() == 0) return hexEvaluate(board, aiPlayer);

  // Limit candidates at deeper levels
  int limit = (depth <= 1) ? 15 : 25;
  if (candidates.size() > limit) {
    ArrayList<int[]> trimmed = new ArrayList<int[]>();
    for (int i = 0; i < limit; i++) trimmed.add(candidates.get(i));
    candidates = trimmed;
  }

  if (maximizing) {
    float maxEval = -999999;
    for (int[] move : candidates) {
      HEXBoard copy = board.copy();
      copy.placeStone(move[0], move[1], aiPlayer);
      float eval = hexMinimax(copy, depth - 1, alpha, beta, false, aiPlayer);
      maxEval = max(maxEval, eval);
      alpha = max(alpha, eval);
      if (beta <= alpha) break;
    }
    return maxEval;
  } else {
    float minEval = 999999;
    for (int[] move : candidates) {
      HEXBoard copy = board.copy();
      copy.placeStone(move[0], move[1], opponent);
      float eval = hexMinimax(copy, depth - 1, alpha, beta, true, aiPlayer);
      minEval = min(minEval, eval);
      beta = min(beta, eval);
      if (beta <= alpha) break;
    }
    return minEval;
  }
}

float hexEvaluate(HEXBoard board, int aiPlayer) {
  int opponent = (aiPlayer == 1) ? 2 : 1;
  float aiDist = hexShortestPath(board, aiPlayer);
  float oppDist = hexShortestPath(board, opponent);
  float score = (oppDist - aiDist) * 10;

  // Center bias
  float centerR = (HEX_BOARD_SIZE - 1) / 2.0;
  float centerC = (HEX_BOARD_SIZE - 1) / 2.0;
  for (int r = 0; r < HEX_BOARD_SIZE; r++) {
    for (int c = 0; c < HEX_BOARD_SIZE; c++) {
      if (board.grid[r][c] != 0) {
        float dist = abs(r - centerR) + abs(c - centerC);
        float centerVal = max(0, (HEX_BOARD_SIZE - dist)) * 0.3;
        if (board.grid[r][c] == aiPlayer) score += centerVal;
        else score -= centerVal;
      }
    }
  }

  // Bridge bonus: two own stones with two shared empty neighbors
  for (int r = 0; r < HEX_BOARD_SIZE; r++) {
    for (int c = 0; c < HEX_BOARD_SIZE; c++) {
      if (board.grid[r][c] == aiPlayer) {
        ArrayList<int[]> nbrs = board.getNeighbors(r, c);
        for (int[] n : nbrs) {
          if (board.grid[n[0]][n[1]] == aiPlayer) {
            // Count shared empty neighbors
            ArrayList<int[]> nbrs1 = board.getNeighbors(r, c);
            ArrayList<int[]> nbrs2 = board.getNeighbors(n[0], n[1]);
            int shared = 0;
            for (int[] a : nbrs1) {
              if (board.grid[a[0]][a[1]] != 0) continue;
              for (int[] b : nbrs2) {
                if (a[0] == b[0] && a[1] == b[1]) { shared++; break; }
              }
            }
            if (shared >= 2) score += 1.5;
          }
        }
      }
    }
  }

  return score;
}

// Dijkstra-like shortest path: minimum empty cells needed to connect edges
float hexShortestPath(HEXBoard board, int player) {
  // Use priority queue simulation with BFS on cost
  // Cost: 0 for own cell, 1 for empty cell, infinity for opponent cell
  int INF = 9999;
  int[][] dist = new int[HEX_BOARD_SIZE][HEX_BOARD_SIZE];
  for (int r = 0; r < HEX_BOARD_SIZE; r++)
    for (int c = 0; c < HEX_BOARD_SIZE; c++)
      dist[r][c] = INF;

  // Simple Dijkstra with ArrayList (0-1 BFS)
  // Deque simulation: cost 0 items go to front, cost 1 items go to back
  ArrayList<int[]> deque = new ArrayList<int[]>(); // [row, col]
  int dequeStart = 0;

  int opponent = (player == 1) ? 2 : 1;

  if (player == 1) {
    // Start from left edge (col=0)
    for (int r = 0; r < HEX_BOARD_SIZE; r++) {
      if (board.grid[r][0] == opponent) continue;
      int cost = (board.grid[r][0] == player) ? 0 : 1;
      if (cost < dist[r][0]) {
        dist[r][0] = cost;
        deque.add(new int[] {r, 0});
      }
    }
  } else {
    // Start from top edge (row=0)
    for (int c = 0; c < HEX_BOARD_SIZE; c++) {
      if (board.grid[0][c] == opponent) continue;
      int cost = (board.grid[0][c] == player) ? 0 : 1;
      if (cost < dist[0][c]) {
        dist[0][c] = cost;
        deque.add(new int[] {0, c});
      }
    }
  }

  while (dequeStart < deque.size()) {
    int[] cur = deque.get(dequeStart);
    dequeStart++;
    int cr = cur[0], cc = cur[1];

    ArrayList<int[]> nbrs = board.getNeighbors(cr, cc);
    for (int[] n : nbrs) {
      if (board.grid[n[0]][n[1]] == opponent) continue;
      int ncost = (board.grid[n[0]][n[1]] == player) ? 0 : 1;
      int newDist = dist[cr][cc] + ncost;
      if (newDist < dist[n[0]][n[1]]) {
        dist[n[0]][n[1]] = newDist;
        deque.add(n);
      }
    }
  }

  float best = INF;
  if (player == 1) {
    for (int r = 0; r < HEX_BOARD_SIZE; r++)
      best = min(best, dist[r][HEX_BOARD_SIZE - 1]);
  } else {
    for (int c = 0; c < HEX_BOARD_SIZE; c++)
      best = min(best, dist[HEX_BOARD_SIZE - 1][c]);
  }
  return best;
}

ArrayList<int[]> hexGetCandidates(HEXBoard board) {
  boolean[][] candidate = new boolean[HEX_BOARD_SIZE][HEX_BOARD_SIZE];
  ArrayList<int[]> result = new ArrayList<int[]>();

  if (board.moveCount == 0) {
    result.add(new int[] {HEX_BOARD_SIZE / 2, HEX_BOARD_SIZE / 2});
    return result;
  }

  // Cells adjacent to existing stones
  for (int r = 0; r < HEX_BOARD_SIZE; r++) {
    for (int c = 0; c < HEX_BOARD_SIZE; c++) {
      if (board.grid[r][c] != 0) {
        ArrayList<int[]> nbrs = board.getNeighbors(r, c);
        for (int[] n : nbrs) {
          if (board.grid[n[0]][n[1]] == 0 && !candidate[n[0]][n[1]]) {
            candidate[n[0]][n[1]] = true;
            result.add(n);
          }
        }
      }
    }
  }

  // Also add 2-distance neighbors for edge cells
  for (int r = 0; r < HEX_BOARD_SIZE; r++) {
    for (int c = 0; c < HEX_BOARD_SIZE; c++) {
      if (board.grid[r][c] != 0) {
        ArrayList<int[]> nbrs = board.getNeighbors(r, c);
        for (int[] n : nbrs) {
          if (board.grid[n[0]][n[1]] == 0) {
            ArrayList<int[]> nbrs2 = board.getNeighbors(n[0], n[1]);
            for (int[] n2 : nbrs2) {
              if (board.grid[n2[0]][n2[1]] == 0 && !candidate[n2[0]][n2[1]]) {
                candidate[n2[0]][n2[1]] = true;
                result.add(n2);
              }
            }
          }
        }
      }
    }
  }

  // Limit to ~30 candidates sorted by center proximity
  if (result.size() > 30) {
    final float center = (HEX_BOARD_SIZE - 1) / 2.0;
    // Sort by distance to center (insertion sort for Processing compatibility)
    for (int i = 1; i < result.size(); i++) {
      int[] key = result.get(i);
      float keyDist = abs(key[0] - center) + abs(key[1] - center);
      int j = i - 1;
      while (j >= 0) {
        int[] jItem = result.get(j);
        float jDist = abs(jItem[0] - center) + abs(jItem[1] - center);
        if (jDist > keyDist) {
          result.set(j + 1, jItem);
          j--;
        } else break;
      }
      result.set(j + 1, key);
    }
    ArrayList<int[]> trimmed = new ArrayList<int[]>();
    for (int i = 0; i < 30; i++) trimmed.add(result.get(i));
    return trimmed;
  }

  if (result.size() == 0) return board.getEmptyCells();
  return result;
}
