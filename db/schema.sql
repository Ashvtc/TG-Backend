-- Esquema de TG-Backend, equivalente a lo que crea TypeORM con DB_SYNC=true.
-- Nombres de columnas y constraints generados a partir de los metadatos de las
-- entidades (src/**/entities/*.entity.ts). Si cambias una entidad, actualiza este archivo.
--
-- Uso: psql "<url de conexión>" -v ON_ERROR_STOP=1 -f db/schema.sql
-- Es idempotente: se puede correr más de una vez sin duplicar nada.

BEGIN;

-- Los ids se generan con uuid_generate_v4(). Si el proveedor no permite crear la
-- extensión, cambia uuid_generate_v4() por gen_random_uuid() (PostgreSQL 13+).
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS "area" (
    "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "name" text NOT NULL,
    "order" integer,
    CONSTRAINT "PK_39d5e4de490139d6535d75f42ff" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "rol" (
    "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "name" text NOT NULL,
    CONSTRAINT "UQ_642b883443b82d52f4ba99589c9" UNIQUE ("name"),
    CONSTRAINT "PK_c93a22388638fac311781c7f2dd" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "cleaning_type" (
    "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "name" text NOT NULL,
    "description" text,
    "created_at" TIMESTAMP,
    "order" integer,
    CONSTRAINT "PK_ad7efc6de136e7bd273f5126c3f" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "room" (
    "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "name" text NOT NULL,
    "order" integer,
    "areaId" uuid,
    CONSTRAINT "PK_c6d46db005d623e691b2fbcba23" PRIMARY KEY ("id"),
    CONSTRAINT "FK_358d7edc0989b6518d8f3bfcbf8" FOREIGN KEY ("areaId") REFERENCES "area"("id") ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS "user" (
    "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "username" text NOT NULL,
    "password" text NOT NULL,
    "email" text NOT NULL,
    "first_name" text NOT NULL,
    "last_name" text NOT NULL,
    "code_area_1" text,
    "phone_number_1" text,
    "rolId" uuid,
    CONSTRAINT "UQ_78a916df40e02a9deb1c4b75edb" UNIQUE ("username"),
    CONSTRAINT "PK_cace4a159ff9f2512dd42373760" PRIMARY KEY ("id"),
    CONSTRAINT "FK_f66058a8f024b32ce70e0d6a929" FOREIGN KEY ("rolId") REFERENCES "rol"("id") ON DELETE NO ACTION ON UPDATE NO ACTION
);

-- Árbol materialized-path de TypeORM: "mpath" lo calcula TypeORM al guardar
-- (formato "<id-raiz>.<id-hijo>.<id>."), por eso los checks deben insertarse vía TypeORM.
CREATE TABLE IF NOT EXISTS "cleaning_check" (
    "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "name" text NOT NULL,
    "created_at" TIMESTAMP,
    "order" integer,
    "mpath" character varying DEFAULT '',
    "parentCheckId" uuid,
    "typeId" uuid,
    CONSTRAINT "PK_b917f6f99c9bf1b6ccec1688da3" PRIMARY KEY ("id"),
    CONSTRAINT "FK_796eba5b26ba12337d4019d32f0" FOREIGN KEY ("parentCheckId") REFERENCES "cleaning_check"("id") ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT "FK_9027c43101305e78b229de3f040" FOREIGN KEY ("typeId") REFERENCES "cleaning_type"("id") ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS "permissions" (
    "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "rolId" uuid,
    "roomId" uuid,
    "cleaningTypeId" uuid,
    CONSTRAINT "PK_920331560282b8bd21bb02290df" PRIMARY KEY ("id"),
    CONSTRAINT "FK_4a60ab2d6eca520d075a5f1b480" FOREIGN KEY ("rolId") REFERENCES "rol"("id") ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT "FK_18d5ea7f045af6dad556fbe11f2" FOREIGN KEY ("roomId") REFERENCES "room"("id") ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT "FK_987a70e42d6af879732d3e66d44" FOREIGN KEY ("cleaningTypeId") REFERENCES "cleaning_type"("id") ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS "cleaning_action" (
    "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "initial_time_hk" TIMESTAMP,
    "end_time_hk" TIMESTAMP,
    "initial_time_sup" TIMESTAMP,
    "end_time_sup" TIMESTAMP,
    "text" text,
    "room_id" uuid,
    "hk_id" uuid,
    "cleaningType_id" uuid,
    "sup_id" uuid,
    CONSTRAINT "PK_8bdf8ae5ed5036465697eb62431" PRIMARY KEY ("id"),
    CONSTRAINT "FK_a44fdc118611997f23c88af7c56" FOREIGN KEY ("room_id") REFERENCES "room"("id") ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT "FK_4d5044c37efbfa420f661150a02" FOREIGN KEY ("hk_id") REFERENCES "user"("id") ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT "FK_772275e5db8fa895b5e6eee8bf0" FOREIGN KEY ("cleaningType_id") REFERENCES "cleaning_type"("id") ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT "FK_caa9d09afd630b91902a764277b" FOREIGN KEY ("sup_id") REFERENCES "user"("id") ON DELETE NO ACTION ON UPDATE NO ACTION
);

COMMIT;
