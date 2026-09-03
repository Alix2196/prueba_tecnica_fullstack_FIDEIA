# Ensayo — Uso de Claude y Claude Code (Parte B)

> Extensión objetivo: 700–1.000 palabras. Escribir en primera persona, con ejemplos concretos propios (no genéricos). Contenido de autoría propia; la IA solo puede usarse para corregir redacción, no para generar el criterio ni los ejemplos.

## 1. Los primeros 90 minutos

_¿Cómo usarías Claude Code para entender un sistema que no conoces (la API documental de ~40.000 líneas)? Sé concreto: qué le pedirías, en qué orden, y qué harías con lo que responde._

Hice la lectura de la prueba analice el comienza y las tecnologias ha implear y como lo iba a hacer luego se creo el repositorio en el Git luego se clona el repositorio se abre el archivo con viasual estudio code se suben cambios y se crea la documentacion inicial donde se toma la desicion de las herramientas tecnologias a implementar, como son para base de datos posgrest porque es opensource y no tiene interferencias con la conexion a la IA, Backend con java spring boot porque es interprice y es un framework robusto por la parte del frontend elegi angular por que estoy mas familiarizada con esta tecnologia me parece mas organizada ella tambien es interprice, mejore la documentacion que tenia inicalmente basandome en investigaciones

## 2. Preparación del contexto

_¿Cómo dejarías el proyecto configurado para que la asistencia sea consistente en el tiempo (archivo de contexto del proyecto, convenciones, comandos frecuentes, subagentes, skills, conexiones a herramientas externas)?_

Mira yo comenzaria creando mi archivo claude que se aloja en la raiz del proyecto este archivo contiene para que la pueda leer visual contiene la descripcion del proyecto el stack tecnologico o las tecnologias que utilice, tambien contiene la arquitectura del proyecto este lo crea directamente la IA es un resumen total del proyecto, colocando delimitantes de los linters y especificando las reglas del codigo, se centraliza comandos y simples como los de arranque, con claude code como subagente conexiones de base de datos y las tecnologias con sus versiones herramientas de prueba como lo son posman. 

## 3. Delegación

_Para las dos tareas del sprint (módulo de notificaciones, error de concurrencia que duplica registros), ¿qué le delegarías a Claude Code y qué no le delegarías nunca? Justifica el límite. ¿Cambia tu respuesta entre las dos tareas? ¿Por qué?_

Bueno que le delegaria le delegaria la deneracion de  la estructura de la base con los dtos la infraestructura del servicio en tareas repetititivas como modulos y notificaciones el analisis teorico preliminar  y las sugerencias de posibles puntos de fallo para los problemas complejos como errores, la reduccion de documentacion inicial en las plantillas del README apartir del analisis del requerimientio, y que no le delegaria la definicion de las reglas de negocio criticas como los disparadores de las notificaciones ni la implementacion directa de soluciones.


## 4. Verificación

_¿Cómo compruebas que el código generado es correcto, seguro y mantenible antes de abrir el PR? Menciona riesgos concretos: APIs inexistentes, dependencias inventadas, código que compila pero no hace lo que dice, credenciales o datos sensibles en el prompt._

Para comprobar que el código generado por la IA es correcto, seguro y mantenible antes de abrir el PR, ejecuto y pruebo localmente para evitar código que solo compila pero falla en la lógica, reviso exhaustivamente las importaciones y dependencias para detectar APIs o librerías inventadas, y mantengo un control estricto para nunca incluir datos sensibles en los prompts. Finalmente, audito que la solución cumpla con los patrones arquitectónicos y las reglas de transaccionalidad del proyecto sin comprometer la seguridad.

## 5. Tu experiencia real

_Un caso propio donde un asistente de IA te ahorró trabajo de verdad, y otro donde te dio una respuesta equivocada: cómo lo detectaste y qué cambiaste en tu forma de trabajar después._

Bueno ella comienza a delirar a veces son contradictorias o vuelven a consultar en los mismos archivos que ya a modificado tambien hablan redundancias y hablanm del codigo cuando no se le solicito esa informacion, Un caso real donde la IA me ahorró trabajo de verdad fue al generar rápidamente la estructura base y la documentación inicial de la mesa de ayuda, permitiéndome enfocarme en la lógica compleja. En contraste, me dio una respuesta equivocada al proponer un enfoque de concurrencia ineficiente para evitar duplicados, lo cual detecté al realizar pruebas locales y revisar críticamente la lógica transaccional.

## 6. Esta misma prueba

_Cómo usaste (o no) Claude en la Parte A: qué le pediste, qué corregiste de lo que te entregó y qué escribiste por tu cuenta._

Se realizo la investigacion y la mejora en la documentacion sobre el sistema de tickets en el cual se implemento el diseño de las Apis, las vistas del frontend y el modelo de datos, se le solicita a la IA que cree la base de datos bajo la documentacion, le solicite ayuda para crear la base inicial del backend, se utiliza una base de datos en docker para alojar la persistencia de los datos, se crea la configuracion del posman para probar las apis,se realiza la creacion de el frontend con las vistas, se configura el frontend para que corra en el puerto 4200 para poder ver la vista del frontend se corre el puerto en el puerto para poder visualizar la vista y realizar pruebas.
