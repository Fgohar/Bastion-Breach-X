// GLOBAL VARS

int gameState = 0; // 0: Splash, 1: Play, 2: GameOver
int score = 0;
int lives = 3;
int level = 1;
int health = 100;
int spawnTimer = 0;

ArrayList<Enemy> enemies;
ArrayList<HealthKit> crates;
Base myBase;

// 2. CORE ENGINE

void setup() {
  size(800, 600);
  resetGame();
}

void resetGame() {
  health = 100;
  lives = 3;
  score = 0;
  level = 1;
  enemies = new ArrayList<Enemy>();
  crates = new ArrayList<HealthKit>();
  myBase = new Base(width/2, height/2);
}

void draw() {
  if (gameState == 0) {
    displaySplash();
  } else if (gameState == 1) {
    playMission();
  } else if (gameState == 2) {
    displayGameOver();
  }
}


// 3. GAME STATES

void playMission() {
  background(85, 95, 70); 
  drawGrid();
  myBase.display();
  
  level = 1 + (score / 1000); // Level up every 1000 points
  
  // HUD
  fill(255);
  textAlign(LEFT);
  textSize(16);
  text("BASE INTEGRITY: " + health + "%", 20, 30);
  text("SQUAD LIVES: " + lives, 20, 50);
  text("INTEL SCORE: " + score, width - 150, 30);
  text("THREAT LEVEL: " + level, width - 150, 50);

  // Spawning Enemies
  int spawnRate = max(400, 1500 - (level * 100));
  if (millis() - spawnTimer > spawnRate) {
    spawnUnit();
    spawnTimer = millis();
  }
  
  // Spawning Health Kits every 10 seconds (approx 600 frames)
  if (frameCount % 600 == 0) {
    crates.add(new HealthKit(random(100, width-100), random(100, height-100)));
  }

  // Handle Health Kits
  for (int i = crates.size() - 1; i >= 0; i--) {
    HealthKit h = crates.get(i);
    h.display();
    if (h.isExpired()) crates.remove(i);
  }

  // Handle Enemies
  for (int i = enemies.size() - 1; i >= 0; i--) {
    Enemy e = enemies.get(i);
    e.update(level); 
    e.display();

    if (myBase.checkCollision(e)) {
      if (e instanceof Tank) health -= 15; 
      else if (e instanceof Mine) health -= 30;
      enemies.remove(i);
    }
  }

  // Health/Life Management
  if (health <= 0) {
    lives--;
    health = 100;
    if (lives <= 0) gameState = 2;
  }
}

void displaySplash() {
  background(30, 40, 30);
  textAlign(CENTER, CENTER);
  fill(150, 255, 150);
  textSize(40);
  text("TACTICAL DEFENSE ALPHA", width/2, height/2 - 50);
  textSize(18);
  fill(255);
  text("CLICK TANKS [+100] | AVOID MINES [-1 LIFE]\nCOLLECT MEDKITS [+25% HP]\n\n[ CLICK TO COMMENCE ]", width/2, height/2 + 30);
}

void displayGameOver() {
  background(20, 0, 0);
  textAlign(CENTER, CENTER);
  fill(255, 0, 0);
  textSize(50);
  text("MISSION FAILURE", width/2, height/2 - 20);
  fill(255);
  textSize(20);
  text("FINAL SCORE: " + score, width/2, height/2 + 30);
  text("CLICK TO RE-ENGAGE", width/2, height/2 + 80);
}


// 4. INPUT & HELPERS


void mousePressed() {
  if (gameState == 0) {
    gameState = 1;
  } else if (gameState == 2) {
    resetGame();
    gameState = 1;
  } else if (gameState == 1) {
    // 1. Check Health Kits first
    for (int i = crates.size() - 1; i >= 0; i--) {
      if (crates.get(i).checkMouseHit(mouseX, mouseY)) {
        health = min(100, health + 25);
        crates.remove(i);
        return; 
      }
    }
    
    // 2. Check Enemies
    for (int i = enemies.size() - 1; i >= 0; i--) {
      Enemy e = enemies.get(i);
      if (e.checkMouseHit(mouseX, mouseY)) {
        if (e instanceof Mine) {
          lives--; 
          enemies.remove(i);
          if (lives <= 0) gameState = 2;
        } else {
          enemies.remove(i);
          score += 100;
        }
        return; 
      }
    }
  }
}

void spawnUnit() {
  float x = random(1) > 0.5 ? -30 : width + 30;
  float y = random(height);
  if (random(1) > 0.3) enemies.add(new Tank(x, y));
  else enemies.add(new Mine(x, y));
}

void drawGrid() {
  stroke(100, 110, 85);
  for(int i = 0; i < width; i+=50) line(i, 0, i, height);
  for(int j = 0; j < height; j+=50) line(0, j, width, j);
}


// 5. All my classes

class Enemy {
  float x, y, anim = 0, speed = 1.0;
  Enemy(float x, float y) { this.x = x; this.y = y; }
  void update(int lvl) {
    float angle = atan2(myBase.y - y, myBase.x - x);
    float currentSpeed = speed + (lvl * 0.2);
    x += cos(angle) * currentSpeed;
    y += sin(angle) * currentSpeed;
    anim += 0.1;
  }
  void display() {}
  boolean checkMouseHit(float mx, float my) { return dist(mx, my, x, y) < 30; }
}

class Tank extends Enemy {
  Tank(float x, float y) { super(x, y); speed = 1.0; }
  void display() {
    pushMatrix();
    translate(x, y);
    rotate(atan2(myBase.y-y, myBase.x-x));
    fill(60, 70, 40); rectMode(CENTER); rect(0, 0, 40, 30); 
    fill(45, 55, 30); ellipse(0, 0, 15, 15); rect(10, 0, 20, 4);
    popMatrix();
  }
}

class Mine extends Enemy {
  Mine(float x, float y) { super(x, y); speed = 0.6; }
  void display() {
    pushMatrix(); translate(x, y); rotate(anim * 0.5);
    fill(40); ellipse(0, 0, 25, 25);
    for(int i=0; i<8; i++) { rotate(PI/4); rect(15, 0, 10, 2); }
    fill(sin(anim*2) > 0 ? color(255, 0, 0) : color(50, 0, 0));
    ellipse(0, 0, 8, 8); popMatrix();
  }
}

class HealthKit {
  float x, y; int spawnTime; int lifetime = 5000;
  HealthKit(float x, float y) { this.x = x; this.y = y; this.spawnTime = millis(); }
  void display() {
    float b = sin(millis()*0.005)*5;
    fill(200, 255, 200); stroke(255); rect(x, y + b, 30, 30, 5);
    fill(255, 0, 0); noStroke(); rect(x, y + b, 20, 5); rect(x, y + b, 5, 20);
  }
  boolean checkMouseHit(float mx, float my) { return dist(mx, my, x, y) < 30; }
  boolean isExpired() { return millis() - spawnTime > lifetime; }
}

class Base {
  float x, y;
  Base(float x, float y) { this.x = x; this.y = y; }
  void display() {
    fill(120, 110, 90); stroke(0); rectMode(CENTER);
    rect(x, y, 60, 60); fill(80); rect(x, y, 30, 30);
  }
  boolean checkCollision(Enemy e) { return dist(x, y, e.x, e.y) < 40; }
}
