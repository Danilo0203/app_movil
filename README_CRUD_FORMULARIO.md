# Planificación: CRUD de Formulario

Este documento define la planificación de la **Épica 2: CRUD de formulario y guardado en base de datos** para el proyecto `app_creditos`.

## Objetivo

Implementar un módulo completo de formularios con:

- Persistencia en PostgreSQL (Prisma).
- API CRUD segura (NestJS + JWT).
- Flujo de envío del formulario con estado.
- Pantallas Flutter para operación end-to-end.
- Pruebas E2E de los casos principales.

## Alcance

- Backend (`apps/api`): modelo, migración, endpoints, validaciones y pruebas.
- Mobile (`apps/mobile`): pantallas, integración API y UX de envío.

## Tareas de la Épica 2

### 1) Definir modelo de datos del formulario (Prisma)

**Checklist**

- [ ] Crear tabla `FormSubmission` (o nombre final acordado).
- [ ] Definir campos del formulario.
- [ ] Definir estados: `DRAFT`, `SUBMITTED`.
- [ ] Agregar `createdAt` y `updatedAt` (y `submittedAt` si aplica).
- [ ] Relación con `User` (propietario del formulario).
- [ ] Crear y versionar migración en `prisma/migrations`.

**Criterio de aceptación**

- La migración aplica correctamente en PostgreSQL y el esquema queda disponible para uso desde Prisma Client.

### 2) Crear endpoints CRUD del formulario (NestJS)

**Checklist**

- [ ] `POST /forms`
- [ ] `GET /forms`
- [ ] `GET /forms/:id`
- [ ] `PATCH /forms/:id`
- [ ] `DELETE /forms/:id`
- [ ] `POST /forms/:id/submit` (enviar formulario)
- [ ] Proteger endpoints con `JwtAuthGuard`.
- [ ] Implementar DTOs y validaciones con `class-validator`.
- [ ] Restringir acceso por propietario (`userId`).

**Criterio de aceptación**

- Todos los endpoints están protegidos con JWT, validan payloads con DTOs y respetan autorización por usuario.

### 3) Validaciones de negocio del formulario

**Checklist**

- [ ] Validar campos obligatorios.
- [ ] Validar formatos (correo, números, longitudes, fechas, etc.).
- [ ] Bloquear edición cuando estado sea `SUBMITTED`.
- [ ] Definir reglas para eliminación (por ejemplo, solo en `DRAFT`).
- [ ] Estandarizar errores HTTP y mensajes claros.

**Criterio de aceptación**

- La API rechaza datos inválidos con errores claros y consistentes.

### 4) Pantallas Flutter para CRUD del formulario

**Checklist**

- [ ] Pantalla de listado de formularios.
- [ ] Pantalla de creación de formulario.
- [ ] Pantalla de detalle.
- [ ] Pantalla de edición.
- [ ] Acción de eliminación con confirmación.
- [ ] Integración con `ApiClient`.
- [ ] Estados UI: loading, vacío, error y éxito.

**Criterio de aceptación**

- El flujo completo de listar, crear, ver, editar y eliminar funciona desde la app contra la API.

### 5) Flujo "Enviar formulario"

**Checklist**

- [ ] Botón `Enviar` visible para formularios `DRAFT`.
- [ ] Confirmación previa al envío.
- [ ] Llamada a `POST /forms/:id/submit`.
- [ ] Cambio de estado en UI a `SUBMITTED`.
- [ ] Feedback visual (snackbar/alerta) para éxito o error.
- [ ] Bloqueo de edición luego de enviado.

**Criterio de aceptación**

- Al enviar, el registro queda persistido en DB con estado `SUBMITTED` y no permite edición posterior.

### 6) Pruebas E2E del CRUD

**Checklist**

- [ ] Caso crear formulario.
- [ ] Caso editar formulario.
- [ ] Caso eliminar formulario.
- [ ] Caso enviar formulario.
- [ ] Casos negativos (sin token, payload inválido, edición de `SUBMITTED`).

**Criterio de aceptación**

- Los casos principales y negativos definidos están cubiertos y pasando en ejecución E2E.

## Dependencias sugeridas

- Modelo Prisma listo antes de endpoints.
- Endpoints listos antes de pantallas Flutter.
- Reglas de negocio listas antes de pruebas E2E finales.

## Definición de Hecho (DoD)

- Migraciones versionadas y aplicables.
- Endpoints documentados y protegidos.
- Flujo funcional en móvil validado manualmente.
- E2E verdes para escenarios críticos.
- Sin regresiones en módulos existentes (auth, challenges, submissions, ranking).
