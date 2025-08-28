#include <ESP32Servo.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

Servo myServo;
int servoPin = 13;

LiquidCrystal_I2C lcd(0x27, 16, 2);

const int irSensorPin = 35;

const int ldrPin = 34;      
const int ledPin = 14;      

const int buzzerPin = 4;   

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

void setup() {
  Serial.begin(115200);
  myServo.attach(servoPin);
  myServo.write(0); 
  
  pinMode(irSensorPin, INPUT);
  
  pinMode(ldrPin, INPUT);
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, LOW); 
  
  pinMode(buzzerPin, OUTPUT);
  digitalWrite(buzzerPin, LOW); 
  
  lcd.init();
  lcd.backlight();
  
  lcd.setCursor(0, 0);
  lcd.print("Safe System");
  lcd.setCursor(0, 1);
  lcd.print("Enter 4-digit PIN:");
  
  Serial.println("Safe system started");
  Serial.println("Enter 4-digit password (1234):");
  Serial.println("Press ENTER to submit password");
}

bool checkIRSensor() {
  return digitalRead(irSensorPin) == LOW;
}

int readLDR() {
  return analogRead(ldrPin); 
}

void manageBuzzerAndLight() {
  if (buzzerActive) {
    digitalWrite(buzzerPin, HIGH);
    digitalWrite(ledPin, HIGH);
  } else {
    digitalWrite(buzzerPin, LOW);
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
      digitalWrite(buzzerPin, LOW);
      digitalWrite(ledPin, LOW);
      Serial.println("Buzzer and Light turned OFF due to low light");
    }
  }
}

void openDoor() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Access Granted!");
  lcd.setCursor(0, 1);
  lcd.print("Opening Door...");
  
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
  
  int ldrValue = readLDR();
  Serial.print("LDR Value: ");
  Serial.println(ldrValue);

  if (ldrValue > 1000) {  
    digitalWrite(ledPin, HIGH);
    Serial.println("LED ON (Bright environment)");
    
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("LED: ON (Light)");
    lcd.setCursor(0, 1);
    lcd.print("LDR: ");
    lcd.print(ldrValue);
    delay(2000);
  } else { 
    digitalWrite(ledPin, LOW);
    Serial.println("LED OFF (Dark environment)");
    
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("LED: OFF (Dark)");
    lcd.setCursor(0, 1);
    lcd.print("LDR: ");
    lcd.print(ldrValue);
    delay(2000);
  }

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Safe Opened!");
  lcd.setCursor(0, 1);
  lcd.print("Check LDR value");
  
  Serial.println("Safe opened successfully!");
  delay(2000);
}

void closeDoor() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Closing Door...");
  
  for (int i = currentAngle; i >= 0; i--) {
    myServo.write(i);
    currentAngle = i;
    delay(30);
  }
  
  doorOpen = false;
  countingDown = false;
  
  digitalWrite(ledPin, LOW);
  digitalWrite(buzzerPin, LOW); 
  
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Enter 4-digit PIN:");
  
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
    
    if (checkIRSensor()) {
      countingDown = false;
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Door Open");
      lcd.setCursor(0, 1);
      lcd.print("Person detected");
      Serial.println("Person detected during countdown. Countdown stopped.");
      delay(2000);
      return;
    }
    
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Closing in:");
    lcd.setCursor(0, 1);
    lcd.print("    ");
    lcd.print(countdownValue);
    lcd.print(" seconds    ");
    
    Serial.print("Closing in: ");
    Serial.print(countdownValue);
    Serial.println(" seconds");
    
    if (countdownValue <= 0) {
      closeDoor();
    }
  }
}

void showInvalidInput() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("INVALID INPUT!");
  lcd.setCursor(0, 1);
  lcd.print("4 digits only");
  
  Serial.println("INVALID! Enter exactly 4 digits (0-9)");
  
  delay(2000);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Enter 4-digit PIN:");
}

void checkPassword() {
  Serial.print("Checking: '");
  Serial.println(enteredPassword);
  
  if (enteredPassword.length() != 4) {
    Serial.println("Password length invalid! Must be exactly 4 digits.");
    showInvalidInput();
  }
  
  for (int i = 0; i < enteredPassword.length(); i++) {
    if (!isDigit(enteredPassword[i])) {
      showInvalidInput();
      return;
    }
  }
  
  if (enteredPassword == correctPassword) {
    openDoor();
  } else {
    showWrongPassword();
  }
}

void showWrongPassword() {
  attemptCount++;
  
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Wrong Password!");
  lcd.setCursor(0, 1);
  lcd.print("Try: ");
  lcd.print(attemptCount);
  lcd.print("/");
  lcd.print(maxAttempts);
  
  Serial.print("Wrong password! Attempt ");
  Serial.print(attemptCount);
  Serial.print("/");
  Serial.println(maxAttempts);
  
  buzzerActive = true;
  wrongPasswordActive = true;
  digitalWrite(buzzerPin, HIGH);
  digitalWrite(ledPin, HIGH);
  delay(300);
  buzzerActive = false;
  wrongPasswordActive = false;
  digitalWrite(buzzerPin, LOW);
  digitalWrite(ledPin, LOW);
  
  delay(2000);
  
  if (attemptCount >= maxAttempts) {
    showNoMoreAttempts();
  } else {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Enter 4-digit PIN:");
  }
}

void showNoMoreAttempts() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("No more tries!");
  lcd.setCursor(0, 1);
  lcd.print("Wait 30 sec...");
  
  Serial.println("No more attempts! System locked for 30 seconds");
  
  buzzerActive = true;
  wrongPasswordActive = true;
  Serial.println("Buzzer and Light turned ON due to wrong password attempts");
  
  unsigned long lockStartTime = millis();
  while (millis() - lockStartTime < 30000) {
    digitalWrite(buzzerPin, HIGH);
    digitalWrite(ledPin, HIGH);
    
    int remainingTime = 30 - ((millis() - lockStartTime) / 1000);
    
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Locked: ");
    lcd.print(remainingTime);
    lcd.print("s");
    
    delay(1000);
  }
  
  attemptCount = 0;
  buzzerActive = false;
  wrongPasswordActive = false;
  digitalWrite(buzzerPin, LOW);
  digitalWrite(ledPin, LOW);
  Serial.println("Buzzer and Light turned OFF after wrong password lockout");
  
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Enter 4-digit PIN:");
}

void checkSensorPeriodically() {
  unsigned long currentTime = millis();
  
  if (doorOpen && (currentTime - lastCheckTime >= checkInterval)) {
    lastCheckTime = currentTime;
    
    if (!checkIRSensor()) {
      Serial.println("No one detected. Starting countdown...");
      showCountdown();
    } else {
      countingDown = false;
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Door Open");
      lcd.setCursor(0, 1);
      lcd.print("Person detected");
      Serial.println("Person detected. Door remains open.");
      delay(2000);
    }
  }
}

void loop() {
  if (Serial.available() > 0) {
    char inputChar = Serial.read();
    
    if (inputChar == '\n' || inputChar == '\r') {
      if (enteredPassword.length() > 0) {
        Serial.print("Checking password: ");
        Serial.println(enteredPassword);
        
        if (enteredPassword.length() != 4) {
          Serial.println("Password too long! Clearing and showing error.");
          showInvalidInput();
          enteredPassword = "";
          return;
        }
        
        checkPassword();
        enteredPassword = "";
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Enter 4-digit PIN:");
      }
      return;
    }
    
    if (inputChar == 8 || inputChar == 127) {
      if (enteredPassword.length() > 0) {
        enteredPassword.remove(enteredPassword.length() - 1);
        
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Password:");
        lcd.setCursor(0, 1);
        for (int i = 0; i < enteredPassword.length(); i++) {
          lcd.print("*");
        }
      }
      return;
    } 
    else {
      if (isDigit(inputChar)) {
        if (enteredPassword.length() >= 4) {
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("MAX 4 digits!");
          lcd.setCursor(0, 1);
          lcd.print("Press ENTER");
          Serial.println("Maximum 4 digits allowed! Press ENTER to submit.");
          enteredPassword = "";
          delay(2000);
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Enter 4-digit PIN:");
          return;
        }
        
        enteredPassword += inputChar;
        
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Password:");
        lcd.setCursor(0, 1);
        for (int i = 0; i < enteredPassword.length(); i++) {
          lcd.print("*");
        }
        
        if (enteredPassword.length() == 4) {
          Serial.print("Password entered: ");
          Serial.println(enteredPassword);
          Serial.println("Press ENTER to submit");
        }
      } else {
        showInvalidInput();
        enteredPassword = "";
        return;
      }
    }
  }
  
  checkLDRForAlarm();
  
  manageBuzzerAndLight();
  
  static unsigned long lastLDRPrint = 0;
  if (millis() - lastLDRPrint >= 2000) {
    int val = readLDR();
    Serial.print("LDR Reading: ");
    Serial.println(val);
    lastLDRPrint = millis();
  }

  if (countingDown) {
    showCountdown();
  } else {
    checkSensorPeriodically();
  }
  
  delay(100);
}