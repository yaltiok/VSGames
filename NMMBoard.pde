// NMM Phase constants
final int NMM_PHASE_PLACE = 0;
final int NMM_PHASE_MOVE = 1;
final int NMM_PHASE_FLY = 2;

class NMMBoard {
  int[] positions;
  int[] piecesInHand;
  int[] piecesOnBoard;

  // Adjacency list for each of the 24 positions
  int[][] adjacency = {
    {1, 9},          // 0
    {0, 2, 4},       // 1
    {1, 14},         // 2
    {4, 10},         // 3
    {1, 3, 5, 7},    // 4
    {4, 13},         // 5
    {7, 11},         // 6
    {4, 6, 8},       // 7
    {7, 12},         // 8
    {0, 10, 21},     // 9
    {3, 9, 11, 18},  // 10
    {6, 10, 15},     // 11
    {8, 13, 17},     // 12
    {5, 12, 14, 20}, // 13
    {2, 13, 23},     // 14
    {11, 16},        // 15
    {15, 17, 19},    // 16
    {12, 16},        // 17
    {10, 19},        // 18
    {16, 18, 20, 22},// 19
    {13, 19},        // 20
    {9, 22},         // 21
    {19, 21, 23},    // 22
    {14, 22}         // 23
  };

  // 16 possible mill lines
  int[][] mills = {
    {0, 1, 2},    {3, 4, 5},    {6, 7, 8},       // top horizontals
    {15, 16, 17}, {18, 19, 20}, {21, 22, 23},     // bottom horizontals
    {9, 10, 11},  {12, 13, 14},                    // middle horizontals
    {0, 9, 21},   {3, 10, 18},  {6, 11, 15},      // left verticals
    {1, 4, 7},    {16, 19, 22},                    // center verticals
    {8, 12, 17},  {5, 13, 20},  {2, 14, 23}       // right verticals
  };

  NMMBoard() {
    positions = new int[24];
    piecesInHand = new int[3];
    piecesOnBoard = new int[3];
    piecesInHand[1] = 9;
    piecesInHand[2] = 9;
  }

  boolean isAdjacent(int a, int b) {
    for (int n : adjacency[a]) {
      if (n == b) return true;
    }
    return false;
  }

  boolean formsMill(int pos, int player) {
    for (int[] mill : mills) {
      boolean inMill = false;
      for (int m : mill) {
        if (m == pos) { inMill = true; break; }
      }
      if (!inMill) continue;
      boolean allPlayer = true;
      for (int m : mill) {
        if (positions[m] != player) { allPlayer = false; break; }
      }
      if (allPlayer) return true;
    }
    return false;
  }

  // Returns the mill indices if placing at pos forms a mill for player, null otherwise
  int[] getMillPositions(int pos, int player) {
    for (int[] mill : mills) {
      boolean inMill = false;
      for (int m : mill) {
        if (m == pos) { inMill = true; break; }
      }
      if (!inMill) continue;
      boolean allPlayer = true;
      for (int m : mill) {
        if (positions[m] != player) { allPlayer = false; break; }
      }
      if (allPlayer) return mill;
    }
    return null;
  }

  boolean allInMills(int player) {
    for (int i = 0; i < 24; i++) {
      if (positions[i] == player && !formsMill(i, player)) {
        return false;
      }
    }
    return true;
  }

  boolean canRemove(int pos, int player) {
    int opponent = (player == 1) ? 2 : 1;
    if (positions[pos] != opponent) return false;
    if (!formsMill(pos, opponent)) return true;
    return allInMills(opponent);
  }

  ArrayList<int[]> getValidMoves(int player, int phase) {
    ArrayList<int[]> moves = new ArrayList<int[]>();
    if (phase == NMM_PHASE_PLACE) {
      for (int i = 0; i < 24; i++) {
        if (positions[i] == 0) {
          moves.add(new int[]{i});
        }
      }
    } else if (phase == NMM_PHASE_MOVE) {
      for (int i = 0; i < 24; i++) {
        if (positions[i] != player) continue;
        for (int n : adjacency[i]) {
          if (positions[n] == 0) {
            moves.add(new int[]{i, n});
          }
        }
      }
    } else { // FLY
      for (int i = 0; i < 24; i++) {
        if (positions[i] != player) continue;
        for (int j = 0; j < 24; j++) {
          if (positions[j] == 0) {
            moves.add(new int[]{i, j});
          }
        }
      }
    }
    return moves;
  }

  boolean hasValidMoves(int player, int phase) {
    if (phase == NMM_PHASE_PLACE) {
      for (int i = 0; i < 24; i++) {
        if (positions[i] == 0) return true;
      }
      return false;
    } else if (phase == NMM_PHASE_MOVE) {
      for (int i = 0; i < 24; i++) {
        if (positions[i] != player) continue;
        for (int n : adjacency[i]) {
          if (positions[n] == 0) return true;
        }
      }
      return false;
    } else {
      for (int i = 0; i < 24; i++) {
        if (positions[i] == player) {
          for (int j = 0; j < 24; j++) {
            if (positions[j] == 0) return true;
          }
        }
      }
      return false;
    }
  }

  NMMBoard copy() {
    NMMBoard b = new NMMBoard();
    b.positions = new int[24];
    arrayCopy(positions, b.positions);
    b.piecesInHand = new int[3];
    arrayCopy(piecesInHand, b.piecesInHand);
    b.piecesOnBoard = new int[3];
    arrayCopy(piecesOnBoard, b.piecesOnBoard);
    return b;
  }

  void placePiece(int pos, int player) {
    positions[pos] = player;
    piecesInHand[player]--;
    piecesOnBoard[player]++;
  }

  void movePiece(int fromPos, int toPos, int player) {
    positions[fromPos] = 0;
    positions[toPos] = player;
  }

  void removePiece(int pos) {
    int player = positions[pos];
    positions[pos] = 0;
    piecesOnBoard[player]--;
  }

  int getPhase(int player) {
    if (piecesInHand[player] > 0) return NMM_PHASE_PLACE;
    if (piecesOnBoard[player] <= 3) return NMM_PHASE_FLY;
    return NMM_PHASE_MOVE;
  }
}
