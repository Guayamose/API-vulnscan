# 📖 Documentación Técnica y Explicativa – API Vulnscan

**Versión:** 1.0  
**Base URL (mock Heroku):**  
`https://vulnscan-mock-df9c85d690d0.herokuapp.com`

---

## 1. Introducción

La API de Vulnscan se compone de dos bloques principales:

1. **Auth API** → encargada de login, refresco de sesiones, revocación y validación de tokens.  
2. **Ingesta API** → encargada de recibir y gestionar escaneos de proyectos (**Scans**) y los hallazgos de seguridad encontrados (**Findings**).

El diseño se inspira en **mejores prácticas de APIs modernas**: uso de **JWTs para autenticación**, **idempotencia en operaciones críticas**, **respuestas consistentes de error**, y un modelo de datos sencillo pero extensible.

---

## 2. Tokens JWT – Cómo funcionan

### 🔑 Concepto
Un JWT es un token firmado digitalmente que contiene **claims** (información del usuario y permisos). Se usa como **credencial** para acceder a la API sin necesidad de enviar la contraseña en cada request.

### 🔄 Flujo
1. El usuario se loguea con `username` y `password` → recibe dos tokens:
   - **Access token** (corto, 15 min).  
   - **Refresh token** (largo, 30 días).  
2. El cliente (extensión VS Code o web) guarda ambos tokens.  
3. Para cada request protegido, envía:
   ```
   Authorization: Bearer <access_token>
   ```
4. Cuando el access token expira, el cliente usa el refresh para pedir otro par nuevo.  
5. Si el usuario cierra sesión, el refresh se revoca.

### ⚠️ Reglas importantes
- **Nunca almacenar tokens en texto plano.**  
  - En web: usar `HttpOnly cookies` o almacenamiento seguro.  
  - En VS Code extension: usar el `SecretStorage` API.  
- **No compartir el JWT_SECRET.**  
  - Solo el servidor lo conoce y lo usa para firmar/validar.  
- **El cliente nunca “fabrica” tokens.**  
  - Solo los consume y reenvía.

---

## 3. Idempotency-Key – Qué es y por qué usarla

### 🔑 Concepto
Una **Idempotency-Key** es un identificador único (normalmente un UUID) que el cliente envía en operaciones críticas como `POST /scans`.

Sirve para:
- **Evitar duplicados** si el cliente reintenta la misma petición (por ejemplo, por timeout o error de red).  
- Garantizar que la operación se ejecute **una sola vez**, aunque se mande varias veces.

### 🔄 Flujo de idempotencia
1. El cliente genera un UUID y lo envía en el header:  
   ```
   Idempotency-Key: 11111111-1111-1111-1111-111111111111
   ```
2. El servidor guarda ese UUID asociado al resultado de la operación.  
3. Si el mismo cliente reenvía la misma operación con el mismo UUID:
   - Si el body es idéntico → devuelve el mismo resultado (201 con el mismo scan_id).  
   - Si el body difiere → devuelve error `409 idempotency_conflict`.

---

## 4. Modelos de datos

### 👤 User
Representa a un desarrollador que usa la extensión.  
- Campos:
  - `id` → identificador único.  
  - `email` → login.  
  - `password_digest` → hash de la contraseña.  
  - `org` → referencia a la organización.  
  - `role` → `developer | manager | admin`.

### 🏢 Organization
Representa a una empresa que contrata Vulnscan.  
- Campos:
  - `id`, `name`.  
  - `seats` → nº de licencias disponibles.  
  - Relación: muchos `users`.

### 🧪 Scan
Contenedor de findings, es un **escaneo completo** del workspace.  
- Campos:
  - `org` → organización dueña del scan.  
  - `user_ref` → usuario que ejecutó el scan.  
  - `project_slug` → identificador del proyecto (ej. `backend-api`).  
  - `scan_type` → `workspace | file | pipeline`.  
  - `commit_sha` → opcional, commit analizado.  
  - `started_at` / `finished_at` → timestamps ISO-8601.  
  - `findings_ingested` → nº de findings recibidos.  
  - `deduped` → nº de findings deduplicados.  
  - `status` → `running | completed | failed`.  
  - `idempotency_key` → UUID único por scan.

### 🧩 Finding
Un hallazgo de vulnerabilidad.  
- Campos:
  - `scan_id` → referencia al scan.  
  - `rule_id` → regla que disparó (ej. Bandit B303).  
  - `severity` → `LOW | MEDIUM | HIGH | CRITICAL`.  
  - `file_path` → archivo afectado.  
  - `line` → línea en el archivo.  
  - `message` → descripción del problema.  
  - `fingerprint_hint` → hash/huella opcional para deduplicación.

---

## 5. Endpoints detallados

### 🔐 Auth

#### `POST /api/v1/auth/password_login`
**Función:** Login con credenciales.  
**Entrada:**
```json
{ "username": "dev@acme.com", "password": "test1234" }
```
**Respuesta:**
```json
{
  "access": "<jwt_access>",
  "refresh": "<jwt_refresh>",
  "expires_in": 900,
  "user": { "sub": 1, "org": "org_mock_acme", "role": "developer" }
}
```
**Uso recomendado:**  
Guardar `refresh` en almacenamiento seguro. Usar `access` en cada request. Renovar antes de expirar.

---

#### `POST /api/v1/auth/refresh`
**Función:** Rota el refresh token y devuelve nuevos tokens.  
**Entrada:**
```json
{ "refresh": "<jwt_refresh>" }
```

---

#### `POST /api/v1/auth/revoke`
**Función:** Revoca refresh → logout.  
**Entrada:**
```json
{ "refresh": "<jwt_refresh>" }
```

---

#### `GET /api/v1/auth/whoami`
**Función:** Valida el access y devuelve datos del usuario.  
**Headers:**
```
Authorization: Bearer <access>
```

---

### 🧪 Scans

#### `POST /api/v1/scans`
**Función:** Crear un nuevo scan.  
**Headers:**
```
Authorization: Bearer <access>
Idempotency-Key: <uuid>
```
**Body:**
```json
{
  "org": "org_mock_acme",
  "user_ref": "usr_mock_1",
  "project_slug": "backend-api",
  "scan_type": "workspace",
  "commit_sha": "abc123",
  "started_at": "2025-09-28T10:00:00Z",
  "finished_at": "2025-09-28T10:00:05Z",
  "findings_ingested": 3,
  "deduped": 0,
  "status": "completed"
}
```
**Notas:**  
- `started_at` y `finished_at` deben ser **ISO-8601 con Z** (UTC).  
- `finished_at` ≥ `started_at`.  
- Si `Idempotency-Key` ya existe con body distinto → `409 idempotency_conflict`.

---

#### `GET /api/v1/scans/:id`
Devuelve un scan específico con todos sus campos.  

---

#### `GET /api/v1/scans?...`
Permite listar scans filtrados por query params:
- `project_slug`  
- `status`  
- `idempotency_key`

---

### 🧩 Findings

#### `POST /api/v1/findings`
**Función:** Registrar un hallazgo dentro de un scan.  
**Body:**
```json
{
  "scan_id": "42",
  "rule_id": "B303",
  "severity": "HIGH",
  "file_path": "app/auth/crypto.py",
  "line": 42,
  "message": "Uso inseguro de MD5",
  "fingerprint_hint": "app/auth/crypto.py:42:B303"
}
```
**Notas:**  
- `severity` debe ser uno de los valores permitidos.  
- `scan_id` debe existir o devolverá `404 not_found`.

---

#### `GET /api/v1/findings?scan_id=42`
Lista todos los findings asociados a un scan.

---

## 6. Errores y validaciones

Todas las respuestas de error siguen el formato:
```json
{ "error": "<code>", "message": "<texto>", "details": {} }
```

### Errores comunes
- **Auth**  
  - `invalid_credentials` → usuario/contraseña incorrectos.  
  - `invalid_token` → access/refresh inválido o expirado.  

- **Scans**  
  - `validation_error` → campos mal formados.  
  - `idempotency_conflict` → Idempotency-Key en conflicto.  
  - `not_found` → scan no existe.  

- **Findings**  
  - `validation_error` → severity inválido.  
  - `not_found` → scan_id no existe.  

- **General**  
  - `rate_limited` → demasiadas peticiones.  

---

## 7. Paridad con Django (no tiene por que ser igual si ocurren mejoras no hay problema)

El mock en Rails es un **doble de contrato**.  
El backend Django debe:
- Implementar los **mismos endpoints, métodos y códigos de error**.  
- Usar **DRF + SimpleJWT** para JWT.  
- Aplicar **idempotencia en scans**.  
- Validar enums y timestamps exactamente igual.  
- Mantener la misma forma de errores y payloads.  
