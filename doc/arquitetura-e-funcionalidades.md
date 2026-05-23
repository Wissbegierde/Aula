# Aula Inteligente — Arquitectura y Funcionalidades

## Visión General

**Aula Inteligente** es un sistema IoT para la gestión de aulas inteligentes. Integra:

- **Aplicación móvil/desktop/web** (Flutter) — interfaz de usuario
- **Backend** (Firebase Cloud Functions + Express.js + Firestore) — API REST, autenticación, reglas de seguridad
- **Hardware** (ESP32 + sensores) — recolección de datos del ambiente y control de acceso por NFC

---

## Arquitectura de Comunicación

```
┌────────────────┐       ┌──────────────────────────┐       ┌────────────────┐
│   Flutter App  │ ◄──── │  Firebase Cloud Functions │ ◄──── │  ESP32 +       │
│   (mobile/web) │  HTTP │  (Express.js + Firestore) │  HTTP │  Sensores      │
└────────────────┘  REST │                          │  REST └────────────────┘
                         └──────────────────────────┘
                                 │
                                 ▼
                          ┌──────────────┐
                          │   Firestore   │
                          │   (NoSQL DB)  │
                          └──────────────┘
```

- **Flutter App** → Consume la API REST pública alojada en Firebase Cloud Functions.
- **ESP32** → Envía lecturas de sensores directamente a la misma API REST.
- **Backend** → Almacena todo en Firestore, genera alertas automáticamente mediante triggers y ejecuta tareas programadas (cierre automático).

---

## Funcionalidades Detalladas

### 1. Monitoreo Ambiental (Temperatura, Humedad, Calidad del Aire)

| Característica | Detalle |
|---|---|
| **Sensores** | AHT20 (temperatura y humedad), MQ-2 (gas/humo) |
| **Frecuencia del ESP32** | Envía lecturas cada **60 segundos** (`SENSOR_INTERVAL_MS = 60000`) |
| **Polling de la App** | App consulta `GET /sensors/latest` cada **30 segundos** |
| **Latencia típica** | Una nueva lectura del sensor aparece en la app en hasta ~**90s** (peor caso) |
| **Gráficos** | Histórico de 24h con gráficos de línea segmentados por métrica |
| **Alerta de humo** | Banner rojo en la parte superior cuando `smoke_detected = true` |

**Flujo de datos (ejemplo: temperatura):**
```
t=0s    ESP32 lee sensor AHT20 (temperatura = 24.5°C)
t=60s   ESP32 envía POST /sensors/reading → Firestore guarda
t=75s   App hace GET /sensors/latest → recibe 24.5°C
        → tiempo total: ~75s (entre 60s y 90s)
```

### 2. Control de Acceso por NFC

| Característica | Detalle |
|---|---|
| **Lector** | PN532 (NFC/RFID) conectado al ESP32 en la puerta del aula |
| **App como tarjeta** | Usuario acerca el celular (NFC) al lector — la app lee el UID del tag/tarjeta y lo envía a `POST /auth/validate-nfc` |
| **Validación** | Backend verifica `card_uid` en Firestore; retorna `{ allowed: true/false }` |
| **Acción física** | Servomotor abre/cierra la cerradura por 3 segundos (`TIEMPO_ABIERTO = 3000ms`) |
| **Registro** | Cada entrada/salida se registra en `/access/logs` con timestamp y nombre del usuario |

### 3. Panel Principal (Dashboard)

- Tarjetas con **últimas lecturas** de los sensores (temperatura, humedad, calidad del aire)
- Resumen de **alertas activas** (no resueltas)
- **Último registro de acceso** (quién entró/salió)
- Atajos de navegación filtrados por rol del usuario

### 4. Monitoreo de Energía

| Característica | Detalle |
|---|---|
| **Sensor** | ACS712 (medición de corriente) en el ESP32 |
| **Métricas** | Potencia actual (kW), energía del día (kWh), proyección mensual |
| **Visualización** | Gráfico de barras de las últimas 24h; composición por dispositivos (iluminación, proyector, AC, otros) |

### 5. Alertas Automáticas

| Disparador | Severidad | Condición |
|---|---|---|
| Humo detectado | **Crítico** | `smoke_detected = true` |
| Temperatura alta | **Warning** | `temperature > 35°C` |
| Humedad alta | **Info** | `humidity > 70%` |
| Mala calidad del aire | **Warning** | `air_quality_index > 150` |

- Creadas automáticamente por un **trigger de Firestore** (`onCreate` de sensor reading).
- Pueden **resolverse** manualmente por el usuario mediante `PATCH /alerts/:id/resolve`.
- Contador de no resueltas visible en la app.

### 6. Cierre Automático del Aula

- Función programada en Firebase (PubSub) ejecutada **cada 30 minutos**.
- Si el aula está **inactiva por más de 2 horas** (sin lecturas de sensor), el sistema cierra el aula y apaga las luces (simulado).

### 7. Roles y Permisos

| Pantalla / Acción | Admin | Profesor | Conserje |
|---|---|---|---|
| Dashboard | ✅ | ✅ | ✅ |
| Monitoreo Ambiental | ✅ | ✅ | ❌ |
| Logs de Acceso | ✅ (ve todos) | ✅ (ve propios) | ✅ |
| Energía | ✅ | ❌ | ✅ |
| Alertas | ✅ | ✅ | ✅ |
| CRUD Usuarios/Aulas | ✅ | ❌ | ❌ |

### 8. Autenticación

- Inicio de sesión con **email y contraseña** (mock: `admin@aula.com`, `profesor@aula.com`, `conserje@aula.com`)
- **Token JWT** almacenado en el `ApiClient` y enviado como `Authorization: Bearer <token>`
- **API Key** (`aula-sensor-key-2024`) enviada en todas las solicitudes mediante el header `x-api-key`

---

## Componentes del Sistema

### Flutter App (`aula_inteligente/`)

| Capa | Tecnología |
|---|---|
| Lenguaje | Dart (Flutter 3.5+) |
| Estado | Provider |
| Navegación | GoRouter (5 pestañas en bottom nav) |
| Solicitudes | `package:http` |
| Gráficos | `fl_chart` |
| NFC | `nfc_manager` |
| Build | Web, Android, iOS, Desktop |

### Backend (`backend/`)

| Componente | Tecnología |
|---|---|
| Runtime | Node.js 18/20 |
| Framework | Express.js |
| Base de datos | Firestore |
| Auth | Firebase Auth + JWT + API Key |
| Deploy | Firebase Cloud Functions |
| Programación | Cloud PubSub (cron) |

### Hardware (`codigo_sensores/`)

| Componente | Función |
|---|---|
| ESP32 | Microcontrolador principal (Wi-Fi + GPIO) |
| AHT20 | Temperatura y humedad (I2C) |
| MQ-2 | Gas/humo (digital + analógico) |
| ACS712 | Corriente eléctrica / potencia |
| PN532 | Lector NFC/RFID (I2C) |
| Servomotor | Cerradura de la puerta |

---

## Latencias e Intervalos (Resumen)

| Flujo | Intervalo |
|---|---|
| ESP32 → API (lectura de sensores) | Cada **60s** |
| App → API (polling de sensores) | Cada **30s** |
| App → API (polling de acceso) | Cada **60s** |
| App → API (polling de alertas) | Cada **60s** |
| Backend → cierre automático | Cada **30 min** (verifica inactividad de 2h) |
| Cerradura se abre | **3s** (delay del servomotor) |

**Latencia sensor → usuario:** entre 60s y 90s (media ~75s).

---

## Endpoints de la API

| Método | Ruta | Autenticación | Descripción |
|---|---|---|---|
| GET | `/health` | — | Health check |
| POST | `/sensors/reading` | API Key | Ingresar lectura del ESP32 |
| GET | `/sensors/latest` | Bearer | Última lectura del aula |
| GET | `/sensors/history` | Bearer | Histórico de lecturas |
| POST | `/auth/validate-nfc` | API Key | Validar tarjeta NFC |
| POST | `/access/open` | Bearer | Abrir puerta + log |
| POST | `/access/close` | Bearer | Cerrar puerta + log |
| GET | `/access/logs` | Bearer | Histórico de acceso |
| GET | `/alerts` | Bearer | Listar alertas |
| PATCH | `/alerts/:id/resolve` | Bearer | Resolver alerta |
| GET/POST | `/classrooms` | Bearer | CRUD aulas |
| GET/POST | `/users` | Bearer (admin) | CRUD usuarios |
