#include <AccelStepper.h>
#include <Adafruit_Fingerprint.h>
#include <SoftwareSerial.h>


SoftwareSerial mySerial(2, 3);
Adafruit_Fingerprint finger(&mySerial);


// pins 9, 11, 10, and 12 set to HALF4WIRE mode
AccelStepper stepper(AccelStepper::HALF4WIRE, 9, 11, 10, 12);


//set three revolutions of the motor
const int STEPS_PER_REV = 2560;
const int REV_COUNT     = 3;     


#define BUTTON_PIN 8
bool lastButton = LOW;


void setup() {
  Serial.begin(9600);
  delay(100);


  Serial.println("Adafruit Fingerprint test");
  finger.begin(57600);
  delay(5);
  if (!finger.verifyPassword()) {
    Serial.println("!! Sensor not found. Halting.");
    while (1) delay(1);
  }
  finger.getTemplateCount();
  Serial.print("Enrolled templates: ");
  Serial.println(finger.templateCount);


  // configure the AccelStepper motor speed
  stepper.setMaxSpeed(800.0);      // steps/sec – increase for faster
  stepper.setAcceleration(400.0);  // better torque


  // configure the led outputs
  pinMode(7, OUTPUT);  // if match found
  pinMode(6, OUTPUT);  // if no m--atch
  pinMode(5, OUTPUT);  // if no finger


  // configure closing garage button
  pinMode(BUTTON_PIN, INPUT); 
  Serial.println("Setup complete.");
}


void loop() {
  if (stepper.distanceToGo() != 0) {
    stepper.run();
    return;
  }


  checkFingerprint();
  checkButton();
}


//when fingerprint matches, rotate motor so garage door opens
void checkFingerprint() {
  uint8_t p = finger.getImage();
  if (p == FINGERPRINT_NOFINGER){
    digitalWrite(5, HIGH); delay(200); digitalWrite(5, LOW);
    return;}
  if (p != FINGERPRINT_OK) {
    Serial.println("Image error"); //digitalWrite(5, HIGH); delay(200); digitalWrite(5, LOW);
    return;
  }


  if (finger.image2Tz() != FINGERPRINT_OK) {
    Serial.println("Convert error"); return;
  }
  p = finger.fingerSearch();
  if (p == FINGERPRINT_OK) {
    Serial.println("Match! → spinning FORWARD 3 revs");
    digitalWrite(7, HIGH);
    stepper.move( REV_COUNT * STEPS_PER_REV );
    digitalWrite(7, LOW);
  } else {
    Serial.println("No match"); digitalWrite(6, HIGH); delay(200); digitalWrite(6, LOW);
  }
}


//when button pressed, rotate other direction so the garage door closes
void checkButton() {
  bool curr = digitalRead(BUTTON_PIN);
  if (lastButton == LOW && curr == HIGH) {
    Serial.println("Button! → spinning REVERSE 3 revs");
    stepper.move( -REV_COUNT * STEPS_PER_REV );
  }
  lastButton = curr;
}
