#include <WiFi.h>

// ==========================================
// WIFI
// ==========================================

const char* ssid = "Hwjunction";
const char* password = "forged@forge";

WiFiServer server(80);

// ==========================================
// LED PINS
// ==========================================

const int redLED = 26;
const int yellowLED = 27;
const int greenLED = 33;

// ==========================================
// GAME SETTINGS
// ==========================================

const int TOTAL_ROUNDS = 5;
const int MAX_LIVES = 3;

const unsigned long RED_MIN_TIME = 2000;
const unsigned long RED_MAX_TIME = 5000;

const unsigned long YELLOW_TIME = 1000;
const unsigned long GREEN_TIME = 5000;

// ==========================================
// GAME STATES
// ==========================================

enum GameState {
  READY,
  RED_STATE,
  YELLOW_STATE,
  GREEN_STATE,
  FINISHED
};

GameState gameState = READY;

// ==========================================
// GAME VARIABLES
// ==========================================

int currentRound = 0;
int score = 0;
int lives = MAX_LIVES;
int streak = 0;

int lastReaction = 0;
int bestReaction = 99999;

unsigned long stateStartTime = 0;
unsigned long greenStartTime = 0;
unsigned long randomRedTime = 0;

// ==========================================
// LED FUNCTIONS
// ==========================================

void redLight() {
  digitalWrite(redLED, HIGH);
  digitalWrite(yellowLED, LOW);
  digitalWrite(greenLED, LOW);
}

void yellowLight() {
  digitalWrite(redLED, LOW);
  digitalWrite(yellowLED, HIGH);
  digitalWrite(greenLED, LOW);
}

void greenLight() {
  digitalWrite(redLED, LOW);
  digitalWrite(yellowLED, LOW);
  digitalWrite(greenLED, HIGH);
}

void allOff() {
  digitalWrite(redLED, LOW);
  digitalWrite(yellowLED, LOW);
  digitalWrite(greenLED, LOW);
}

// ==========================================
// START GAME
// ==========================================

void startGame() {

  currentRound = 1;
  score = 0;
  lives = MAX_LIVES;
  streak = 0;

  lastReaction = 0;
  bestReaction = 99999;

  gameState = RED_STATE;

  redLight();

  stateStartTime = millis();

  randomRedTime = random(
    RED_MIN_TIME,
    RED_MAX_TIME + 1
  );

  Serial.println();
  Serial.println("==============================");
  Serial.println("TRAFFIC REACTION CHALLENGE");
  Serial.println("==============================");

  Serial.print("ROUND ");
  Serial.println(currentRound);

  Serial.println("RED - WAIT");
}

// ==========================================
// START NEXT ROUND
// ==========================================

void startNextRound() {

  if (currentRound >= TOTAL_ROUNDS) {

    gameState = FINISHED;

    redLight();

    Serial.println();
    Serial.println("==============================");
    Serial.println("GAME FINISHED");
    Serial.print("FINAL SCORE: ");
    Serial.println(score);
    Serial.println("==============================");

    return;
  }

  currentRound++;

  gameState = RED_STATE;

  redLight();

  stateStartTime = millis();

  randomRedTime = random(
    RED_MIN_TIME,
    RED_MAX_TIME + 1
  );

  Serial.println();
  Serial.print("ROUND ");
  Serial.println(currentRound);

  Serial.println("RED - WAIT");
}

// ==========================================
// GAME ENGINE
// ==========================================

void updateGame() {

  unsigned long now = millis();

  // -------------------------------
  // RED
  // -------------------------------

  if (gameState == RED_STATE) {

    if (now - stateStartTime >= randomRedTime) {

      yellowLight();

      gameState = YELLOW_STATE;

      stateStartTime = now;

      Serial.println("YELLOW - GET READY");
    }
  }

  // -------------------------------
  // YELLOW
  // -------------------------------

  else if (gameState == YELLOW_STATE) {

    if (now - stateStartTime >= YELLOW_TIME) {

      greenLight();

      gameState = GREEN_STATE;

      greenStartTime = now;

      Serial.println("GREEN - CLICK GO!");
    }
  }

  // -------------------------------
  // GREEN
  // -------------------------------

  else if (gameState == GREEN_STATE) {

    if (now - greenStartTime >= GREEN_TIME) {

      Serial.println("TIME OUT!");

      lives--;

      streak = 0;

      Serial.print("Lives remaining: ");
      Serial.println(lives);

      if (lives <= 0) {

        gameState = FINISHED;

        redLight();

        Serial.println("GAME OVER!");

      } else {

        startNextRound();
      }
    }
  }
}

// ==========================================
// PLAYER CLICK
// ==========================================

void playerClicked() {

  // Ignore click if game isn't running
  if (gameState == READY || gameState == FINISHED) {
    return;
  }

  // ======================================
  // CORRECT CLICK
  // ======================================

  if (gameState == GREEN_STATE) {

    lastReaction = millis() - greenStartTime;

    streak++;

    if (lastReaction < bestReaction) {
      bestReaction = lastReaction;
    }

    int points = 0;

    if (lastReaction <= 300) {
      points = 200;
    }
    else if (lastReaction <= 600) {
      points = 150;
    }
    else if (lastReaction <= 1000) {
      points = 100;
    }
    else if (lastReaction <= 1500) {
      points = 75;
    }
    else {
      points = 50;
    }

    // Streak bonus
    if (streak == 2) {
      points += 25;
    }

    if (streak >= 3) {
      points += 50;
    }

    score += points;

    Serial.println();
    Serial.println("CORRECT!");

    Serial.print("Reaction: ");
    Serial.print(lastReaction);
    Serial.println(" ms");

    Serial.print("Points: ");
    Serial.println(points);

    Serial.print("Score: ");
    Serial.println(score);

    Serial.print("Streak: ");
    Serial.println(streak);

    // Move to next round
    startNextRound();
  }

  // ======================================
  // FALSE START
  // ======================================

  else {

    lives--;

    streak = 0;

    Serial.println();
    Serial.println("FALSE START!");
    Serial.println("You clicked before GREEN.");

    Serial.print("Lives remaining: ");
    Serial.println(lives);

    if (lives <= 0) {

      gameState = FINISHED;

      redLight();

      Serial.println("GAME OVER!");

    } else {

      // Restart SAME round
      gameState = RED_STATE;

      redLight();

      stateStartTime = millis();

      randomRedTime = random(
        RED_MIN_TIME,
        RED_MAX_TIME + 1
      );

      Serial.println("Round restarted.");
      Serial.println("RED - WAIT");
    }
  }
}

// ==========================================
// GET GAME STATE TEXT
// ==========================================

String getGameState() {

  if (gameState == READY) {
    return "READY";
  }

  if (gameState == RED_STATE) {
    return "WAIT";
  }

  if (gameState == YELLOW_STATE) {
    return "GET READY";
  }

  if (gameState == GREEN_STATE) {
    return "CLICK GO!";
  }

  if (gameState == FINISHED) {
    return "GAME OVER";
  }

  return "";
}

// ==========================================
// SEND WEBPAGE
// ==========================================

void sendWebPage(WiFiClient &client) {

  client.println("HTTP/1.1 200 OK");
  client.println("Content-Type: text/html");
  client.println("Connection: close");
  client.println();

  client.println("<!DOCTYPE html>");
  client.println("<html>");
  client.println("<head>");

  client.println("<meta name='viewport' content='width=device-width, initial-scale=1'>");

  client.println("<title>Traffic Reaction Challenge</title>");

  client.println("<style>");

  client.println("* { box-sizing:border-box; }");

  client.println("body {");
  client.println("margin:0;");
  client.println("font-family:Arial,sans-serif;");
  client.println("background:#111827;");
  client.println("color:white;");
  client.println("text-align:center;");
  client.println("}");

  client.println(".container {");
  client.println("max-width:500px;");
  client.println("margin:auto;");
  client.println("padding:25px;");
  client.println("}");

  client.println("h1 {");
  client.println("font-size:30px;");
  client.println("margin-bottom:5px;");
  client.println("}");

  client.println(".subtitle {");
  client.println("color:#9ca3af;");
  client.println("margin-bottom:20px;");
  client.println("}");

  // Traffic light
  client.println(".traffic {");
  client.println("background:#050505;");
  client.println("width:150px;");
  client.println("padding:18px;");
  client.println("border-radius:30px;");
  client.println("margin:20px auto;");
  client.println("}");

  client.println(".light {");
  client.println("width:75px;");
  client.println("height:75px;");
  client.println("border-radius:50%;");
  client.println("margin:14px auto;");
  client.println("opacity:.15;");
  client.println("}");

  client.println(".red { background:#ef4444; }");
  client.println(".yellow { background:#facc15; }");
  client.println(".green { background:#22c55e; }");

  client.println(".active {");
  client.println("opacity:1;");
  client.println("}");

  // Panel
  client.println(".panel {");
  client.println("background:#1f2937;");
  client.println("padding:20px;");
  client.println("border-radius:18px;");
  client.println("}");

  client.println(".status {");
  client.println("font-size:25px;");
  client.println("font-weight:bold;");
  client.println("margin:15px;");
  client.println("}");

  // Stats
  client.println(".stats {");
  client.println("display:grid;");
  client.println("grid-template-columns:1fr 1fr;");
  client.println("gap:10px;");
  client.println("}");

  client.println(".stat {");
  client.println("background:#374151;");
  client.println("padding:15px;");
  client.println("border-radius:12px;");
  client.println("}");

  client.println(".label {");
  client.println("font-size:13px;");
  client.println("color:#9ca3af;");
  client.println("}");

  client.println(".value {");
  client.println("font-size:25px;");
  client.println("font-weight:bold;");
  client.println("margin-top:5px;");
  client.println("}");

  // Buttons
  client.println("button {");
  client.println("width:100%;");
  client.println("padding:18px;");
  client.println("margin-top:15px;");
  client.println("border:none;");
  client.println("border-radius:12px;");
  client.println("font-size:20px;");
  client.println("font-weight:bold;");
  client.println("cursor:pointer;");
  client.println("}");

  client.println(".start {");
  client.println("background:#2563eb;");
  client.println("color:white;");
  client.println("}");

  client.println(".go {");
  client.println("background:#16a34a;");
  client.println("color:white;");
  client.println("}");

  client.println(".restart {");
  client.println("background:#6b7280;");
  client.println("color:white;");
  client.println("}");

  client.println("</style>");

  client.println("</head>");
  client.println("<body>");

  client.println("<div class='container'>");

  client.println("<h1>Traffic Reaction Challenge</h1>");

  client.println("<div class='subtitle'>Wait for green and react quickly.</div>");

  // ======================================
  // TRAFFIC LIGHT DISPLAY
  // ======================================

  client.println("<div class='traffic'>");

  if (gameState == RED_STATE) {
    client.println("<div class='light red active'></div>");
  } else {
    client.println("<div class='light red'></div>");
  }

  if (gameState == YELLOW_STATE) {
    client.println("<div class='light yellow active'></div>");
  } else {
    client.println("<div class='light yellow'></div>");
  }

  if (gameState == GREEN_STATE) {
    client.println("<div class='light green active'></div>");
  } else {
    client.println("<div class='light green'></div>");
  }

  client.println("</div>");

  // ======================================
  // PANEL
  // ======================================

  client.println("<div class='panel'>");

  client.print("<div class='status'>");
  client.print(getGameState());
  client.println("</div>");

  // ======================================
  // STATS
  // ======================================

  client.println("<div class='stats'>");

  // Round
  client.println("<div class='stat'>");
  client.println("<div class='label'>ROUND</div>");
  client.println("<div class='value'>");

  client.print(currentRound);
  client.print(" / ");
  client.print(TOTAL_ROUNDS);

  client.println("</div>");
  client.println("</div>");

  // Score
  client.println("<div class='stat'>");
  client.println("<div class='label'>SCORE</div>");
  client.println("<div class='value'>");

  client.print(score);

  client.println("</div>");
  client.println("</div>");

  // Lives
  client.println("<div class='stat'>");
  client.println("<div class='label'>LIVES</div>");
  client.println("<div class='value'>");

  client.print(lives);

  client.println("</div>");
  client.println("</div>");

  // Streak
  client.println("<div class='stat'>");
  client.println("<div class='label'>STREAK</div>");
  client.println("<div class='value'>");

  client.print(streak);

  client.println("</div>");
  client.println("</div>");

  client.println("</div>");

  // ======================================
  // REACTION
  // ======================================

  if (lastReaction > 0) {

    client.println("<p>");

    client.print("Last reaction: ");
    client.print(lastReaction);
    client.println(" ms");

    client.println("</p>");
  }

  if (bestReaction != 99999) {

    client.println("<p>");

    client.print("Best reaction: ");
    client.print(bestReaction);
    client.println(" ms");

    client.println("</p>");
  }

  // ======================================
  // BUTTON
  // ======================================

  if (gameState == READY) {

    client.println("<a href='/start'>");
    client.println("<button class='start'>START GAME</button>");
    client.println("</a>");

  }

  else if (gameState == FINISHED) {

    client.println("<a href='/start'>");
    client.println("<button class='restart'>PLAY AGAIN</button>");
    client.println("</a>");

  }

  else {

    client.println("<a href='/click'>");
    client.println("<button class='go'>GO</button>");
    client.println("</a>");
  }

  client.println("</div>");

  client.println("</div>");

  client.println("</body>");
  client.println("</html>");

  client.println();
}

// ==========================================
// SETUP
// ==========================================

void setup() {

  Serial.begin(115200);

  // LED pins
  pinMode(redLED, OUTPUT);
  pinMode(yellowLED, OUTPUT);
  pinMode(greenLED, OUTPUT);

  // Turn LEDs OFF
  allOff();

  // Random seed
  randomSeed(analogRead(34));

  // ======================================
  // WIFI
  // ======================================

  Serial.println();
  Serial.println("Connecting to WiFi...");

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {

    delay(500);

    Serial.print(".");
  }

  Serial.println();

  Serial.println("WiFi Connected!");

  Serial.print("ESP32 IP Address: ");
  Serial.println(WiFi.localIP());

  server.begin();

  Serial.println("Web server started.");
  Serial.println("Open the IP address in your browser.");
}

// ==========================================
// LOOP
// ==========================================

void loop() {

  // ALWAYS update traffic light
  updateGame();

  // Check browser
  WiFiClient client = server.available();

  if (client) {

    String request = "";

    unsigned long timeout = millis();

    while (client.connected() &&
           millis() - timeout < 1000) {

      if (client.available()) {

        char c = client.read();

        request += c;

        // End of HTTP request
        if (c == '\n') {

          // START GAME
          if (request.indexOf("GET /start") >= 0) {

            startGame();
          }

          // GO BUTTON
          else if (request.indexOf("GET /click") >= 0) {

            playerClicked();
          }

          // Send webpage
          sendWebPage(client);

          break;
        }
      }
    }

    client.stop();
  }
}
