class QRTBoard {
  int[][] grid;
  boolean[] available;
  int selectedPiece;
  int lastPlacedBy;

  QRTBoard() {
    grid = new int[4][4];
    for (int r = 0; r < 4; r++)
      for (int c = 0; c < 4; c++)
        grid[r][c] = -1;
    available = new boolean[16];
    for (int i = 0; i < 16; i++) available[i] = true;
    selectedPiece = -1;
    lastPlacedBy = 0;
  }

  boolean placePiece(int row, int col, int player) {
    if (row < 0 || row >= 4 || col < 0 || col >= 4) return false;
    if (grid[row][col] != -1) return false;
    if (selectedPiece < 0) return false;
    grid[row][col] = selectedPiece;
    available[selectedPiece] = false;
    selectedPiece = -1;
    lastPlacedBy = player;
    return true;
  }

  void choosePiece(int pieceId) {
    if (pieceId < 0 || pieceId >= 16) return;
    if (!available[pieceId]) return;
    selectedPiece = pieceId;
  }

  boolean hasCommonAttribute(int p0, int p1, int p2, int p3) {
    for (int bit = 0; bit < 4; bit++) {
      int mask = 1 << bit;
      if (((p0 & mask) == (p1 & mask)) &&
          ((p1 & mask) == (p2 & mask)) &&
          ((p2 & mask) == (p3 & mask))) {
        return true;
      }
    }
    return false;
  }

  int checkWin() {
    // Rows
    for (int r = 0; r < 4; r++) {
      if (grid[r][0] != -1 && grid[r][1] != -1 && grid[r][2] != -1 && grid[r][3] != -1) {
        if (hasCommonAttribute(grid[r][0], grid[r][1], grid[r][2], grid[r][3]))
          return lastPlacedBy;
      }
    }
    // Columns
    for (int c = 0; c < 4; c++) {
      if (grid[0][c] != -1 && grid[1][c] != -1 && grid[2][c] != -1 && grid[3][c] != -1) {
        if (hasCommonAttribute(grid[0][c], grid[1][c], grid[2][c], grid[3][c]))
          return lastPlacedBy;
      }
    }
    // Diagonal top-left to bottom-right
    if (grid[0][0] != -1 && grid[1][1] != -1 && grid[2][2] != -1 && grid[3][3] != -1) {
      if (hasCommonAttribute(grid[0][0], grid[1][1], grid[2][2], grid[3][3]))
        return lastPlacedBy;
    }
    // Diagonal top-right to bottom-left
    if (grid[0][3] != -1 && grid[1][2] != -1 && grid[2][1] != -1 && grid[3][0] != -1) {
      if (hasCommonAttribute(grid[0][3], grid[1][2], grid[2][1], grid[3][0]))
        return lastPlacedBy;
    }
    return 0;
  }

  boolean isFull() {
    for (int r = 0; r < 4; r++)
      for (int c = 0; c < 4; c++)
        if (grid[r][c] == -1) return false;
    return true;
  }

  ArrayList<int[]> getEmptyCells() {
    ArrayList<int[]> cells = new ArrayList<int[]>();
    for (int r = 0; r < 4; r++)
      for (int c = 0; c < 4; c++)
        if (grid[r][c] == -1) cells.add(new int[]{r, c});
    return cells;
  }

  ArrayList<Integer> getAvailablePieces() {
    ArrayList<Integer> pieces = new ArrayList<Integer>();
    for (int i = 0; i < 16; i++)
      if (available[i]) pieces.add(i);
    return pieces;
  }

  QRTBoard copy() {
    QRTBoard b = new QRTBoard();
    for (int r = 0; r < 4; r++)
      for (int c = 0; c < 4; c++)
        b.grid[r][c] = grid[r][c];
    for (int i = 0; i < 16; i++)
      b.available[i] = available[i];
    b.selectedPiece = selectedPiece;
    b.lastPlacedBy = lastPlacedBy;
    return b;
  }
}
