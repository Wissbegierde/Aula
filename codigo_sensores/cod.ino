#include <Wire.h>
#include <Adafruit_AHTX0.h>
#include <Adafruit_PN532.h>
#include <ESP32Servo.h>

// ========================
// AHT20 - I2C
// ========================
Adafruit_AHTX0 aht;

// ========================
// PN532 - I2C
// ========================
#define SDA_PIN 21
#define SCL_PIN 22

Adafruit_PN532 nfc(SDA_PIN, SCL_PIN);

// ========================
// MQ2
// ========================
#define MQ2_DO_PIN 27
#define MQ2_AO_PIN 34

// ========================
// ACS712
// ========================
#define ACS712_PIN 35

// ========================
// Servo
// ========================
#define SERVO_PIN 13
#define SERVO_OPEN 90
#define SERVO_CLOSE 0
#define TIEMPO_ABIERTO 3000

Servo miServo;

// ========================
// UIDs autorizados
// ========================
String uidsAutorizados[] = { "A1B2C3D4", "E5F6A7B8", "32AF4E06" };
int totalAutorizados = 3;

void setup() {
  Serial.begin(115200);
  delay(1000);

  Wire.begin(SDA_PIN, SCL_PIN);

  // ========================
  // AHT20
  // ========================
  Serial.println("Iniciando AHT20...");

  if (!aht.begin()) {
    Serial.println("  ERROR: AHT20 no detectado");
  } else {
    Serial.println("  AHT20 OK");
  }

  // ========================
  // PN532
  // ========================
  Serial.println("Iniciando PN532...");

  nfc.begin();

  uint32_t versiondata = nfc.getFirmwareVersion();

  if (!versiondata) {
    Serial.println("  ERROR: PN532 no detectado");
  } else {

    Serial.print("  Chip PN5");
    Serial.println((versiondata >> 24) & 0xFF, HEX);

    Serial.print("  Firmware ver: ");
    Serial.print((versiondata >> 16) & 0xFF, DEC);
    Serial.print('.');
    Serial.println((versiondata >> 8) & 0xFF, DEC);

    nfc.SAMConfig();

    Serial.println("  PN532 OK");
  }

  // ========================
  // MQ2
  // ========================
  pinMode(MQ2_DO_PIN, INPUT);

  // ========================
  // ADC
  // ========================
  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);

  // ========================
  // Servo
  // ========================
  miServo.attach(SERVO_PIN);
  miServo.write(SERVO_CLOSE);

  Serial.println("  Servo OK - Posicion inicial: cerrado");

  Serial.println("\nSistema listo. Acerca una tarjeta NFC...\n");
}

void loop() {

  // ========================
  // Leer sensores
  // ========================
  leerAHT20();
  leerMQ2();
  leerACS712();

  // ========================
  // NFC + Servo
  // ========================
  leerPN532yControlServo();

  Serial.println("==================================");

  delay(2000);
}

// ========================
// AHT20
// ========================
void leerAHT20() {

  sensors_event_t humidity, temp;

  aht.getEvent(&humidity, &temp);

  Serial.print("[AHT20] Temperatura: ");
  Serial.print(temp.temperature);

  Serial.print(" °C  |  Humedad: ");
  Serial.print(humidity.relative_humidity);

  Serial.println(" %");
}

// ========================
// MQ2
// ========================
void leerMQ2() {

  int mq2Digital = digitalRead(MQ2_DO_PIN);
  int mq2Analog = analogRead(MQ2_AO_PIN);

  Serial.print("[MQ2]   Digital: ");

  Serial.print(
    mq2Digital == LOW ? "ALERTA - Gas/Humo detectado" : "Normal");

  Serial.print("  |  Analogico: ");

  Serial.println(mq2Analog);
}

// ========================
// ACS712
// ========================
void leerACS712() {

  long suma = 0;

  const int muestras = 200;

  for (int i = 0; i < muestras; i++) {

    suma += analogRead(ACS712_PIN);

    delayMicroseconds(500);
  }

  float promedio = suma / (float)muestras;

  float voltaje = (promedio / 4095.0) * 3.3;

  Serial.print("[ACS712] ADC promedio: ");
  Serial.print(promedio, 1);

  Serial.print("  |  Voltaje en pin: ");
  Serial.print(voltaje, 3);

  Serial.println(" V");
}

// ========================
// PN532 + Servo
// ========================
void leerPN532yControlServo() {

  uint8_t success;

  uint8_t uid[7];
  uint8_t uidLength;

  success = nfc.readPassiveTargetID(
    PN532_MIFARE_ISO14443A,
    uid,
    &uidLength,
    1000);

  if (!success) {

    Serial.println("[NFC]   Sin tarjeta");

    return;
  }

  Serial.println("\n--- Tarjeta detectada ---");

  Serial.print("UID: ");

  String uidStr = "";

  for (uint8_t i = 0; i < uidLength; i++) {

    if (uid[i] < 0x10) {
      Serial.print("0");
      uidStr += "0";
    }

    Serial.print(uid[i], HEX);

    uidStr += String(uid[i], HEX);

    if (i < uidLength - 1) {
      Serial.print(":");
    }
  }

  Serial.println();

  uidStr.toUpperCase();

  Serial.print("[NFC]   UID normalizado: ");

  Serial.println(uidStr);

  // ========================
  // Validar acceso
  // ========================
  if (estaAutorizado(uidStr)) {

    Serial.println("[ACCESO] AUTORIZADO - Abriendo cerradura...");

    abrirCerradura();

  } else {

    Serial.println("[ACCESO] DENEGADO - UID no registrado");
  }

  delay(1000);
}

// ========================
// Verificar UID
// ========================
bool estaAutorizado(String uid) {

  for (int i = 0; i < totalAutorizados; i++) {

    if (uid == uidsAutorizados[i]) {

      return true;
    }
  }

  return false;
}

// ========================
// Servo
// ========================
void abrirCerradura() {

  miServo.write(SERVO_OPEN);

  Serial.println("[SERVO]  Posicion: ABIERTO");

  delay(TIEMPO_ABIERTO);

  miServo.write(SERVO_CLOSE);

  Serial.println("[SERVO]  Posicion: CERRADO");
}
