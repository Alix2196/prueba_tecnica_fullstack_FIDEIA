# Sistema de gestión de tickets — Mesa de ayuda (Prueba Técnica Fullstack FIDEIA)

Núcleo mínimo de una mesa de ayuda interna: gestión del ciclo de vida de tickets (creación, cambio de estado, comentarios e historial de auditoría), expuesto vía API REST y consumido por un frontend con filtros y paginación server-side.

## 1. Stack tecnológico

| Capa | Tecnología | Por qué |
|---|---|---|
| Backend | Java + Spring Boot | Tipado fuerte, buen soporte nativo para transacciones (clave para la operación compuesta estado + comentario + historial), validación declarativa (Bean Validation) y manejo explícito de excepciones vía `@ControllerAdvice`. |
| Frontend | Angular | Estructura opinada (servicios, componentes, RxJS) que facilita modelar explícitamente los estados de carga/vacío/error exigidos por el enunciado. |
| Base de datos | PostgreSQL | Soporte nativo de tipos `ENUM`, restricciones `CHECK` para validar transiciones a nivel de esquema, e índices parciales/compuestos útiles para la consulta de reporte. |

> Detalle de versiones y justificación ampliada: pendiente de completar a medida que se implementa (ver sección 7).

## 2. Estructura del repositorio (planeada)

```
/backend    Spring Boot — API REST, lógica de negocio, pruebas
/frontend   Angular — listado y detalle de tickets
/db         Scripts DDL, datos de prueba (seed) y consulta de reporte
ENSAYO.md   Parte B — ensayo sobre uso de Claude Code
README.md   Este archivo
```

## 3. Cómo levantar el proyecto

_Pendiente — se documentará aquí el paso a paso (requisitos, variables de entorno, comandos) a medida que el backend, la base de datos y el frontend queden implementados._

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

> Cómo se garantiza la consistencia entre cambio de estado, comentario e historial (transaccionalidad, etc.): _pendiente de documentar durante la implementación._

## 6. API REST (endpoints mínimos)

| Operación | Método | Notas |
|---|---|---|
| Crear ticket | `POST` | Validación de entrada. Nace en estado `ABIERTO`. |
| Listar tickets | `GET` | Filtros por estado y prioridad, paginación server-side, total de registros en la respuesta. |
| Consultar ticket | `GET` | Detalle con comentarios e historial de estados. |
| Cambiar estado | `PATCH`/`POST` | Aplica la máquina de estados de la sección 5. |
| Agregar comentario | `POST` | Rechazado si el ticket está `CERRADO`. |

Formato de error: pendiente (código, mensaje entendible, status HTTP correcto para entrada inválida / recurso inexistente / transición no permitida).

## 7. Decisiones de diseño

_Pendiente — se documentará aquí cada decisión relevante (p. ej. cómo se garantiza la atomicidad de la transición de estado, estrategia de validación, manejo de errores) a medida que se tomen durante la implementación._

## 8. Supuestos asumidos

- No se implementa autenticación/autorización real: el usuario actual se selecciona de una lista o se fija por configuración.
- No hay despliegue en la nube, contenedores ni CI/CD.
- No se exige diseño visual elaborado, responsive fino ni accesibilidad avanzada.
- No se implementa cobertura de pruebas amplia, notificaciones, adjuntos ni reportes gráficos.
- El catálogo de usuarios (solicitantes/agentes) se precarga mediante seed, sin gestión de usuarios.

_(Se irán agregando aquí los supuestos adicionales que surjan durante la implementación, según lo pide el enunciado en la sección 2.4.)_

## 9. Índices y su justificación

_Pendiente — se documentará cada índice creado y qué consulta busca acelerar, una vez definido el DDL final._

## 10. Qué quedó pendiente

_Pendiente — se completará al final del ejercicio, priorizando según el orden sugerido: (1) máquina de estados e historial, (2) esquema de BD y consulta de reporte, (3) endpoints de listado/detalle, (4) README, (5) frontend completo._

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
- [ ] Scripts SQL: DDL, datos de prueba (≥15 tickets) y consulta de reporte.
- [ ] Código fuente: backend, frontend y al menos dos pruebas automatizadas sobre la máquina de estados.
- [ ] ENSAYO.md (Parte B).

**Plazo de entrega:** jueves 3 de septiembre de 2026, 12:00 m (hora Colombia), a `luis.espitia@fideia.ai`.
