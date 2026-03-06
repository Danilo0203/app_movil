# Planificación: Offline-first y Sincronización

Este documento define la planificación de la **Épica 3: Offline-first + sincronización al reconectar** para el proyecto `app_creditos`.

## Objetivo

Permitir que la app móvil funcione sin internet para captura/edición de datos y que, al recuperar conexión, sincronice de forma automática, confiable y auditable con la API.

## Alcance

- Mobile (`apps/mobile`): almacenamiento local, cola de operaciones, motor de sync, estados UI y manejo de conflictos.
- Backend (`apps/api`): idempotencia, anti-duplicados y soporte a sincronización segura.

## Tareas de la Épica 3

### 1) Diseñar almacenamiento local offline

**Checklist**

- [ ] Seleccionar motor local (`Hive`, `Isar` o `SQLite`).
- [ ] Definir estructuras para formularios locales.
- [ ] Definir estructuras para cola de operaciones pendientes.
- [ ] Definir versionado de esquema local (migraciones locales).
- [ ] Definir política de limpieza de datos temporales.

**Criterio de aceptación**

- Se puede crear y editar información local sin internet y persiste al cerrar/reabrir app.

### 2) Implementar Outbox Queue (cola de sincronización)

**Checklist**

- [ ] Registrar operaciones `CREATE`, `UPDATE`, `DELETE`, `SUBMIT`.
- [ ] Guardar por operación: `id`, `entityId`, `payload`, `createdAt`.
- [ ] Guardar control de reintentos: `retryCount`, `status`, `lastError`.
- [ ] Mantener orden de procesamiento por timestamp/secuencia.
- [ ] Persistencia de cola entre reinicios de app.

**Criterio de aceptación**

- Toda acción ejecutada sin conexión queda almacenada en una cola persistente.

### 3) Detector de conectividad + reachability real

**Checklist**

- [ ] Integrar `connectivity_plus` para estado de red.
- [ ] Implementar verificación real contra backend (ping/health).
- [ ] Diferenciar estados: sin red, red sin internet, online real.
- [ ] Exponer estado de conectividad a capa de presentación.

**Criterio de aceptación**

- La app distingue correctamente entre tener red local y tener acceso real al backend.

### 4) Motor de sincronización automática

**Checklist**

- [ ] Disparar sincronización al recuperar conectividad.
- [ ] Procesar cola en orden y de forma transaccional por item.
- [ ] Implementar reintentos con backoff exponencial.
- [ ] Definir máximo de reintentos y estado final de error.
- [ ] Evitar múltiples sincronizaciones concurrentes.

**Criterio de aceptación**

- Las operaciones pendientes se sincronizan automáticamente sin intervención manual al reconectar.

### 5) Manejo de idempotencia y duplicados en API

**Checklist**

- [ ] Enviar `clientRequestId` único por operación desde móvil.
- [ ] Persistir `clientRequestId` en backend para deduplicación.
- [ ] Responder de forma idempotente ante reintentos.
- [ ] Cubrir casos de timeout con reintento seguro.

**Criterio de aceptación**

- Reintentos por red inestable no generan registros duplicados.

### 6) Resolución de conflictos

**Checklist**

- [ ] Definir estrategia: `last-write-wins` o control por versión.
- [ ] Detectar conflictos de actualización/borrado remoto.
- [ ] Marcar items en conflicto en almacenamiento local.
- [ ] Mostrar opción de resolver (reintentar, sobrescribir o descartar).

**Criterio de aceptación**

- Un conflicto se detecta, se visualiza y el usuario puede resolverlo.

### 7) Estados UI de sincronización

**Checklist**

- [ ] Mostrar estado por item: `Pendiente`, `Sincronizando`, `Sincronizado`, `Error`.
- [ ] Mostrar contador global de pendientes.
- [ ] Agregar acción manual `Reintentar`.
- [ ] Mostrar errores legibles para usuario.

**Criterio de aceptación**

- El usuario entiende qué está pendiente, qué falló y qué ya se sincronizó.

### 8) Soporte offline para adjuntos/evidencias

**Checklist**

- [ ] Guardar rutas locales de imágenes/adjuntos.
- [ ] Encolar subida de archivos en reconexión.
- [ ] Asociar archivo local con operación correspondiente.
- [ ] Limpiar temporales tras confirmación de sincronización.
- [ ] Manejar faltantes de archivo local con error recuperable.

**Criterio de aceptación**

- Evidencias capturadas sin internet se suben al backend al reconectar.

### 9) Sincronización en ciclo de vida de app

**Checklist**

- [ ] Ejecutar sync al abrir app.
- [ ] Ejecutar sync al volver a foreground.
- [ ] Ejecutar sync por intervalo (timer controlado).
- [ ] Evitar consumo excesivo de batería/datos.

**Criterio de aceptación**

- La cola no queda estancada aunque el usuario no navegue entre pantallas.

### 10) Observabilidad de sincronización

**Checklist**

- [ ] Registrar logs de cada operación sincronizada.
- [ ] Métricas mínimas: pendientes, errores, tiempo medio de sync.
- [ ] Estandarizar códigos de error de sincronización.
- [ ] Preparar trazabilidad para soporte y QA.

**Criterio de aceptación**

- Se puede auditar por qué una sincronización falló y en qué paso.

### 11) QA de escenarios offline/online

**Checklist**

- [ ] Pruebas en modo avión.
- [ ] Pruebas con reconexión intermitente.
- [ ] Pruebas con reconexión tardía.
- [ ] Pruebas con conflicto de datos.
- [ ] Pruebas de reintentos y no-duplicación.
- [ ] Matriz de evidencia de pruebas por escenario.

**Criterio de aceptación**

- La matriz de pruebas offline/online está aprobada y sin bloqueantes críticos.

## Dependencias sugeridas

- Almacenamiento local y cola antes del motor de sync.
- Idempotencia backend antes de activar reintentos agresivos.
- Estados UI y observabilidad antes de cierre de QA final.

## Definición de Hecho (DoD)

- Flujo offline funcional para creación/edición/envío.
- Sincronización automática estable al reconectar.
- Sin duplicados por reintentos.
- Conflictos detectables y resolubles.
- Evidencia de QA aprobada para escenarios críticos de conectividad.
