# app_creditos Monorepo

Monorepo con:

- `apps/mobile`: app Flutter
- `apps/api`: backend NestJS + Prisma + PostgreSQL

## Requisitos

- Flutter SDK
- Node.js LTS (npm incluido)
- PostgreSQL local
- DBeaver (opcional, recomendado para administrar la DB)

## Estructura

```text
app_creditos/
├── apps/
│   ├── mobile/   # Flutter
│   └── api/      # NestJS + Prisma
├── .gitignore
├── README.md
└── PLANIFICACION.md
```

## Instalación de PostgreSQL (resumen por OS)

### macOS

- Homebrew (recomendado):
  - `brew install postgresql`
  - `brew services start postgresql`
- Alternativa: Postgres.app o EnterpriseDB.

### Windows

- Instalar PostgreSQL desde instalador oficial (EDB) o usar Postgres.app equivalente para Windows.
- Asegúrate de recordar puerto, usuario y contraseña.

### Linux

- Debian/Ubuntu:
  - `sudo apt update`
  - `sudo apt install postgresql postgresql-contrib`
- Fedora:
  - `sudo dnf install postgresql-server postgresql-contrib`

## Crear DB en DBeaver

1. Crear conexión a PostgreSQL local.
2. Crear base de datos:
   - Nombre sugerido: `app_creditos`
3. Usuario/password (ejemplo):
   - usuario: `postgres`
   - password: `tu_password`

## Configurar backend (`apps/api/.env`)

1. Copiar el template:

```bash
cd apps/api
cp .env.example .env
```

2. Editar `DATABASE_URL` con tus credenciales reales:

```env
DATABASE_URL="postgresql://USER:PASSWORD@localhost:5432/app_creditos?schema=public"
```

## Correr backend (NestJS + Prisma)

```bash
cd apps/api
npm install
npx prisma migrate dev
npm run start:dev
```

### Endpoint de health

- `GET http://localhost:3000/health`
- Respuesta esperada:

```json
{ "status": "ok" }
```

## Correr Flutter (`apps/mobile`)

```bash
cd apps/mobile
flutter pub get
flutter run
```

## App de Retos Fotográficos (Android + iOS)

La app móvil ahora incluye:

- Login/registro con JWT
- Retos A/B/C (Detector de Misterios, Safari de Oficina, Inspector Técnico)
- Captura de evidencias con cámara
- Subida de fotos al backend
- Generación de PDF y preview/compartir
- Ranking global

### Seguridad de capturas de pantalla

- Android: bloqueo fuerte con `FLAG_SECURE`
- iOS: best effort con detección de screenshot/grabación y ocultamiento de contenido

Importante: en iOS no existe un bloqueo preventivo total equivalente a Android usando APIs públicas.

### Permisos móviles

- Android: `CAMERA`, `INTERNET`
- iOS: `NSCameraUsageDescription` y `NSPhotoLibraryAddUsageDescription`

### Endpoints principales usados por la app

- `POST /auth/register`
- `POST /auth/login`
- `GET /challenges`
- `POST /challenges/seed-defaults`
- `POST /submissions`
- `POST /submissions/:id/photos`
- `POST /submissions/:id/complete`
- `GET /ranking/global`

## Prisma (comandos útiles)

```bash
cd apps/api
npx prisma migrate dev --name init
npx prisma studio
```

## Checklist GitHub

- Confirmar que `apps/api/.env` NO se sube.
- Confirmar que `apps/api/node_modules` y `apps/api/dist` NO se suben.
- Confirmar que `apps/mobile/build` y `.dart_tool` NO se suben.
- Confirmar que `apps/api/prisma/migrations/**` SÍ se suben.

## Notas específicas para macOS

- Si instalaste PostgreSQL con Homebrew:
  - iniciar servicio: `brew services start postgresql`
  - detener servicio: `brew services stop postgresql`
- Verifica estado del server:
  - `pg_isready -h localhost -p 5432`
- Si usas `nvm`, asegúrate de cargarlo en `~/.zshrc` para que `node` y `npm` estén disponibles en nuevas terminales.
