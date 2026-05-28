#include <Wire.h>
#include <Adafruit_AHTX0.h>
// Cambio: Adafruit_PN532 NO soporta correctamente HCE de Android en
// modulos PN532 con firmware v1.6 (clones rojos). Usamos la libreria
// de elechouse/Seeed que maneja correctamente la activacion ISO-DEP.
#include <PN532_I2C.h>
#include <PN532.h>
#include <ESP32Servo.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// ========================
// WiFi Configuration
// ========================
#define WIFI_SSID "WILSON"
#define WIFI_PASS "W91275990"

// ========================
// Backend Configuration
// ========================
#define API_BASE_URL "https://us-central1-aula-inteligente-30639.cloudfunctions.net/api"
#define API_KEY "e41c939b3478cefcdff9aae786541377d86fd45ca0134e69da97224c66cafe9c"
#define CLASSROOM_ID "aula-201-edificio-b"

// ========================
// AHT20 - I2C
// ========================
Adafruit_AHTX0 aht;

// ========================
// PN532 - I2C
// ========================
#define SDA_PIN 21
#define SCL_PIN 22

PN532_I2C pn532i2c(Wire);
PN532 nfc(pn532i2c);

// ========================
// MQ2
// ========================
#define MQ2_DO_PIN 27
#define MQ2_AO_PIN 34

// ========================
// ACS712
// ========================
#define ACS712_PIN 35
#define ACS712_SENSITIVITY 0.185  // V/A for 5A module (0.100 for 20A, 0.066 for 30A)
#define ACS712_VCC 5.0
#define VREF 3.3
#define ADC_RES 4095

// ========================
// Servo
// ========================
#define SERVO_PIN 13
#define SERVO_OPEN 90
#define SERVO_CLOSE 0
#define TIEMPO_ABIERTO 3000

Servo miServo;

// ========================
// Intervalos
// ========================
#define SENSOR_INTERVAL_MS 60000  // Enviar datos cada 60s

unsigned long ultimoEnvio = 0;
unsigned long ultimaLecturaSensores = 0;
#define SENSOR_READ_INTERVAL_MS 5000

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

  // ========================
  // WiFi
  // ========================
  Serial.print("Conectando a WiFi...");
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  int intentos = 0;
  while (WiFi.status() != WL_CONNECTED && intentos < 20) {
    delay(500);
    Serial.print(".");
    intentos++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println(" CONECTADO");
    Serial.print("  IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println(" FALLIDO - continuando sin WiFi");
  }

  Serial.println("\nSistema listo. Acerca una tarjeta NFC...\n");
}

void loop() {
  unsigned long ahora = millis();

  // Leer y reportar sensores de forma no bloqueante cada 5 segundos
  if (ahora - ultimaLecturaSensores >= SENSOR_READ_INTERVAL_MS) {
    ultimaLecturaSensores = ahora;

    float temperatura = leerAHT20();
    float humedad = leerAHT20Humedad();
    int mq2Digital = leerMQ2Digital();
    int mq2Analog = leerMQ2Analogico();
    float potenciaWatts = leerACS712();
    int calidadAire = calcularCalidadAire(mq2Analog);

    Serial.println("==================================");

    // Enviar datos al backend cada 60s
    if (ahora - ultimoEnvio >= SENSOR_INTERVAL_MS) {
      ultimoEnvio = ahora;

      if (WiFi.status() == WL_CONNECTED) {
        enviarLectura(temperatura, humedad, mq2Digital == LOW, potenciaWatts, calidadAire);
      } else {
        Serial.println("[WIFI] No conectado - reintentando conexion...");
        WiFi.reconnect();
      }
    }
  }

  // NFC se ejecuta de forma casi instantanea en cada ciclo de loop sin trabar el sistema
  leerPN532yControlServo();
}

// ========================
// AHT20 - Temperatura
// ========================
float leerAHT20() {
  sensors_event_t humidity, temp;
  aht.getEvent(&humidity, &temp);

  Serial.print("[AHT20] Temperatura: ");
  Serial.print(temp.temperature);
  Serial.print(" °C");

  return temp.temperature;
}

// ========================
// AHT20 - Humedad
// ========================
float leerAHT20Humedad() {
  sensors_event_t humidity, temp;
  aht.getEvent(&humidity, &temp);

  Serial.print("  |  Humedad: ");
  Serial.print(humidity.relative_humidity);
  Serial.println(" %");

  return humidity.relative_humidity;
}

// ========================
// MQ2 - Digital
// ========================
int leerMQ2Digital() {
  int value = digitalRead(MQ2_DO_PIN);
  Serial.print("[MQ2]   Digital: ");
  Serial.print(value == LOW ? "ALERTA - Gas/Humo detectado" : "Normal");
  return value;
}

// ========================
// MQ2 - Analogico
// ========================
int leerMQ2Analogico() {
  int value = analogRead(MQ2_AO_PIN);
  Serial.print("  |  Analogico: ");
  Serial.println(value);
  return value;
}

// ========================
// Calcular Indice de Calidad del Aire (0-300)
// ========================
int calcularCalidadAire(int mq2Analog) {
  if (mq2Analog < 200) return (int)map(mq2Analog, 0, 200, 0, 20);
  if (mq2Analog < 800) return (int)map(mq2Analog, 200, 800, 20, 50);
  if (mq2Analog < 2000) return (int)map(mq2Analog, 800, 2000, 50, 100);
  if (mq2Analog < 3000) return (int)map(mq2Analog, 2000, 3000, 100, 200);
  return (int)map(mq2Analog, 3000, 4095, 200, 300);
}

// ========================
// ACS712
// ========================
float leerACS712() {
  long suma = 0;
  const int muestras = 200;

  for (int i = 0; i < muestras; i++) {
    suma += analogRead(ACS712_PIN);
    delayMicroseconds(500);
  }

  float promedio = suma / (float)muestras;
  float voltaje = (promedio / ADC_RES) * VREF;
  float corriente = (voltaje - (ACS712_VCC / 2.0)) / ACS712_SENSITIVITY;
  float potencia = corriente * 220.0;  // 220V asumido

  if (potencia < 0) potencia = 0;

  Serial.print("[ACS712] ADC: ");
  Serial.print(promedio, 1);
  Serial.print("  |  Voltaje: ");
  Serial.print(voltaje, 3);
  Serial.print(" V  |  Corriente: ");
  Serial.print(corriente, 3);
  Serial.print(" A  |  Potencia: ");
  Serial.print(potencia, 1);
  Serial.println(" W");

  return potencia;
}

// ========================
// PN532 + Servo
// ========================
void leerPN532yControlServo() {
  uint8_t success;
  uint8_t uid[7];
  uint8_t uidLength;

  // Timeout mas amplio: los telefonos Android en HCE pueden tardar mas
  // que una tarjeta MIFARE en presentarse, sobre todo si la pantalla
  // estaba apagada milisegundos antes.
  success = nfc.readPassiveTargetID(
    PN532_MIFARE_ISO14443A,
    uid,
    &uidLength,
    500);

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
  // Intentar HCE (Host Card Emulation)
  // El smartphone en modo llave responde a comandos APDU
  // ========================
  String hceUid = leerHceUid();
  if (hceUid.length() > 0) {
    Serial.print("[HCE]   UID desde telefono: ");
    Serial.println(hceUid);
    uidStr = hceUid;
  }

  // ========================
  // Validar contra backend
  // ========================
  if (WiFi.status() == WL_CONNECTED) {
    if (validarNfcConBackend(uidStr)) {
      Serial.println("[ACCESO] AUTORIZADO (backend) - Abriendo cerradura...");
      abrirCerradura();
    } else {
      Serial.println("[ACCESO] DENEGADO (backend) - UID no registrado");
    }
  } else {
    // Fallback local si no hay WiFi
    if (estaAutorizadoLocal(uidStr)) {
      Serial.println("[ACCESO] AUTORIZADO (local) - Abriendo cerradura...");
      abrirCerradura();
    } else {
      Serial.println("[ACCESO] DENEGADO (local) - UID no registrado");
    }
  }

  delay(1000);
}

// ========================
// Intentar lectura HCE via APDU
// Intenta intercambio APDU con el tag
// Si responde, extrae el UID del telefono
// Si falla (tarjeta comun), devuelve vacio
// ========================
String leerHceUid() {
  uint8_t response[64];
  uint8_t responseLength;

  // SELECT AID = F000000001 (proprietario Aula Inteligente)
  // Se incluye Le=0x00 al final para asegurar compatibilidad con HCE
  // de Android (algunas implementaciones exigen APDU case 4).
  uint8_t selectApdu[] = {
    0x00, 0xA4, 0x04, 0x00, 0x05,
    0xF0, 0x00, 0x00, 0x00, 0x01,
    0x00
  };

  // Importante: NO insertar delay aqui. El PN532 ya tiene activado el
  // target ISO-DEP justo despues de readPassiveTargetID. Una pausa larga
  // hace que algunos telefonos pierdan la activacion HCE.

  bool ok = false;
  int reintentos = 4;

  for (int i = 0; i < reintentos; i++) {
    responseLength = sizeof(response);
    ok = nfc.inDataExchange(selectApdu, sizeof(selectApdu), response, &responseLength);
    if (ok && responseLength >= 2) {
      break;
    }
    Serial.print("[HCE]   intento ");
    Serial.print(i + 1);
    Serial.print(": ok=");
    Serial.print(ok);
    Serial.print(" len=");
    Serial.println(responseLength);
    delay(20);
  }

  if (!ok || responseLength < 2) {
    Serial.println("[HCE]   No responde a APDU - tarjeta comun o HCE inactivo");
    return "";
  }

  // Verificar status word (0x9000)
  if (response[responseLength - 2] != 0x90 || response[responseLength - 1] != 0x00) {
    Serial.print("[HCE]   SELECT AID rechazado, SW=");
    if (response[responseLength - 2] < 0x10) Serial.print("0");
    Serial.print(response[responseLength - 2], HEX);
    if (response[responseLength - 1] < 0x10) Serial.print("0");
    Serial.println(response[responseLength - 1], HEX);
    return "";
  }

  Serial.println("[HCE]   Telefono en modo llave detectado!");

  // Enviar comando cualquiera para recibir el UID
  // El HCE service responde a cualquier comando con el UID + 0x9000
  uint8_t readCmd[] = { 0x00, 0xB0, 0x00, 0x00, 0x00 };
  responseLength = sizeof(response);
  ok = nfc.inDataExchange(readCmd, sizeof(readCmd), response, &responseLength);

  if (!ok || responseLength < 2) {
    Serial.println("[HCE]   Error al leer UID del telefono");
    return "";
  }

  // Verificar status word
  if (response[responseLength - 2] != 0x90 || response[responseLength - 1] != 0x00) {
    Serial.println("[HCE]   Respuesta invalida del telefono");
    return "";
  }

  // Extraer UID (todo antes del status word)
  String uid = "";
  for (uint8_t i = 0; i < responseLength - 2; i++) {
    uid += (char)response[i];
  }

  uid.toUpperCase();
  return uid;
}

// ========================
// Validar NFC via Backend
// ========================
bool validarNfcConBackend(String uid) {
  if (WiFi.status() != WL_CONNECTED) return false;

  HTTPClient http;
  String url = String(API_BASE_URL) + "/auth/validate-nfc";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("x-api-key", API_KEY);

  String payload = "{\"card_uid\":\"" + uid + "\"}";
  int codigo = http.POST(payload);

  if (codigo == 200) {
    String respuesta = http.getString();
    http.end();

    DynamicJsonDocument doc(256);
    DeserializationError error = deserializeJson(doc, respuesta);
    if (error) return false;

    bool autorizado = doc["authorized"] | false;
    if (autorizado) {
      const char* nombre = doc["name"] | "Desconocido";
      Serial.print("[BACKEND] Acceso autorizado para: ");
      Serial.println(nombre);
    }
    return autorizado;
  }

  http.end();
  return false;
}

// ========================
// Verificar UID local (fallback)
// ========================
String uidsAutorizados[] = { "A1B2C3D4", "E5F6A7B8", "32AF4E06" };
int totalAutorizados = 3;

bool estaAutorizadoLocal(String uid) {
  for (int i = 0; i < totalAutorizados; i++) {
    if (uid == uidsAutorizados[i]) {
      return true;
    }
  }
  return false;
}

// ========================
// Enviar lectura al backend
// ========================
void enviarLectura(float temperatura, float humedad, bool humoDetectado, float potenciaWatts, int calidadAire) {
  HTTPClient http;
  String url = String(API_BASE_URL) + "/sensors/reading";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("x-api-key", API_KEY);

  StaticJsonDocument<256> doc;
  doc["classroom_id"] = CLASSROOM_ID;
  doc["temperature"] = temperatura;
  doc["humidity"] = humedad;
  doc["smoke_detected"] = humoDetectado;
  doc["power_consumption_watts"] = potenciaWatts;
  doc["air_quality_index"] = calidadAire;
  doc["api_key"] = API_KEY;

  String payload;
  serializeJson(doc, payload);

  Serial.print("[HTTP] Enviando lectura... ");
  int codigo = http.POST(payload);

  if (codigo > 0) {
    Serial.print("HTTP ");
    Serial.print(codigo);
    Serial.print(" - ");
    Serial.println(http.getString());
  } else {
    Serial.print("Error: ");
    Serial.println(http.errorToString(codigo));
  }

  http.end();
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
