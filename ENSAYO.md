# Ensayo — Uso de Claude y Claude Code (Parte B)

> Extensión objetivo: 700–1.000 palabras. Escribir en primera persona, con ejemplos concretos propios (no genéricos). Contenido de autoría propia; la IA solo puede usarse para corregir redacción, no para generar el criterio ni los ejemplos.

## 1. Los primeros 90 minutos

_¿Cómo usarías Claude Code para entender un sistema que no conoces (la API documental de ~40.000 líneas)? Sé concreto: qué le pedirías, en qué orden, y qué harías con lo que responde._

Hice la lectura de la prueba analice el comienza y las tecnologias ha implear y como lo iba a hacer luego se creo el repositorio en el Git luego se clona el repositorio se abre el archivo con viasual estudio code se suben cambios y se crea la documentacion inicial donde se toma la desicion de las herramientas tecnologias a implementar, como son para base de datos posgrest porque es opensource y no tiene interferencias con la conexion a la IA, Backend con java spring boot porque es interprice y es un framework robusto por la parte del frontend elegi angular por que estoy mas familiarizada con esta tecnologia me parece mas organizada ella tambien es interprice, mejore la documentacion que tenia inicalmente basandome en investigaciones

## 2. Preparación del contexto

_¿Cómo dejarías el proyecto configurado para que la asistencia sea consistente en el tiempo (archivo de contexto del proyecto, convenciones, comandos frecuentes, subagentes, skills, conexiones a herramientas externas)?_

## 3. Delegación

_Para las dos tareas del sprint (módulo de notificaciones, error de concurrencia que duplica registros), ¿qué le delegarías a Claude Code y qué no le delegarías nunca? Justifica el límite. ¿Cambia tu respuesta entre las dos tareas? ¿Por qué?_

## 4. Verificación

_¿Cómo compruebas que el código generado es correcto, seguro y mantenible antes de abrir el PR? Menciona riesgos concretos: APIs inexistentes, dependencias inventadas, código que compila pero no hace lo que dice, credenciales o datos sensibles en el prompt._

## 5. Tu experiencia real

_Un caso propio donde un asistente de IA te ahorró trabajo de verdad, y otro donde te dio una respuesta equivocada: cómo lo detectaste y qué cambiaste en tu forma de trabajar después._

## 6. Esta misma prueba

_Cómo usaste (o no) Claude en la Parte A: qué le pediste, qué corregiste de lo que te entregó y qué escribiste por tu cuenta._

Se realizo la investigacion y la mejora en la documentacion sobre el sistema de tickets en el cual se implemento el diseño de las Apis, las vistas del frontend y el modelo de datos, se le solicita a la IA que cree la base de datos bajo la documentacion, le solicite ayuda para crear la base inicial del backend, se utiliza una base de datos en docker para alojar la persistencia de los datos.
