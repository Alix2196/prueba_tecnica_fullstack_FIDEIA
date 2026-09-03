# Sistema de gestión de tickets — Mesa de ayuda (Prueba Técnica Fullstack FIDEIA)

Núcleo mínimo de una mesa de ayuda interna: gestión del ciclo de vida de tickets (creación, cambio de estado, comentarios e historial de auditoría), expuesto vía API REST y consumido por un frontend con filtros y paginación server-side.

## 1. Stack tecnológico

| Capa | Tecnología | Por qué |
|---|---|---|
| Backend | Java + Spring Boot | Tipado fuerte, buen soporte nativo para transacciones (clave para la operación compuesta estado + comentario + historial), validación declarativa (Bean Validation) y manejo explícito de excepciones vía `@ControllerAdvice`. |
| Frontend | Angular | Estructura opinada (servicios, componentes, RxJS) que facilita modelar explícitamente los estados de carga/vacío/error exigidos por el enunciado. |
| Base de datos | PostgreSQL | Soporte nativo de tipos `ENUM`, triggers para reforzar invariantes de negocio a nivel de esquema (inmutabilidad del historial, integridad de roles, bloqueo de comentarios en `CERRADO` — ver sección 5), e índices compuestos útiles para la consulta de reporte. |

Versiones usadas: **Java 25** (JDK Eclipse Temurin), **Spring Boot 3.5.13** sobre **Maven** (ver nota abajo), **PostgreSQL** (probado contra 18.6; el esquema solo usa features disponibles desde 14+), **Angular** (versión a definir al implementar el frontend).

> Nota: se empezó con Spring Boot 3.2.5, la versión estable más señalada al planear el stack. Al fijar el proyecto a JDK 25 (LTS más reciente) se detectó que Spring Framework 6.1.6 (el que trae 3.2.5) no puede correr en JDK 25: su ASM interno para el escaneo de componentes (`@Configuration`, `@Service`, etc.) no reconoce el bytecode de esa versión y la aplicación falla al arrancar. Se subió a **Spring Boot 3.5.13** (Spring Framework 6.2.x), que sí lo soporta.

## 2. Estructura del repositorio (planeada)

```
/backend    Spring Boot — API REST, lógica de negocio, pruebas
/frontend   Angular — listado y detalle de tickets
/db         Scripts DDL (schema.sql), datos de prueba (seed) y consulta de reporte
/postman    Colección de Postman (api.json) para probar la API manualmente
ENSAYO.md   Parte B — ensayo sobre uso de Claude Code
README.md   Este archivo
```

## 3. Cómo levantar el proyecto

### 3.1 Backend

Requisitos: JDK 25 y PostgreSQL 14+ corriendo con el esquema de `db/schema.sql` aplicado. No hace falta tener Maven instalado: el proyecto incluye Maven Wrapper.

```bash
# 1. Crear la base de datos, aplicar el esquema y cargar datos de prueba
psql -U postgres -c "CREATE DATABASE tickets;"
psql -U postgres -d tickets -f db/schema.sql
psql -U postgres -d tickets -f db/seed.sql   # opcional: 18 tickets de ejemplo

# 2. Levantar la API (por defecto en http://localhost:8080)
cd backend
./mvnw spring-boot:run        # Linux/macOS
mvnw.cmd spring-boot:run      # Windows
```

`db/reporte.sql` es independiente de la app: se corre directo con `psql` (o cualquier cliente SQL) sobre la base ya poblada para ver el reporte de la sección 3.5.

Los valores por defecto (base `tickets`, usuario `tickets`, password `tickets` en `localhost:5432`) alcanzan para levantar el proyecto sin configuración adicional si el paso 1 se hizo con esas credenciales. Para otros valores, Spring Boot lee las variables directamente del entorno del sistema operativo (no hay archivo `.env`: eso no es un mecanismo nativo de Spring Boot/Java). Por ejemplo:

```bash
# Linux/macOS
export DB_URL=jdbc:postgresql://localhost:5432/tickets
export DB_USER=tickets
export DB_PASSWORD=tickets

# Windows (PowerShell)
$env:DB_URL = "jdbc:postgresql://localhost:5432/tickets"
$env:DB_USER = "tickets"
$env:DB_PASSWORD = "tickets"
```

Variables de entorno soportadas (con su valor por defecto): `DB_URL` (`jdbc:postgresql://localhost:5432/tickets`), `DB_USER` (`tickets`), `DB_PASSWORD` (`tickets`), `SERVER_PORT` (`8080`), `APP_CORS_ALLOWED_ORIGINS` (`http://localhost:4200`).

El backend usa `spring.jpa.hibernate.ddl-auto=validate`: nunca modifica el esquema, solo valida al arrancar que las entidades coincidan con `db/schema.sql` (que es la fuente de verdad, ver sección 7).

### 3.2 Frontend

Requiere Node 20+ (probado con Node 24) y el backend corriendo en `http://localhost:8080` (la URL está fija en `frontend/src/app/core/services/api-config.ts`; no hay build de producción en el alcance de esta prueba, ver sección 12).

```bash
cd frontend
npm install
npm start          # http://localhost:4200
```

No hay autenticación: la barra superior tiene un selector "Actuando como" con el catálogo de usuarios (`GET /api/usuarios`, ver sección 6), y ese usuario se usa como autor al comentar o cambiar el estado de un ticket (README sección 8).

## 4. Modelo de dominio

| Entidad | Descripción |
|---|---|
| **Ticket** | Título, descripción, prioridad (`BAJA`, `MEDIA`, `ALTA`), estado, solicitante, agente asignado (opcional), fecha de creación y de última actualización. |
| **Comentario** | Texto, autor y fecha. Pertenece a un ticket. |
| **Historial de estado** | Registro inmutable de cada transición: estado anterior, estado nuevo, autor y fecha. No se edita ni se borra. |

Los usuarios (solicitantes y agentes) son un catálogo simple precargado; no hay registro ni gestión de usuarios ni autenticación real (fuera de alcance, ver sección 8).

## 5. Regla de negocio central: máquina de estados

```
ABIERTO      →  EN_PROCESO
EN_PROCESO   →  RESUELTO
RESUELTO     →  CERRADO
RESUELTO     →  EN_PROCESO   (reapertura, solo si RESUELTO hace menos de 3 días)
```

Restricciones:
- Cualquier transición no listada se rechaza con error explícito y código HTTP adecuado (p. ej. no se puede pasar de `ABIERTO` directo a `RESUELTO`).
- `CERRADO` es estado terminal: no admite cambios de estado ni comentarios nuevos.
- Pasar a `RESUELTO` exige un comentario de solución no vacío; si falta, la operación falla completa (no cambia estado ni guarda nada).
- Toda transición se registra en el historial de forma inmutable.
- La reapertura (`RESUELTO` → `EN_PROCESO`) solo es válida si el ticket pasó a `RESUELTO` hace menos de 3 días.

**Consistencia entre estado, comentario e historial:** el cambio de estado se maneja en el backend dentro de una única transacción de base de datos que (1) valida la transición contra la máquina de estados, (2) si aplica, inserta el comentario de solución, (3) actualiza `ticket.estado` (y `ticket.fecha_resolucion` si el nuevo estado es `RESUELTO`), y (4) inserta el registro en `historial_estado`. Si cualquier paso falla, la transacción hace rollback completo — no queda estado a medias.

Como segunda línea de defensa, el esquema (`db/schema.sql`) refuerza a nivel de base de datos las invariantes que no deben violarse aunque exista un bug en el backend: el historial es inmutable (trigger que bloquea `UPDATE`/`DELETE`), no se pueden agregar comentarios a un ticket `CERRADO`, y `solicitante_id`/`agente_id` deben corresponder a usuarios con el rol correcto. La regla de reapertura (RESUELTO hace menos de 3 días) se valida en el backend comparando `now()` contra `ticket.fecha_resolucion`.

## 6. API REST (endpoints mínimos)

Base path: `/api`.

| Operación | Método y ruta | Notas |
|---|---|---|
| Crear ticket | `POST /api/tickets` | Validación de entrada. Nace en estado `ABIERTO`. |
| Listar tickets | `GET /api/tickets?estado=&prioridad=&page=&size=` | Filtros por estado y prioridad (combinables), paginación server-side, total de registros en la respuesta. |
| Consultar ticket | `GET /api/tickets/{id}` | Detalle con comentarios e historial de estados. |
| Cambiar estado | `PATCH /api/tickets/{id}/estado` | Body: `{ estadoNuevo, autorId, comentario? }`. Aplica la máquina de estados de la sección 5; `comentario` es obligatorio solo si `estadoNuevo` es `RESUELTO`. |
| Agregar comentario | `POST /api/tickets/{id}/comentarios` | Body: `{ autorId, texto }`. Rechazado si el ticket está `CERRADO`. |
| Listar usuarios | `GET /api/usuarios?rol=` | No exigido por el enunciado; se agregó de solo lectura para poblar el selector de "usuario actual" y los formularios del frontend (catálogo precargado, sin gestión — ver sección 8). |

Formato de error, uniforme en toda la API (`ai.fideia.tickets.dto.ErrorResponse` / `GlobalExceptionHandler`):

```json
{ "codigo": "TRANSICION_INVALIDA", "mensaje": "No se puede pasar de ABIERTO a RESUELTO", "detalles": [], "timestamp": "..." }
```

| Caso | Código | HTTP |
|---|---|---|
| Body invalido (campos faltantes, tipos incorrectos, JSON malformado) | `VALIDACION` | 400 |
| Recurso inexistente (ticket o usuario) | `RECURSO_NO_ENCONTRADO` | 404 |
| Método HTTP no soportado en la ruta | `METODO_NO_SOPORTADO` | 405 |
| Transición de estado no permitida por la máquina de estados (incluida la ventana de reapertura) | `TRANSICION_INVALIDA` | 409 |
| Regla de negocio violada (comentario de solución vacío al resolver, comentario sobre ticket `CERRADO`, usuario con rol incorrecto) | `REGLA_NEGOCIO` | 422 |
| Error no anticipado | `ERROR_INTERNO` | 500 |

## 7. Decisiones de diseño

- **Enums nativos de PostgreSQL** para `prioridad`, `estado` de ticket y `rol` de usuario, en vez de `VARCHAR` + `CHECK`: el motor rechaza valores fuera del dominio sin validación adicional y el esquema documenta el dominio de valores directamente.
- **Catálogo `usuario` único con columna `rol`** (`SOLICITANTE` / `AGENTE`) en vez de dos tablas separadas: el enunciado no exige comportamientos distintos entre ambos roles más allá de a qué campo del ticket pueden asociarse, así que una tabla con un enum evita duplicar estructura.
- **`ticket.fecha_resolucion`** como columna dedicada (en vez de derivarla con una subconsulta al historial en cada request) para que la regla de reapertura (RESUELTO hace menos de 3 días) sea una comparación directa e indexable.
- **`comentario.es_solucion`** para distinguir el comentario obligatorio de solución del resto de comentarios normales en la vista de detalle.
- **Restricciones de negocio duplicadas en dos capas** (backend + triggers de base de datos) para la inmutabilidad del historial, el bloqueo de comentarios en tickets `CERRADO` y la integridad de roles: el backend es la fuente de verdad y responde con el error HTTP correcto, pero la base de datos no depende únicamente de que el backend se comporte bien (ver sección 5 y `db/schema.sql`).
- **`TicketEstadoMachine` sin dependencias de Spring ni de la base de datos**: la máquina de estados es una clase con métodos estáticos puros, para poder probarla con JUnit simple sin levantar contexto de Spring ni base de datos (ver `backend/src/test/java/.../TicketEstadoMachineTest.java`).
- **Manejo de errores centralizado en `GlobalExceptionHandler`** (`@RestControllerAdvice`): traduce cada excepción de negocio a un código HTTP y un `ErrorResponse` uniforme (formato y tabla completa en la sección 6). Se manejan explícitamente, además de las excepciones de negocio, el body JSON malformado (400) y el método HTTP no soportado (405) — sin esto, un `@ExceptionHandler(Exception.class)` genérico los habría convertido incorrectamente en 500.
- **Sin locking optimista (`@Version`) en `Ticket`**: dos cambios de estado concurrentes sobre el mismo ticket no están cubiertos. Fuera del alcance explícito de esta prueba (ver sección 10, "qué quedó pendiente").
- **Consulta de reporte (`db/reporte.sql`) construida desde una base `CROSS JOIN` de agentes × prioridades, no desde un `GROUP BY` directo sobre `ticket`**: agrupar directamente sobre `ticket` haría desaparecer a un agente sin tickets asignados, porque no habría ninguna fila suya de la cual partir. Se arma primero el universo completo de combinaciones (agente, prioridad) y se hace `LEFT JOIN` contra los tickets no cerrados, para que un agente con 0 tickets siga apareciendo con conteo 0. Los tickets sin agente asignado se listan aparte (`UNION ALL`, etiqueta "Sin asignar") en vez de omitirlos.

## 8. Supuestos asumidos

- No se implementa autenticación/autorización real: el usuario actual se selecciona de una lista o se fija por configuración.
- No hay despliegue en la nube, contenedores ni CI/CD.
- No se exige diseño visual elaborado, responsive fino ni accesibilidad avanzada.
- No se implementa cobertura de pruebas amplia, notificaciones, adjuntos ni reportes gráficos.
- El catálogo de usuarios (solicitantes/agentes) se precarga mediante seed, sin gestión de usuarios.

_(Se irán agregando aquí los supuestos adicionales que surjan durante la implementación, según lo pide el enunciado en la sección 2.4.)_

## 9. Índices y su justificación

Definidos en `db/schema.sql`:

| Índice | Tabla / columnas | Qué consulta acelera |
|---|---|---|
| `idx_ticket_estado_prioridad` | `ticket (estado, prioridad)` | `GET /tickets` filtrando por estado solo, o por estado + prioridad combinados (el prefijo `estado` cubre ambos casos). |
| `idx_ticket_prioridad` | `ticket (prioridad)` | `GET /tickets` filtrando solo por prioridad (no cubierto por el índice compuesto, cuyo primer campo es `estado`). |
| `idx_ticket_agente_estado` | `ticket (agente_id, estado)` | La consulta de reporte de la sección 3.5: agrupa por agente los tickets no cerrados. |
| `idx_ticket_fecha_creacion` | `ticket (fecha_creacion DESC)` | Orden por defecto del listado (más recientes primero) combinado con paginación. |
| `idx_comentario_ticket_id` | `comentario (ticket_id)` | Cargar los comentarios de un ticket en la vista de detalle. |
| `idx_historial_ticket_id` | `historial_estado (ticket_id)` | Cargar el historial de estados de un ticket en la vista de detalle. |

## 10. Qué quedó pendiente

Completado, en el orden sugerido por el enunciado: (1) máquina de estados e historial, (2) esquema de BD y consulta de reporte, (3) endpoints de listado/detalle (y el resto de la API), (4) README, (5) frontend Angular (listado con filtros/paginación server-side y detalle con comentarios, historial y cambio de estado). Queda pendiente:

- **Locking optimista** (`@Version` en `Ticket`): dos cambios de estado concurrentes sobre el mismo ticket no están cubiertos; el enunciado no lo exige para esta prueba, pero en un sistema real con varios agentes trabajando a la vez valdría la pena.
- **Rate limiting / paginación por cursor**: mencionados en el apéndice (sección 14) como buenas prácticas a mayor escala; la paginación simple por página/tamaño alcanza para el volumen de este ejercicio.
- **Formulario de creación de ticket**: el enunciado (sección 3.6) solo exige dos vistas (listado y detalle); se agregó igual un formulario mínimo embebido en el listado para poder probar `POST /api/tickets` desde la UI, sin invertir tiempo en una vista dedicada.

## 11. Uso de IA

Se usó **Claude Code** para generar la documentación inicial de este README a partir del análisis del enunciado de la prueba técnica (`Prueba_Tecnica_Fullstack_Fideia.docx`), incluyendo la estructura de secciones, el resumen del modelo de dominio, la máquina de estados y la tabla de endpoints. El stack tecnológico (Spring Boot, Angular, PostgreSQL) fue decidido por el desarrollador.

_Esta sección se ampliará durante la implementación, detallando qué partes del código se generaron con asistencia de IA, para qué se usó y en qué proporción aproximada, tal como exige la sección 2.3 del enunciado._

## 12. Fuera de alcance

- Autenticación y autorización reales.
- Despliegue en la nube, contenedores o CI/CD.
- Diseño visual elaborado, responsive fino o accesibilidad avanzada.
- Cobertura de pruebas amplia, notificaciones, adjuntos, reportes gráficos.

## 13. Entregables

- [ ] Repositorio Git con historial de commits descriptivos.
- [ ] README.md (este archivo).
- [x] Scripts SQL: DDL (`db/schema.sql`), datos de prueba (`db/seed.sql`, 18 tickets) y consulta de reporte (`db/reporte.sql`).
- [x] Código fuente: backend (`/backend`), frontend (`/frontend`) y 5 pruebas automatizadas sobre la máquina de estados (`TicketEstadoMachineTest`, ≥2 exigidas).
- [ ] ENSAYO.md (Parte B).

**Plazo de entrega:** jueves 3 de septiembre de 2026, 12:00 m (hora Colombia), a `luis.espitia@fideia.ai`.

## 14. Apéndice — Modelo extendido de referencia (fuera del alcance de esta prueba)

> Esta sección documenta cómo se vería un sistema de mesa de ayuda completo (estilo Zendesk/Freshdesk), a modo de referencia para justificar decisiones de diseño y para la sección "qué quedó pendiente" (10). **No es el alcance a construir**: varios elementos aquí descritos (adjuntos, notificaciones, reportes gráficos, portal de cliente, autenticación/roles reales, SLAs) están explícitamente excluidos por la sección 12 (Fuera de alcance) del enunciado. El MVP de esta prueba se limita a las secciones 4–6 de este README.

### 14.1 Modelo de datos extendido

El núcleo de un sistema completo sigue siendo la entidad **Ticket**, pero con más campos y entidades relacionadas de las que exige esta prueba:

- **Ticket**: id, título, descripción, estado (`open` / `pending` / `on_hold` / `resolved` / `closed` / `reopened`), prioridad (`low` / `medium` / `high` / `urgent`), categoría/tipo, canal de origen (email, web, chat, API), solicitante, agente asignado, equipo, etiquetas, fechas (creación, actualización, vencimiento de SLA) y campos personalizados.
- **Comentarios**: separando respuestas públicas de notas internas (visibles solo para agentes).
- **Adjuntos**: archivos asociados a un ticket o comentario.
- **Historial de estado / Log de auditoría**: quién cambió qué y cuándo — imprescindible para trazabilidad (equivalente al "Historial de estado" de la sección 4 de este README, pero aquí ampliado a auditoría general, no solo de estado).
- **Usuarios**: con roles (cliente, agente, admin).
- **Equipos**: agrupación de agentes.
- **Políticas de SLA**: tiempos de primera respuesta y de resolución según prioridad.
- **Categorías/Etiquetas**.
- **Macros / respuestas predefinidas**: para agilizar el trabajo de los agentes.

**Punto clave de arquitectura** (este sí aplica directamente a esta prueba, ver sección 5): el estado del ticket se modela como una **máquina de estados explícita** —no como un campo de texto libre— con transiciones válidas definidas (por ejemplo, no se puede pasar de `closed` a `in_progress` sin pasar antes por `reopened`). Esto evita inconsistencias y facilita los reportes.

### 14.2 Vistas recomendadas (frontend extendido)

- **Dashboard/inicio**: KPIs como tickets abiertos, SLA en riesgo, tiempo promedio de resolución, tickets por agente/equipo.
- **Bandejas de tickets**: listas filtrables — "mis tickets", "sin asignar", "por equipo", "por prioridad", "vencidos" — con filtros combinables y ordenamiento.
- **Detalle de ticket**: hilo de conversación, notas internas, historial de cambios, panel lateral con metadatos editables (prioridad, asignación, etiquetas).
- **Formulario de creación**: tanto para agentes como para un portal de autoservicio del cliente.
- **Portal de cliente** (opcional pero recomendable): seguimiento de sus propios tickets, base de conocimiento/FAQ para reducir volumen de tickets repetitivos.
- **Administración**: gestión de usuarios, equipos, categorías, SLAs, macros, reglas de automatización (ej. asignación automática, escalamiento).
- **Reportes/analítica**: tendencias, cumplimiento de SLA, satisfacción del cliente (CSAT).

*(Las dos vistas exigidas por esta prueba — listado y detalle de ticket, sección 6 de este README — son un subconjunto mínimo de "Bandejas de tickets" y "Detalle de ticket".)*

### 14.3 Diseño de API REST extendido

Estructura típica versionada (`/api/v1/...`):

- `POST /auth/login`, `POST /auth/refresh` — autenticación (JWT/OAuth2).
- `GET /tickets` (con filtros por query params: `status`, `priority`, `assignee`, `team`, `tags`, paginación) / `POST /tickets`.
- `GET /tickets/{id}` / `PATCH /tickets/{id}` / `DELETE /tickets/{id}`.
- `POST /tickets/{id}/comments` / `GET /tickets/{id}/comments`.
- `POST /tickets/{id}/attachments`.
- `PATCH /tickets/{id}/status` — transición controlada de estado (equivalente al endpoint "Cambiar estado" de la sección 6).
- `PATCH /tickets/{id}/assign`.
- `GET`/`POST /users`, `/teams`, `/categories`, `/tags`, `/sla-policies`.
- `GET /reports/...` para analítica.
- **Webhooks salientes** (`ticket.created`, `ticket.updated`, `ticket.resolved`) para integraciones.

**Buenas prácticas generales** (algunas aplicables al MVP, otras solo relevantes a escala):

- Paginación por cursor para listas grandes (el MVP usa paginación simple por página/tamaño, suficiente para el alcance actual).
- Filtrado/ordenamiento vía query params (sí aplica al MVP: filtros por estado y prioridad en `GET /tickets`).
- Idempotency keys en creación de tickets, para evitar duplicados por reintentos.
- Rate limiting.
- RBAC bien definido (cliente solo ve sus tickets, agente ve los de su equipo, admin ve todo) — fuera de alcance en el MVP, que solo selecciona el usuario actual de una lista (sección 8, supuesto de autenticación).
