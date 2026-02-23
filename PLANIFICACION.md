# PLANIFICACION.md — Monorepo (Flutter + NestJS + PostgreSQL)

## Prompt para Cursor/Codex

Necesito que conviertas mi proyecto existente ubicado en la carpeta raíz **`app_creditos/`** en un **monorepo** con esta estructura:
app_creditos/
apps/
mobile/ (Flutter existente, movido desde la raíz)
api/ (Backend NestJS nuevo)
.gitignore
README.md


Actualmente el proyecto Flutter está en la raíz (tiene `android/`, `ios/`, `lib/`, `pubspec.yaml`, etc.). Quiero que **TODO lo de Flutter** se mueva a **`apps/mobile/`** sin romper el proyecto.

---

## Requisitos y contexto
- Quiero usar **Node.js** para backend con **NestJS** (TypeScript).
- Aún **no tengo instalado NestJS**.
- La base de datos será **PostgreSQL local**.
- Aún **no tengo instalado PostgreSQL**.
- Usaré **DBeaver** para crear la base de datos local.
- El repo se subirá a **GitHub**, así que:
  - No se debe subir `node_modules`, `dist`, `build`, `.dart_tool`, `.env`, etc.
  - Sí se deben subir archivos necesarios como `pubspec.lock` (es app) y migraciones de Prisma.

---

## Objetivo técnico

### Flutter (apps/mobile)
- Mover el proyecto Flutter existente de la raíz a `apps/mobile/`.
- Asegurar que siga funcionando con:
  - `cd apps/mobile && flutter pub get && flutter run`

### Backend (apps/api)
- Crear un backend nuevo en `apps/api/` con:
  - **NestJS + TypeScript**
  - **Prisma ORM**
  - **PostgreSQL**
  - Configuración por variables de entorno (`apps/api/.env`).
- Incluir:
  - `ConfigModule` para envs
  - `ValidationPipe` global
  - Un endpoint simple tipo `GET /health` para verificar que corre
  - Un recurso mínimo (ej: `User`) con Prisma (modelo con `id`, `email`, `createdAt`)
  - Migraciones de Prisma listas para versionar

---

## Reglas de Git/GitHub (MUY IMPORTANTE)
1) Crear un `.gitignore` en la raíz **del monorepo** que cubra:

- Flutter:
  - `.dart_tool/`
  - `build/`
  - `.idea/`
  - `.metadata`
  - `*.iml`
  - `.DS_Store`

- Node/Nest:
  - `apps/api/node_modules/`
  - `apps/api/dist/`
  - `apps/api/.env`
  - `apps/api/.env.*` (excepto `.env.example`)
  - logs

2) Crear `apps/api/.env.example` con variables requeridas.  
3) **NO** subir `.env` real.  
4) **SÍ** subir migraciones Prisma (`apps/api/prisma/migrations/**`).

---

## Pasos que debes ejecutar (en orden)

### A) Reestructuración monorepo
1) Crear `apps/`, `apps/mobile/`, `apps/api/`.
2) Mover TODO lo de Flutter desde la raíz hacia `apps/mobile/`:
   - incluir `android/ ios/ lib/ linux/ macos/ web/ windows/`
   - incluir `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.metadata`, `.dart_tool` (si existe)
   - NO mover cosas del nuevo backend
3) En la raíz deben quedar solo:
   - `apps/`
   - `.gitignore`
   - `README.md`

### B) Backend NestJS + Prisma
1) Crear NestJS en `apps/api/` usando la opción más práctica para alguien sin Nest instalado:
   - preferir `npx` (o instalar Nest CLI si hace sentido)
2) Agregar Prisma:
   - `prisma/schema.prisma` con provider PostgreSQL
   - modelo mínimo `User`
3) Agregar configuración `.env`:
   - `DATABASE_URL="postgresql://USER:PASSWORD@localhost:5432/app_creditos?schema=public"`
4) Agregar scripts y comandos:
   - `npm run start:dev`
   - `npx prisma migrate dev`
   - `npx prisma studio` (opcional)
5) Crear un endpoint `GET /health` que responda `{ status: "ok" }`.

### C) Documentación
Crear/actualizar `README.md` en la raíz con:
1) Requisitos:
   - Flutter SDK
   - Node.js LTS
   - PostgreSQL
   - DBeaver
2) Instalación de PostgreSQL (sección corta por OS: macOS / Windows / Linux)
3) Cómo crear DB en DBeaver:
   - nombre sugerido: `app_creditos`
   - usuario/password (ejemplo)
4) Cómo configurar `apps/api/.env` desde `.env.example`
5) Cómo correr backend:
   - `cd apps/api`
   - `npm install`
   - `npx prisma migrate dev`
   - `npm run start:dev`
6) Cómo correr Flutter:
   - `cd apps/mobile`
   - `flutter pub get`
   - `flutter run`
7) Checklist GitHub:
   - confirmar que `.env` no se sube
   - confirmar que `node_modules`/`dist`/`build` no se suben
   - confirmar que migraciones sí se suben

---

## Entregables al final
1) Mostrar árbol final de carpetas.
2) Mostrar el contenido propuesto de:
   - `.gitignore` (raíz)
   - `apps/api/.env.example`
   - scripts principales de `apps/api/package.json`
3) Lista final de comandos que yo ejecutaré para:
   - instalar PostgreSQL
   - crear DB en DBeaver
   - levantar API
   - levantar Flutter
   - correr migraciones Prisma
4) Notas específicas si estoy en **macOS** (Homebrew, permisos, servicio de Postgres).

---

## Nota final
Si alguna ruta o archivo no existe, no inventes: crea lo mínimo necesario y explícame claramente qué creaste y por qué.