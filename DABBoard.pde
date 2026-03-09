class DABBoard {
  boolean[][] hLines;
  boolean[][] vLines;
  int[][] boxes;
  int[] scores;
  int totalLinesPlaced;

  DABBoard() {
    hLines = new boolean[5][4];
    vLines = new boolean[4][5];
    boxes = new int[4][4];
    scores = new int[3];
    totalLinesPlaced = 0;
  }

  int placeLine(int type, int row, int col, int player) {
    if (type == 0) {
      if (hLines[row][col]) return 0;
      hLines[row][col] = true;
    } else {
      if (vLines[row][col]) return 0;
      vLines[row][col] = true;
    }
    totalLinesPlaced++;

    int completed = 0;

    if (type == 0) {
      // horizontal line at (row, col): top side of box (row, col), bottom side of box (row-1, col)
      if (row < 4 && countSides(row, col) == 4) {
        boxes[row][col] = player;
        scores[player]++;
        completed++;
      }
      if (row > 0 && countSides(row - 1, col) == 4) {
        boxes[row - 1][col] = player;
        scores[player]++;
        completed++;
      }
    } else {
      // vertical line at (row, col): left side of box (row, col), right side of box (row, col-1)
      if (col < 4 && countSides(row, col) == 4) {
        boxes[row][col] = player;
        scores[player]++;
        completed++;
      }
      if (col > 0 && countSides(row, col - 1) == 4) {
        boxes[row][col - 1] = player;
        scores[player]++;
        completed++;
      }
    }

    return completed;
  }

  boolean isLineSet(int type, int row, int col) {
    if (type == 0) return hLines[row][col];
    return vLines[row][col];
  }

  boolean isGameOver() {
    return totalLinesPlaced >= 40;
  }

  int getWinner() {
    if (scores[1] > scores[2]) return 1;
    if (scores[2] > scores[1]) return 2;
    return 3;
  }

  int countSides(int boxRow, int boxCol) {
    int count = 0;
    // top
    if (hLines[boxRow][boxCol]) count++;
    // bottom
    if (hLines[boxRow + 1][boxCol]) count++;
    // left
    if (vLines[boxRow][boxCol]) count++;
    // right
    if (vLines[boxRow][boxCol + 1]) count++;
    return count;
  }

  DABBoard copy() {
    DABBoard c = new DABBoard();
    for (int i = 0; i < 5; i++)
      for (int j = 0; j < 4; j++)
        c.hLines[i][j] = hLines[i][j];
    for (int i = 0; i < 4; i++)
      for (int j = 0; j < 5; j++)
        c.vLines[i][j] = vLines[i][j];
    for (int i = 0; i < 4; i++)
      for (int j = 0; j < 4; j++)
        c.boxes[i][j] = boxes[i][j];
    c.scores[1] = scores[1];
    c.scores[2] = scores[2];
    c.totalLinesPlaced = totalLinesPlaced;
    return c;
  }

  ArrayList<int[]> getAvailableLines() {
    ArrayList<int[]> lines = new ArrayList<int[]>();
    for (int i = 0; i < 5; i++)
      for (int j = 0; j < 4; j++)
        if (!hLines[i][j])
          lines.add(new int[]{0, i, j});
    for (int i = 0; i < 4; i++)
      for (int j = 0; j < 5; j++)
        if (!vLines[i][j])
          lines.add(new int[]{1, i, j});
    return lines;
  }
}
