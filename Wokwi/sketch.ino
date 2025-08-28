#include <ESP32Servo.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

Servo myServo;
int servoPin = 35;

LiquidCrystal_I2C lcd(0x27, 16, 2);

const int TRIG_PIN = 17;
const int ECHO_PIN = 18;

const int ldrPin = 6;      
const int ledPin = 14;     

const int buzzerPin = 2;  

const String correctPassword = "1234"; 
String enteredPassword = "";
bool doorOpen = false;
int attemptCount = 0; 
const int maxAttempts = 3; 

int currentAngle = 0;
unsigned long lastCheckTime = 0;
const long checkInterval = 10000; 
bool countingDown = false;
int countdownValue = 10;

bool buzzerActive = false;
bool lightAlarmActive = false; 
bool wrongPasswordActive = false; 

unsigned long duration;
float distance;

void setup() {
  Serial.begin(115200);
  
  // تهيئة منافذ I2C للشاشة (SDA=4, SCL=5)
  Wire.begin(4, 5);
  
  // Initialize LCD
  lcd.init();
  lcd.backlight();
  
  // Welcome message
  lcd.setCursor(0, 0);
  lcd.print("Safe System");
  lcd.setCursor(0, 1);
  lcd.print("Enter 4-digit PIN:");
  
  myServo.attach(servoPin);
  myServo.write(0);
  currentAngle = 0;  
  
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  
  pinMode(ldrPin, INPUT);
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, LOW); 
  
  pinMode(buzzerPin, OUTPUT);
  digitalWrite(buzzerPin, LOW); 
  
  Serial.println("Safe system started");
  Serial.println("Enter 4-digit password :");
  Serial.println("Press ENTER to submit password");
  
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Welcome!");
  lcd.setCursor(0, 1);
  lcd.print("Enter PIN: ");
  delay(2000);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Enter 4-digit PIN:");
}

bool checkDistanceSensor() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  
  duration = pulseIn(ECHO_PIN, HIGH);
  
  distance = duration * 0.034 / 2;
  
  Serial.print("Distance: ");
  Serial.print(distance);
  Serial.println(" cm");
  return distance < 10;
}

int readLDR() {
  return analogRead(ldrPin);
}

void startBuzzer() {
  tone(buzzerPin, 1000); 
}

void stopBuzzer() {
  noTone(buzzerPin); 
}

void manageBuzzerAndLight() {
  if (buzzerActive) {
    startBuzzer();
    digitalWrite(ledPin, HIGH);
  } else {
    stopBuzzer();
    digitalWrite(ledPin, LOW);
  }
}

void checkLDRForAlarm() {
  int ldrValue = readLDR();
  
  if (ldrValue > 1000 && !doorOpen) {
    if (!lightAlarmActive) {
      Serial.print("High light detected: ");
      Serial.println(ldrValue);
      
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("SECURITY ALERT!");
      lcd.setCursor(0, 1);
      lcd.print("High light detected");
      
      buzzerActive = true;
      lightAlarmActive = true;
      Serial.println("Buzzer and Light turned ON due to high light");
      
      delay(2000);
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Enter 4-digit PIN:");
    }
  } else {
    if (lightAlarmActive) {
      buzzerActive = false;
      lightAlarmActive = false;
      stopBuzzer();
      digitalWrite(ledPin, LOW);
      Serial.println("Buzzer and Light turned OFF due to low light");
    }
  }
}

void displayMessage(String line1, String line2 = "") {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(line1);
  if (line2 != "") {
    lcd.setCursor(0, 1);
    lcd.print(line2);
  }
  delay(100); 
}

void openDoor() {
  displayMessage("Access Granted!", "Opening Door...");
  
  for (int i = currentAngle; i <= 90; i++) {
    myServo.write(i);
    currentAngle = i;
    delay(30);
  }
  
  doorOpen = true;
  attemptCount = 0;
  lastCheckTime = millis();
  countingDown = false;
  buzzerActive = false; 
  lightAlarmActive = false; 
  wrongPasswordActive = false; 
  
  stopBuzzer();
  digitalWrite(ledPin, LOW);
  
  int ldrValue = readLDR();
  Serial.print("LDR Value: ");
  Serial.println(ldrValue);

  if (ldrValue > 1000) {  
    digitalWrite(ledPin, HIGH);
    Serial.println("LED ON (Bright environment)");
    
    displayMessage("LED: ON (Light)", "LDR: " + String(ldrValue));
    delay(2000);
  } else { 
    digitalWrite(ledPin, LOW);
    Serial.println("LED OFF (Dark environment)");
    
    displayMessage("LED: OFF (Dark)", "LDR: " + String(ldrValue));
    delay(2000);
  }

  displayMessage("Safe Opened!", "Check LDR value");
  
  Serial.println("Safe opened successfully!");
  delay(2000);
}

void closeDoor() {
  displayMessage("Closing Door...", "");
  
  for (int i = currentAngle; i >= 0; i--) {
    myServo.write(i);
    currentAngle = i;
    delay(30);
  }
  
  doorOpen = false;
  countingDown = false;
  
  digitalWrite(ledPin, LOW);
  stopBuzzer(); 
  
  displayMessage("Enter 4-digit PIN:", "");
  
  Serial.println("Door closed automatically");
}

void showCountdown() {
  if (!countingDown) {
    countingDown = true;
    countdownValue = 10;
    lastCheckTime = millis();
  }
  
  unsigned long currentTime = millis();
  if (currentTime - lastCheckTime >= 1000) {
    lastCheckTime = currentTime;
    countdownValue--;
    
    if (checkDistanceSensor()) {
      countingDown = false;
      displayMessage("Door Open", "Person detected");
      Serial.println("Person detected during countdown. Countdown stopped.");
      delay(2000);
      return;
    }
    
    displayMessage("Closing in:", String(countdownValue) + " seconds");
    
    Serial.print("Closing in: ");
    Serial.print(countdownValue);
    Serial.println(" seconds");
    
    if (countdownValue <= 0) {
      closeDoor();
    }
  }
}

void showInvalidInput() {
  displayMessage("INVALID INPUT!", "4 digits only");
  
  Serial.println("INVALID! Enter exactly 4 digits (0-9)");
  
  delay(2000);
  displayMessage("Enter 4-digit PIN:", "");
}

void checkPassword() {
  Serial.print("Checking: '");
  Serial.println(enteredPassword);
  
  if (enteredPassword.length() != 4) {
    Serial.println("Password length invalid! Must be exactly 4 digits.");
    showInvalidInput();
    enteredPassword = "";
    return;
  }
  
  for (int i = 0; i < enteredPassword.length(); i++) {
    if (!isDigit(enteredPassword[i])) {
      showInvalidInput();
      enteredPassword = "";
      return;
    }
  }
  
  if (enteredPassword == correctPassword) {
    openDoor();
  } else {
    showWrongPassword();
  }
  enteredPassword = "";
}

void showWrongPassword() {
  attemptCount++;
  
  displayMessage("Wrong Password!", "Try: " + String(attemptCount) + "/" + String(maxAttempts));
  
  Serial.print("Wrong password! Attempt ");
  Serial.print(attemptCount);
  Serial.print("/");
  Serial.println(maxAttempts);
  
  buzzerActive = true;
  wrongPasswordActive = true;
  startBuzzer();
  digitalWrite(ledPin, HIGH);
  delay(300);
  buzzerActive = false;
  wrongPasswordActive = false;
  stopBuzzer();
  digitalWrite(ledPin, LOW);
  
  delay(2000);
  
  if (attemptCount >= maxAttempts) {
    showNoMoreAttempts();
  } else {
    displayMessage("Enter 4-digit PIN:", "");
  }
}

void showNoMoreAttempts() {
  displayMessage("No more tries!", "Wait 30 sec...");
  
  Serial.println("No more attempts! System locked for 30 seconds");
  
  buzzerActive = true;
  wrongPasswordActive = true;
  Serial.println("Buzzer and Light turned ON due to wrong password attempts");
  
  unsigned long lockStartTime = millis();
  while (millis() - lockStartTime < 30000) {
    startBuzzer();
    digitalWrite(ledPin, HIGH);
    
    int remainingTime = 30 - ((millis() - lockStartTime) / 1000);
    
    displayMessage("Locked: " + String(remainingTime) + "s", "");
    
    delay(1000);
  }
  
  attemptCount = 0;
  buzzerActive = false;
  wrongPasswordActive = false;
  stopBuzzer();
  digitalWrite(ledPin, LOW);
  Serial.println("Buzzer and Light turned OFF after wrong password lockout");
  
  displayMessage("Enter 4-digit PIN:", "");
}

void checkSensorPeriodically() {
  unsigned long currentTime = millis();
  
  if (doorOpen && (currentTime - lastCheckTime >= checkInterval)) {
    lastCheckTime = currentTime;
    
    if (!checkDistanceSensor()) {
      Serial.println("No one detected. Starting countdown...");
      showCountdown();
    } else {
      countingDown = false;
      displayMessage("Door Open", "Person detected");
      Serial.println("Person detected. Door remains open.");
      delay(2000);
    }
  }
}

void loop() {
  checkLDRForAlarm();
  
  manageBuzzerAndLight();
  
  static unsigned long lastLDRPrint = 0;
  if (millis() - lastLDRPrint >= 2000) {
    int val = readLDR();
    Serial.print("LDR Reading: ");
    Serial.println(val);
    lastLDRPrint = millis();
  }

  if (Serial.available() > 0) {
    char inputChar = Serial.read();
    
    if (inputChar == '\n' || inputChar == '\r') {
      if (enteredPassword.length() > 0) {
        Serial.print("Checking password: ");
        Serial.println(enteredPassword);
        
        if (enteredPassword.length() != 4) {
          Serial.println("Password length invalid! Must be exactly 4 digits.");
          showInvalidInput();
          enteredPassword = "";
        } else {
          checkPassword();
        }
        
        displayMessage("Enter 4-digit PIN:", "");
      }
    } else if (inputChar == 8 || inputChar == 127) {
      if (enteredPassword.length() > 0) {
        enteredPassword.remove(enteredPassword.length() - 1);
        
        displayMessage("Password:", enteredPassword);
      }
    } else {
      if (isDigit(inputChar)) {
        if (enteredPassword.length() >= 4) {
          displayMessage("MAX 4 digits!", "Press ENTER");
          Serial.println("Maximum 4 digits allowed! Press ENTER to submit.");
          enteredPassword = "";
          delay(2000);
          displayMessage("Enter 4-digit PIN:", "");
        } else {
          enteredPassword += inputChar;
          
          String stars = "";
          for (int i = 0; i < enteredPassword.length(); i++) {
            stars += "*";
          }
          displayMessage("Password:", stars);
          
          if (enteredPassword.length() == 4) {
            Serial.print("Password entered: ");
            Serial.println(enteredPassword);
            Serial.println("Press ENTER to submit");
          }
        }
      } else {
        showInvalidInput();
        enteredPassword = "";
      }
    }
  }

  if (countingDown) {
    showCountdown();
  } else {
    checkSensorPeriodically();
  }
  
  delay(100);
}