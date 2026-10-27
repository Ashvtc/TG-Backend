# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

NestJS 9 + TypeORM + PostgreSQL backend (package name `qroom-backend`) for tracking operating/procedure room terminal cleaning: users with roles, areas → rooms, cleaning types and checklists per room, cleaning actions (housekeeper/supervisor timestamps), and a PDF cleaning-control report.

## Commands

Yarn is the configured package manager (`.yarnrc.yml`, `nodeLinker: node-modules`), though a `package-lock.json` is also checked in.

```bash
yarn install
yarn start:dev        # watch mode; serves on PORT (default 3000) under the /api prefix
yarn build            # nest build -> dist/
yarn start:prod       # node dist/main
yarn lint             # eslint --fix (no eslint config file is currently committed)
yarn format           # prettier
yarn test             # jest, rootDir=src, matches *.spec.ts
yarn test -- path/to/file.spec.ts   # single test file
yarn test -- -t "test name"         # single test by name
```

There are currently no `*.spec.ts` files and no `test/` directory, so `test:e2e` (which expects `test/jest-e2e.json`) will not run as-is.

## Environment

Copy `.env.example` to `.env` and set `DB_USERNAME`, `DB_PASS`, `DB_HOST`, `DB_NAME`, `DB_PORT` (plus optional `PORT`). `AppModule` configures TypeORM with `autoLoadEntities: true` and `synchronize: true` — entity changes alter the database schema on startup; there are no migrations.

## Architecture

Each domain lives in `src/<domain>/` (`user`, `rol`, `area`, `room`, `cleaningType`, `cleaningCheck`, `cleaningAction`, `permissions`) and follows a hexagonal layering:

- `domain/` — plain entity class with a private constructor and a static `create(...)` factory that wraps every field in a value object (`domain/valueObjects/*`, each a tiny class with a getter). `domain/repository/I<Name>.ts` is a generic port interface `I<Name><T>` whose methods return `Promise<Either<Error, T>>`.
- `application/` — one class per use case (`createXService`, `getXService`, …) with an `execute(...)` method. Services take the repository port in their constructor and build domain objects from DTOs (`application/dto/`, validated with class-validator).
- `infrastructure/` — TypeORM entity (`entities/*.entity.ts`, extends `BaseEntity`), the `@Injectable()` adapter that implements the port against TypeORM repositories, the controller, and the Nest module.

Conventions that span files:

- **Error handling uses `Either`** (`src/generics/Either.ts`), not exceptions. Adapters catch errors and return `Either.makeLeft(new Error(...))`; controllers branch on `isLeft()`. Some adapters encode HTTP intent in the error message (e.g. `'403'`, `'404'` in `room.adapter.ts`) which the controller maps to status codes; Postgres unique violations (`error.code === '23505'`) are turned into readable messages.
- **Service wiring is manual**: services are listed as module providers, but controllers overwrite them in the constructor with `new xService(adapter)`. Follow the same pattern when adding use cases.
- **Cross-domain access goes through other domains' TypeORM entities**: a module imports `TypeOrmModule.forFeature([...])` for every foreign entity its adapter injects (e.g. `RoomModule` registers `AreaEntity`, `RolEntity`, `PermissionsEntity`, `CleaningActionEntity`). Adding an `@InjectRepository(X)` to an adapter requires registering `X` in that module.
- Imports use absolute `src/...` paths (resolved via `baseUrl` in `tsconfig.json`).
- `main.ts` sets the global `api` prefix and a `ValidationPipe` with `whitelist` + `forbidNonWhitelisted`, so DTOs must declare every accepted field.
- Role-based access is checked by role *name* passed in the URL (e.g. `GET /api/room/:id/:rol`, `GET /api/cleaning-type/:idRoom/:userRol`) against the `permissions` table; there is no auth token/guard. `POST /api/user/auth` matches email + password directly in the DB.

### PDF reports

- `src/printer/PrinterService` wraps pdfmake's `PdfPrinter` with Roboto fonts loaded from the repo-root `fonts/` directory and a `customLayout01` table layout. Paths are relative to the process CWD, so run the app from the repo root.
- `src/reports/` holds pdfmake document definitions: `cleaning-control-pdf.ts` (cover page, per-area dashboards, per-room tables) plus `sections/` (header/footer) and `helpers/` (date formatting). Images come from `src/upload/` (also CWD-relative).
- `CleaningActionAdapter` injects `PrinterService`, queries data, and builds the document; `CleaningActionController` exposes it at `GET /api/cleaning-action/pdf` (streams the PDFKit document) and `GET /api/cleaning-action/pdf/test` (buffer download).
