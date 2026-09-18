#include <WiFi.h>
#include <WebServer.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <DHT.h>

// =====================================================
// WIFI
// =====================================================

const char* ssid = "Hwjunction";
const char* password = "forged@forge";

WebServer server(80);

// =====================================================
// OLED
// =====================================================

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64

#define OLED_SDA 21
#define OLED_SCL 22

Adafruit_SSD1306 display(
  SCREEN_WIDTH,
  SCREEN_HEIGHT,
  &Wire,
  -1
);

// =====================================================
// PINS
// =====================================================

#define JOY_X 34
#define JOY_Y 35
#define JOY_SW 32

#define PIR_PIN 25

#define DHT_PIN 4
#define DHT_TYPE DHT11

#define BUZZER_PIN 23

DHT dht(DHT_PIN, DHT_TYPE);

// =====================================================
// PET VARIABLES
// =====================================================

int happiness = 80;
int energy = 80;
int hunger = 20;
int visits = 0;

float temperature = 0;
float humidity = 0;

String mood = "HAPPY";
String currentAction = "READY";

// Dashboard-only temperature message
String temperatureMessage = "I'm feeling good!";

// =====================================================
// TIMERS
// =====================================================

unsigned long lastAction = 0;
unsigned long lastMotion = 0;
unsigned long lastDHTRead = 0;
unsigned long lastStatUpdate = 0;

// =====================================================
// LIMIT VALUES
// =====================================================

void limitValues() {

  happiness = constrain(happiness, 0, 100);
  energy = constrain(energy, 0, 100);
  hunger = constrain(hunger, 0, 100);
}

// =====================================================
// UPDATE MOOD
// =====================================================

void updateMood() {

  if (hunger >= 70) {
    mood = "HUNGRY";
  }
  else if (energy <= 25) {
    mood = "SLEEPY";
  }
  else if (happiness <= 30) {
    mood = "SAD";
  }
  else {
    mood = "HAPPY";
  }
}

// =====================================================
// UPDATE TEMPERATURE MESSAGE
// DASHBOARD ONLY
// =====================================================

void updateTemperatureMessage() {

  if (temperature < 20.0) {

    temperatureMessage = "I'm cold...";

  }
  else if (temperature > 30.0) {

    temperatureMessage = "I'm hot...";

  }
  else {

    temperatureMessage = "I'm feeling good!";

  }
}

// =====================================================
// BUZZER
// =====================================================

void beep(int frequency, int duration) {

  tone(
    BUZZER_PIN,
    frequency,
    duration
  );

  delay(duration);

  noTone(BUZZER_PIN);
}

// =====================================================
// DRAW CAT
// =====================================================

void drawCat(
  int x,
  int y,
  int frame = 0
) {

  // Head
  display.drawCircle(
    x,
    y,
    17,
    SSD1306_WHITE
  );

  // Left ear
  display.drawLine(
    x - 14,
    y - 10,
    x - 20,
    y - 25,
    SSD1306_WHITE
  );

  display.drawLine(
    x - 20,
    y - 25,
    x - 7,
    y - 17,
    SSD1306_WHITE
  );

  // Right ear
  display.drawLine(
    x + 14,
    y - 10,
    x + 20,
    y - 25,
    SSD1306_WHITE
  );

  display.drawLine(
    x + 20,
    y - 25,
    x + 7,
    y - 17,
    SSD1306_WHITE
  );

  // Eyes
  if (mood == "SLEEPY") {

    display.drawLine(
      x - 9,
      y - 2,
      x - 4,
      y - 2,
      SSD1306_WHITE
    );

    display.drawLine(
      x + 4,
      y - 2,
      x + 9,
      y - 2,
      SSD1306_WHITE
    );
  }

  else if (mood == "SAD") {

    display.drawLine(
      x - 9,
      y - 5,
      x - 4,
      y - 2,
      SSD1306_WHITE
    );

    display.drawLine(
      x + 4,
      y - 2,
      x + 9,
      y - 5,
      SSD1306_WHITE
    );
  }

  else {

    display.fillCircle(
      x - 7,
      y - 2,
      2,
      SSD1306_WHITE
    );

    display.fillCircle(
      x + 7,
      y - 2,
      2,
      SSD1306_WHITE
    );
  }

  // Nose
  display.fillTriangle(
    x - 2,
    y + 3,
    x + 2,
    y + 3,
    x,
    y + 6,
    SSD1306_WHITE
  );

  // Mouth
  display.drawLine(
    x,
    y + 6,
    x - 4,
    y + 10,
    SSD1306_WHITE
  );

  display.drawLine(
    x,
    y + 6,
    x + 4,
    y + 10,
    SSD1306_WHITE
  );

  // Whiskers
  display.drawLine(
    x - 15,
    y + 4,
    x - 28,
    y + 1,
    SSD1306_WHITE
  );

  display.drawLine(
    x - 15,
    y + 8,
    x - 28,
    y + 9,
    SSD1306_WHITE
  );

  display.drawLine(
    x + 15,
    y + 4,
    x + 28,
    y + 1,
    SSD1306_WHITE
  );

  display.drawLine(
    x + 15,
    y + 8,
    x + 28,
    y + 9,
    SSD1306_WHITE
  );

  // Body
  display.drawCircle(
    x,
    y + 25,
    14,
    SSD1306_WHITE
  );

  // Tail
  if (frame == 1) {

    display.drawCircle(
      x + 20,
      y + 25,
      8,
      SSD1306_WHITE
    );

  }
  else {

    display.drawLine(
      x + 12,
      y + 27,
      x + 25,
      y + 17,
      SSD1306_WHITE
    );
  }
}

// =====================================================
// OLED ACTION TEXT
// =====================================================

void drawActionText(String text) {

  display.setTextSize(1);

  int width =
    text.length() * 6;

  display.setCursor(
    (128 - width) / 2,
    55
  );

  display.println(text);
}

// =====================================================
// READY
// =====================================================

void showReady() {

  display.clearDisplay();

  drawCat(
    64,
    25
  );

  drawActionText("READY");

  display.display();
}

// =====================================================
// FEED
// =====================================================

void showFeed() {

  display.clearDisplay();

  drawCat(
    64,
    22,
    1
  );

  // Bowl
  display.drawLine(
    45,
    48,
    82,
    48,
    SSD1306_WHITE
  );

  display.drawLine(
    48,
    48,
    52,
    53,
    SSD1306_WHITE
  );

  display.drawLine(
    79,
    48,
    75,
    53,
    SSD1306_WHITE
  );

  // Food
  display.fillCircle(
    58,
    45,
    2,
    SSD1306_WHITE
  );

  display.fillCircle(
    65,
    44,
    2,
    SSD1306_WHITE
  );

  display.fillCircle(
    72,
    45,
    2,
    SSD1306_WHITE
  );

  drawActionText("EATING");

  display.display();

  beep(
    1200,
    100
  );

  delay(250);

  display.clearDisplay();

  drawCat(
    64,
    24
  );

  display.drawLine(
    48,
    50,
    80,
    50,
    SSD1306_WHITE
  );

  drawActionText("YUMMY");

  display.display();

  delay(500);
}

// =====================================================
// SLEEP
// =====================================================

void showSleep() {

  display.clearDisplay();

  // Sleeping cat
  display.drawCircle(
    50,
    37,
    13,
    SSD1306_WHITE
  );

  // Ears
  display.drawLine(
    40,
    28,
    37,
    18,
    SSD1306_WHITE
  );

  display.drawLine(
    37,
    18,
    46,
    25,
    SSD1306_WHITE
  );

  display.drawLine(
    60,
    28,
    64,
    18,
    SSD1306_WHITE
  );

  display.drawLine(
    64,
    18,
    56,
    25,
    SSD1306_WHITE
  );

  // Closed eyes
  display.drawLine(
    44,
    37,
    48,
    37,
    SSD1306_WHITE
  );

  display.drawLine(
    53,
    37,
    57,
    37,
    SSD1306_WHITE
  );

  // Body
  display.drawCircle(
    72,
    40,
    12,
    SSD1306_WHITE
  );

  // Z
  display.setTextSize(1);

  display.setCursor(
    85,
    18
  );

  display.print("Z");

  display.setCursor(
    96,
    10
  );

  display.print("Z");

  display.setCursor(
    108,
    2
  );

  display.print("Z");

  drawActionText(
    "SLEEPING"
  );

  display.display();

  beep(
    500,
    150
  );

  delay(900);
}

// =====================================================
// PLAY
// =====================================================

void showPlay() {

  // Frame 1

  display.clearDisplay();

  drawCat(
    55,
    23,
    1
  );

  // Ball
  display.drawCircle(
    101,
    43,
    7,
    SSD1306_WHITE
  );

  display.drawLine(
    97,
    39,
    105,
    47,
    SSD1306_WHITE
  );

  display.drawLine(
    105,
    39,
    97,
    47,
    SSD1306_WHITE
  );

  drawActionText(
    "PLAYING"
  );

  display.display();

  beep(
    1500,
    100
  );

  delay(250);

  // Frame 2

  display.clearDisplay();

  drawCat(
    70,
    23
  );

  display.drawCircle(
    34,
    43,
    7,
    SSD1306_WHITE
  );

  display.drawLine(
    30,
    39,
    38,
    47,
    SSD1306_WHITE
  );

  display.drawLine(
    38,
    39,
    30,
    47,
    SSD1306_WHITE
  );

  drawActionText(
    "PLAYING"
  );

  display.display();

  delay(500);
}

// =====================================================
// PET
// =====================================================

void showPet() {

  display.clearDisplay();

  drawCat(
    64,
    24,
    1
  );

  // Affection marks
  display.drawCircle(
    40,
    12,
    3,
    SSD1306_WHITE
  );

  display.drawCircle(
    88,
    12,
    3,
    SSD1306_WHITE
  );

  drawActionText(
    "PETTED"
  );

  display.display();

  beep(
    1000,
    100
  );

  delay(600);
}

// =====================================================
// HELLO
// =====================================================

void showHello() {

  display.clearDisplay();

  drawCat(
    58,
    24
  );

  // Paw
  display.drawCircle(
    94,
    23,
    6,
    SSD1306_WHITE
  );

  display.drawLine(
    88,
    27,
    80,
    37,
    SSD1306_WHITE
  );

  // Greeting lines
  display.drawLine(
    103,
    15,
    110,
    10,
    SSD1306_WHITE
  );

  display.drawLine(
    105,
    22,
    113,
    22,
    SSD1306_WHITE
  );

  display.drawLine(
    103,
    29,
    110,
    34,
    SSD1306_WHITE
  );

  drawActionText(
    "HELLO"
  );

  display.display();

  beep(
    1800,
    150
  );

  delay(600);
}

// =====================================================
// PIR WELCOME
// =====================================================

void showPIRHello() {

  display.clearDisplay();

  drawCat(
    64,
    23,
    1
  );

  // Motion lines
  display.drawLine(
    20,
    18,
    28,
    24,
    SSD1306_WHITE
  );

  display.drawLine(
    18,
    30,
    28,
    30,
    SSD1306_WHITE
  );

  display.drawLine(
    108,
    18,
    100,
    24,
    SSD1306_WHITE
  );

  display.drawLine(
    110,
    30,
    100,
    30,
    SSD1306_WHITE
  );

  drawActionText(
    "WELCOME"
  );

  display.display();

  beep(
    1400,
    100
  );

  delay(600);
}

// =====================================================
// JOYSTICK
// =====================================================

void checkJoystick() {

  int x =
    analogRead(JOY_X);

  int y =
    analogRead(JOY_Y);

  int button =
    digitalRead(JOY_SW);

  if (millis() - lastAction < 900) {
    return;
  }

  // UP = FEED
  if (y < 1000) {

    hunger -= 20;

    happiness += 5;

    limitValues();

    updateMood();

    currentAction = "FEED";

    showFeed();

    lastAction = millis();
  }

  // DOWN = SLEEP
  else if (y > 3000) {

    energy += 20;

    limitValues();

    updateMood();

    currentAction = "SLEEP";

    showSleep();

    lastAction = millis();
  }

  // RIGHT = PLAY
  else if (x > 3000) {

    happiness += 10;

    energy -= 10;

    limitValues();

    updateMood();

    currentAction = "PLAY";

    showPlay();

    lastAction = millis();
  }

  // LEFT = PET
  else if (x < 1000) {

    happiness += 5;

    limitValues();

    updateMood();

    currentAction = "PET";

    showPet();

    lastAction = millis();
  }

  // PRESS = HELLO
  else if (button == LOW) {

    currentAction = "HELLO";

    showHello();

    lastAction = millis();
  }
}

// =====================================================
// PIR
// =====================================================

void checkPIR() {

  int motion =
    digitalRead(PIR_PIN);

  if (motion == HIGH) {

    if (millis() - lastMotion > 5000) {

      visits++;

      happiness += 5;

      limitValues();

      updateMood();

      currentAction = "WELCOME";

      showPIRHello();

      lastMotion = millis();
    }
  }
}

// =====================================================
// DHT11
// =====================================================

void readDHT() {

  if (millis() - lastDHTRead >= 3000) {

    float t =
      dht.readTemperature();

    float h =
      dht.readHumidity();

    if (!isnan(t)) {

      temperature = t;

      updateTemperatureMessage();
    }

    if (!isnan(h)) {

      humidity = h;
    }

    lastDHTRead = millis();
  }
}

// =====================================================
// PET STAT DECAY
// =====================================================

void updatePetStats() {

  if (millis() - lastStatUpdate >= 30000) {

    hunger += 2;

    energy -= 1;

    limitValues();

    updateMood();

    lastStatUpdate = millis();
  }
}

// =====================================================
// DASHBOARD
// =====================================================

String dashboardPage() {

  String page = R"rawliteral(

<!DOCTYPE html>

<html>

<head>

<meta name="viewport"
content="width=device-width, initial-scale=1">

<title>My Digital Pet</title>

<style>

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  font-family: Arial, sans-serif;
  background: #eeeaff;
  color: #332b4f;
}

.header {
  background: white;
  padding: 25px;
  border-bottom: 1px solid #ddd5f5;
}

.header h1 {
  margin: 0;
  color: #57458c;
  font-size: 30px;
}

.header p {
  color: #777;
  margin: 7px 0 0;
}

.container {
  max-width: 1100px;
  margin: auto;
  padding: 25px;
}

.hero {
  display: grid;
  grid-template-columns: 1.4fr 1fr;
  gap: 20px;
  margin-bottom: 20px;
}

.card {
  background: white;
  border-radius: 22px;
  padding: 22px;
  box-shadow: 0 5px 20px rgba(70,50,120,.08);
}

.pet-card {
  background: #e5ddff;
  min-height: 320px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.bigcat {
  font-family: monospace;
  font-size: 26px;
  line-height: 1.25;
  color: #57458c;
  text-align: center;
  white-space: pre;
  margin: 15px;
}

.speech {
  background: white;
  padding: 13px 20px;
  border-radius: 18px;
  color: #57458c;
  font-weight: bold;
  position: relative;
  margin-top: 5px;
}

.speech:after {
  content: "";
  position: absolute;
  bottom: -10px;
  left: 50%;
  border-width: 10px 10px 0;
  border-style: solid;
  border-color: white transparent transparent transparent;
}

.mood {
  margin-top: 20px;
  font-size: 25px;
  font-weight: bold;
  color: #57458c;
}

.action {
  margin-top: 8px;
  color: #777;
}

.online {
  display: inline-block;
  padding: 7px 12px;
  border-radius: 20px;
  background: #e1f5e8;
  color: #287944;
  font-size: 13px;
}

.stats {
  display: grid;
  grid-template-columns: repeat(4,1fr);
  gap: 15px;
  margin-bottom: 20px;
}

.stat-title {
  color: #777;
  font-size: 14px;
}

.stat-value {
  color: #57458c;
  font-size: 30px;
  font-weight: bold;
  margin: 8px 0;
}

.bar {
  height: 8px;
  background: #eee;
  border-radius: 10px;
  overflow: hidden;
}

.fill {
  height: 100%;
  background: #8b75d6;
  width: 0%;
  transition: width .3s ease;
}

.environment {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 15px;
}

.environment-box {
  background: #f7f5ff;
  border-radius: 16px;
  padding: 20px;
}

.environment-value {
  color: #57458c;
  font-size: 27px;
  font-weight: bold;
  margin-top: 7px;
}

.doodle {
  font-family: monospace;
  font-size: 22px;
  line-height: 1.15;
  color: #8b75d6;
  text-align: center;
  white-space: pre;
  margin: 20px;
}

@media(max-width:700px) {

  .hero {
    grid-template-columns: 1fr;
  }

  .stats {
    grid-template-columns: 1fr 1fr;
  }

  .environment {
    grid-template-columns: 1fr;
  }

}

</style>

</head>

<body>

<div class="header">

<h1>My Digital Pet</h1>

<p>Your little IoT companion</p>

</div>

<div class="container">

<div class="hero">

<div class="card pet-card">

<div class="speech" id="temperatureMessage">
I'm feeling good!
</div>

<div class="bigcat" id="cat">

 /\_/\\
( o.o )
 > ^ <

</div>

<div class="mood"
id="mood">
HAPPY
</div>

<div class="action">

Current action:

<span id="action">
READY
</span>

</div>

</div>

<div class="card">

<span class="online">
ESP32 ONLINE
</span>

<h2>Pet Status</h2>

<div class="doodle">

      /\_/\\
     / o.o \ 
    (   ^   )
     \_____/
      /   \
     /_____\
     
</div>

<p>
Visits:
<b id="visits">0</b>
</p>

<p>
Last action:
<b id="lastAction">READY</b>
</p>

</div>

</div>

<div class="stats">

<div class="card">

<div class="stat-title">
Happiness
</div>

<div class="stat-value"
id="happiness">
80
</div>

<div class="bar">

<div class="fill"
id="happinessBar">
</div>

</div>

</div>

<div class="card">

<div class="stat-title">
Energy
</div>

<div class="stat-value"
id="energy">
80
</div>

<div class="bar">

<div class="fill"
id="energyBar">
</div>

</div>

</div>

<div class="card">

<div class="stat-title">
Hunger
</div>

<div class="stat-value"
id="hunger">
20
</div>

<div class="bar">

<div class="fill"
id="hungerBar">
</div>

</div>

</div>

<div class="card">

<div class="stat-title">
Visits
</div>

<div class="stat-value"
id="visits2">
0
</div>

<div class="stat-title">
times detected
</div>

</div>

</div>

<div class="card">

<h2>Environment</h2>

<div class="environment">

<div class="environment-box">

<div class="stat-title">
Temperature
</div>

<div class="environment-value">

<span id="temperature">
0.0
</span>
C

</div>

</div>

<div class="environment-box">

<div class="stat-title">
Humidity
</div>

<div class="environment-value">

<span id="humidity">
0.0
</span>
%

</div>

</div>

</div>

</div>

</div>

<script>

function updateDashboard() {

  fetch('/status')

  .then(response => response.json())

  .then(data => {

    document.getElementById(
      "happiness"
    ).innerText =
      data.happiness;

    document.getElementById(
      "energy"
    ).innerText =
      data.energy;

    document.getElementById(
      "hunger"
    ).innerText =
      data.hunger;

    document.getElementById(
      "visits"
    ).innerText =
      data.visits;

    document.getElementById(
      "visits2"
    ).innerText =
      data.visits;

    document.getElementById(
      "mood"
    ).innerText =
      data.mood;

    document.getElementById(
      "action"
    ).innerText =
      data.action;

    document.getElementById(
      "lastAction"
    ).innerText =
      data.action;

    document.getElementById(
      "temperature"
    ).innerText =
      data.temperature.toFixed(1);

    document.getElementById(
      "humidity"
    ).innerText =
      data.humidity.toFixed(1);

    document.getElementById(
      "temperatureMessage"
    ).innerText =
      data.temperatureMessage;

    document.getElementById(
      "happinessBar"
    ).style.width =
      data.happiness + "%";

    document.getElementById(
      "energyBar"
    ).style.width =
      data.energy + "%";

    document.getElementById(
      "hungerBar"
    ).style.width =
      data.hunger + "%";

  })

  .catch(error => {

    console.log(
      "ESP32 connection error"
    );

  });

}

// Live update every 500 ms

setInterval(
  updateDashboard,
  500
);

// First update immediately

updateDashboard();

</script>

</body>

</html>

)rawliteral";

  return page;
}

// =====================================================
// ROOT PAGE
// =====================================================

void handleRoot() {

  server.send(
    200,
    "text/html",
    dashboardPage()
  );
}

// =====================================================
// LIVE STATUS JSON
// =====================================================

void handleStatus() {

  String json = "{";

  json += "\"happiness\":";
  json += String(happiness);

  json += ",";

  json += "\"energy\":";
  json += String(energy);

  json += ",";

  json += "\"hunger\":";
  json += String(hunger);

  json += ",";

  json += "\"visits\":";
  json += String(visits);

  json += ",";

  json += "\"temperature\":";
  json += String(temperature, 1);

  json += ",";

  json += "\"humidity\":";
  json += String(humidity, 1);

  json += ",";

  json += "\"mood\":\"";
  json += mood;
  json += "\"";

  json += ",";

  json += "\"action\":\"";
  json += currentAction;
  json += "\"";

  json += ",";

  json += "\"temperatureMessage\":\"";
  json += temperatureMessage;
  json += "\"";

  json += "}";

  server.send(
    200,
    "application/json",
    json
  );
}

// =====================================================
// SETUP
// =====================================================

void setup() {

  Serial.begin(115200);

  // Joystick
  pinMode(
    JOY_SW,
    INPUT_PULLUP
  );

  // PIR
  pinMode(
    PIR_PIN,
    INPUT
  );

  // Buzzer
  pinMode(
    BUZZER_PIN,
    OUTPUT
  );

  // OLED
  Wire.begin(
    OLED_SDA,
    OLED_SCL
  );

  if (!display.begin(
        SSD1306_SWITCHCAPVCC,
        0x3C
      )) {

    Serial.println(
      "OLED not found!"
    );

    while (true);
  }

  // DHT
  dht.begin();

  // Initial OLED
  updateMood();

  showReady();

  // WiFi
  Serial.println();
  Serial.println(
    "Connecting to WiFi..."
  );

  WiFi.begin(
    ssid,
    password
  );

  while (
    WiFi.status() != WL_CONNECTED
  ) {

    delay(500);

    Serial.print(".");
  }

  Serial.println();

  Serial.println(
    "WiFi Connected!"
  );

  Serial.print(
    "IP Address: "
  );

  Serial.println(
    WiFi.localIP()
  );

  // Web server
  server.on(
    "/",
    handleRoot
  );

  server.on(
    "/status",
    handleStatus
  );

  server.begin();

  Serial.println(
    "Dashboard started."
  );
}

// =====================================================
// LOOP
// =====================================================

void loop() {

  server.handleClient();

  checkJoystick();

  checkPIR();

  readDHT();

  updatePetStats();

  updateMood();

  delay(10);
}
