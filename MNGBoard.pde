class MNGBoard {
  int[] pits;
  int currentPlayer;

  MNGBoard() {
    pits = new int[14];
    for (int i = 0; i < 14; i++) {
      if (i == 6 || i == 13) {
        pits[i] = 0;
      } else {
        pits[i] = 4;
      }
    }
    currentPlayer = 1;
  }

  boolean sow(int pitIndex) {
    int stones = pits[pitIndex];
    if (stones == 0) return false;

    int skipStore = (currentPlayer == 1) ? 13 : 6;
    int ownStore = (currentPlayer == 1) ? 6 : 13;

    // Single stone rule: move to next pit
    if (stones == 1) {
      pits[pitIndex] = 0;
      int idx = (pitIndex + 1) % 14;
      if (idx == skipStore) idx = (idx + 1) % 14;
      pits[idx]++;
      if (idx == ownStore) return true;
      // Even capture on opponent's side
      if (!isOwnSide(idx, currentPlayer) && idx != skipStore && pits[idx] % 2 == 0) {
        pits[ownStore] += pits[idx];
        pits[idx] = 0;
      }
      // Capture on own empty pit
      if (pits[idx] == 1 && isOwnSide(idx, currentPlayer)) {
        int opposite = getOppositePit(idx);
        if (pits[opposite] > 0) {
          pits[ownStore] += pits[opposite] + pits[idx];
          pits[opposite] = 0;
          pits[idx] = 0;
        }
      }
      return false;
    }

    // Turkish Mangala sowing: one stone stays in the pit, rest are distributed
    pits[pitIndex] = 1; // one stone stays
    int remaining = stones - 1;

    int idx = pitIndex;
    for (int i = 0; i < remaining; i++) {
      idx = (idx + 1) % 14;
      if (idx == skipStore) {
        idx = (idx + 1) % 14;
      }
      pits[idx]++;
    }

    // Last stone in own store → extra turn
    if (idx == ownStore) {
      return true;
    }

    // Even capture: last stone lands on opponent's side and makes it even → capture all
    if (!isOwnSide(idx, currentPlayer) && idx != skipStore && pits[idx] % 2 == 0) {
      pits[ownStore] += pits[idx];
      pits[idx] = 0;
    }

    // Capture: last stone in empty pit on own side, opposite has stones
    if (pits[idx] == 1 && isOwnSide(idx, currentPlayer)) {
      int opposite = getOppositePit(idx);
      if (pits[opposite] > 0) {
        pits[ownStore] += pits[opposite] + pits[idx];
        pits[opposite] = 0;
        pits[idx] = 0;
      }
    }

    return false;
  }

  boolean isOwnSide(int pitIndex, int player) {
    if (player == 1) return pitIndex >= 0 && pitIndex <= 5;
    return pitIndex >= 7 && pitIndex <= 12;
  }

  boolean isValidMove(int pitIndex, int player) {
    if (player == 1) {
      if (pitIndex < 0 || pitIndex > 5) return false;
    } else {
      if (pitIndex < 7 || pitIndex > 12) return false;
    }
    return pits[pitIndex] > 0;
  }

  boolean isGameOver() {
    boolean p1Empty = true;
    for (int i = 0; i < 6; i++) {
      if (pits[i] > 0) { p1Empty = false; break; }
    }
    boolean p2Empty = true;
    for (int i = 7; i < 13; i++) {
      if (pits[i] > 0) { p2Empty = false; break; }
    }
    return p1Empty || p2Empty;
  }

  void captureRemaining() {
    boolean p1Empty = true;
    for (int i = 0; i < 6; i++) {
      if (pits[i] > 0) { p1Empty = false; break; }
    }

    // Player who empties their side wins opponent's remaining stones
    int targetStore = p1Empty ? 6 : 13;
    for (int i = 0; i < 6; i++) {
      pits[targetStore] += pits[i];
      pits[i] = 0;
    }
    for (int i = 7; i < 13; i++) {
      pits[targetStore] += pits[i];
      pits[i] = 0;
    }
  }

  int getWinner() {
    if (!isGameOver()) return 0;
    captureRemaining();
    if (pits[6] > pits[13]) return 1;
    if (pits[13] > pits[6]) return 2;
    return 3;
  }

  MNGBoard copy() {
    MNGBoard b = new MNGBoard();
    for (int i = 0; i < 14; i++) {
      b.pits[i] = pits[i];
    }
    b.currentPlayer = currentPlayer;
    return b;
  }

  int getOppositePit(int pitIndex) {
    return 12 - pitIndex;
  }

  ArrayList<Integer> getValidMoves(int player) {
    ArrayList<Integer> moves = new ArrayList<Integer>();
    if (player == 1) {
      for (int i = 0; i < 6; i++) {
        if (pits[i] > 0) moves.add(i);
      }
    } else {
      for (int i = 7; i < 13; i++) {
        if (pits[i] > 0) moves.add(i);
      }
    }
    return moves;
  }
}
