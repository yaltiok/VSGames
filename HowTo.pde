// Shared How-To page rendering helpers

final float HOWTO_NAV_Y = 660;
final float HOWTO_CONTENT_TOP = 75;
final float HOWTO_CONTENT_BOTTOM = 630;

void drawHowToFrame(String title, int page, int totalPages, color accentColor) {
  background(30, 30, 40);

  // Title bar
  noStroke();
  fill(accentColor, 40);
  rect(0, 0, CANVAS_W, 60);
  textAlign(CENTER, CENTER);
  textSize(22);
  fill(255);
  text(title, CANVAS_W / 2, 28);

  // Page dots
  float dotsX = CANVAS_W / 2 - (totalPages - 1) * 10;
  for (int i = 0; i < totalPages; i++) {
    noStroke();
    fill(i == page ? color(255) : color(80));
    ellipse(dotsX + i * 20, HOWTO_NAV_Y - 25, 8, 8);
  }

  // Nav buttons
  if (page > 0) {
    drawHowToBtn(80, HOWTO_NAV_Y, "\u2190 Prev", color(100));
  }
  if (page < totalPages - 1) {
    drawHowToBtn(CANVAS_W - 80, HOWTO_NAV_Y, "Next \u2192", accentColor);
  }
  drawHowToBtn(CANVAS_W / 2, HOWTO_NAV_Y, "Close", color(100, 80, 80));
}

void drawHowToBtn(float x, float y, String label, color c) {
  float bw = 110, bh = 36;
  boolean hover = mouseX > x - bw / 2 && mouseX < x + bw / 2 &&
                  mouseY > y - bh / 2 && mouseY < y + bh / 2;
  noStroke();
  fill(c, hover ? 200 : 120);
  rect(x - bw / 2, y - bh / 2, bw, bh, 6);
  textAlign(CENTER, CENTER);
  textSize(15);
  fill(255);
  text(label, x, y);
}

// Returns new page, or -1 if "Close" clicked
int handleHowToNav(int page, int totalPages) {
  float bw = 110, bh = 36;
  // Prev
  if (page > 0) {
    float x = 80;
    if (mouseX > x - bw/2 && mouseX < x + bw/2 && mouseY > HOWTO_NAV_Y - bh/2 && mouseY < HOWTO_NAV_Y + bh/2) {
      return page - 1;
    }
  }
  // Next
  if (page < totalPages - 1) {
    float x = CANVAS_W - 80;
    if (mouseX > x - bw/2 && mouseX < x + bw/2 && mouseY > HOWTO_NAV_Y - bh/2 && mouseY < HOWTO_NAV_Y + bh/2) {
      return page + 1;
    }
  }
  // Close
  float x = CANVAS_W / 2;
  if (mouseX > x - bw/2 && mouseX < x + bw/2 && mouseY > HOWTO_NAV_Y - bh/2 && mouseY < HOWTO_NAV_Y + bh/2) {
    return -1;
  }
  return page;
}

void drawHowToSubtitle(String txt, float y) {
  textAlign(CENTER, CENTER);
  textSize(18);
  fill(241, 196, 15);
  text(txt, CANVAS_W / 2, y);
}

void drawHowToText(String txt, float y) {
  textAlign(CENTER, CENTER);
  textSize(14);
  fill(210);
  text(txt, CANVAS_W / 2, y);
}

void drawHowToBullet(String txt, float x, float y) {
  textAlign(LEFT, CENTER);
  textSize(14);
  fill(200);
  text("\u2022  " + txt, x, y);
}

void drawHowToLines(String[] lines, float x, float startY, float lineH) {
  textAlign(LEFT, CENTER);
  textSize(14);
  fill(200);
  for (int i = 0; i < lines.length; i++) {
    text(lines[i], x, startY + i * lineH);
  }
}
