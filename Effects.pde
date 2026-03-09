class Particle {
  float x, y, vx, vy;
  float life, maxLife;
  color c;
  float sz;

  Particle(float x, float y, color c) {
    this.x = x;
    this.y = y;
    this.vx = random(-3, 3);
    this.vy = random(-5, -1);
    this.life = random(40, 80);
    this.maxLife = this.life;
    this.c = c;
    this.sz = random(3, 7);
  }

  void update() {
    x += vx;
    y += vy;
    vy += 0.08;
    life--;
  }

  void draw() {
    float alpha = map(life, 0, maxLife, 0, 255);
    noStroke();
    fill(c, alpha);
    ellipse(x, y, sz, sz);
  }

  boolean isDead() {
    return life <= 0;
  }
}

void updateParticles(ArrayList<Particle> particles) {
  for (int i = particles.size() - 1; i >= 0; i--) {
    particles.get(i).update();
    if (particles.get(i).isDead()) {
      particles.remove(i);
    }
  }
}

void drawParticles(ArrayList<Particle> particles) {
  for (Particle p : particles) {
    p.draw();
  }
}
