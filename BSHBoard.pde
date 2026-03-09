class BSHShip {
  String name;
  int length;
  int row, col;
  boolean horizontal;
  boolean placed;
  int hits;

  BSHShip(String name, int length) {
    this.name = name;
    this.length = length;
  }

  boolean isSunk() {
    return hits >= length;
  }
}

class BSHBoard {
  int[][] ownGrid;
  int[][] attackGrid;
  BSHShip[] ships;

  BSHBoard() {
    ownGrid = new int[10][10];
    attackGrid = new int[10][10];
    ships = new BSHShip[5];
    ships[0] = new BSHShip("Carrier", 5);
    ships[1] = new BSHShip("Battleship", 4);
    ships[2] = new BSHShip("Cruiser", 3);
    ships[3] = new BSHShip("Submarine", 3);
    ships[4] = new BSHShip("Destroyer", 2);
  }

  boolean canPlaceShip(int shipIdx, int row, int col, boolean horizontal) {
    int len = ships[shipIdx].length;
    if (horizontal) {
      if (col + len > 10) return false;
      for (int c = col; c < col + len; c++) {
        if (ownGrid[row][c] != 0) return false;
      }
    } else {
      if (row + len > 10) return false;
      for (int r = row; r < row + len; r++) {
        if (ownGrid[r][col] != 0) return false;
      }
    }
    return true;
  }

  void placeShip(int shipIdx, int row, int col, boolean horizontal) {
    BSHShip ship = ships[shipIdx];
    ship.row = row;
    ship.col = col;
    ship.horizontal = horizontal;
    ship.placed = true;
    int id = shipIdx + 1;
    if (horizontal) {
      for (int c = col; c < col + ship.length; c++) {
        ownGrid[row][c] = id;
      }
    } else {
      for (int r = row; r < row + ship.length; r++) {
        ownGrid[r][col] = id;
      }
    }
  }

  // Attack this board at (row, col). Returns 0=miss, 1=hit, 2=sunk
  int attack(int row, int col) {
    int cell = ownGrid[row][col];
    if (cell == 0) {
      return 0;
    }
    int shipIdx = cell - 1;
    ships[shipIdx].hits++;
    if (ships[shipIdx].isSunk()) {
      return 2;
    }
    return 1;
  }

  // Mark result on attacker's attack grid
  void markAttack(int row, int col, int result, String sunkShipName) {
    if (result == 0) {
      attackGrid[row][col] = 1; // miss
    } else if (result == 1) {
      attackGrid[row][col] = 2; // hit
    } else if (result == 2) {
      attackGrid[row][col] = 2; // hit first
      markSunkShip(row, col, sunkShipName);
    }
  }

  // After sinking, mark all cells of that ship as sunk (3)
  void markSunkShip(int row, int col, String sunkShipName) {
    // Find all hit cells that could be this ship by flood-filling from the sunk position
    // Simple approach: mark all connected hit cells from this position as sunk
    boolean[][] visited = new boolean[10][10];
    ArrayList<int[]> queue = new ArrayList<int[]>();
    queue.add(new int[]{row, col});
    visited[row][col] = true;
    ArrayList<int[]> shipCells = new ArrayList<int[]>();
    shipCells.add(new int[]{row, col});

    while (queue.size() > 0) {
      int[] pos = queue.remove(0);
      int[][] dirs = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}};
      for (int[] d : dirs) {
        int nr = pos[0] + d[0];
        int nc = pos[1] + d[1];
        if (nr >= 0 && nr < 10 && nc >= 0 && nc < 10 && !visited[nr][nc]) {
          visited[nr][nc] = true;
          if (attackGrid[nr][nc] == 2) {
            queue.add(new int[]{nr, nc});
            shipCells.add(new int[]{nr, nc});
          }
        }
      }
    }

    for (int[] c : shipCells) {
      attackGrid[c[0]][c[1]] = 3;
    }
  }

  boolean allSunk() {
    for (int i = 0; i < 5; i++) {
      if (!ships[i].isSunk()) return false;
    }
    return true;
  }

  String getSunkShipName(int row, int col) {
    int cell = ownGrid[row][col];
    if (cell == 0) return "";
    return ships[cell - 1].name;
  }

  int getShipAt(int row, int col) {
    int cell = ownGrid[row][col];
    if (cell == 0) return -1;
    return cell - 1;
  }

  void placeShipsRandom() {
    for (int i = 0; i < 5; i++) {
      boolean placed = false;
      while (!placed) {
        int row = (int) random(10);
        int col = (int) random(10);
        boolean horiz = random(1) > 0.5;
        if (canPlaceShip(i, row, col, horiz)) {
          placeShip(i, row, col, horiz);
          placed = true;
        }
      }
    }
  }
}
