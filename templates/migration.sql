-- V<yyyyMMddHHmm>__<snake_description>.sql — versioned migration (DB-08).
-- Expand/contract (DB-09): this migration must work with the currently deployed app version.
-- Release plan: <expand in vX, switch code in vX, contract (drop old) in vY>.
-- Replace every <placeholder>. Remove sections that do not apply.

SET lock_timeout = '5s';          -- DB-10
SET statement_timeout = '60s';    -- DB-10

-- New tenant-scoped table (DB-06, DB-07, DB-15)
CREATE TABLE core.<table> (
    tenant_id    uuid        NOT NULL,
    id           uuid        NOT NULL DEFAULT uuidv7(),
    <column>     text        NOT NULL CHECK (char_length(<column>) BETWEEN 1 AND 200),
    created_at   timestamptz NOT NULL DEFAULT now(),
    created_by   uuid        NOT NULL,
    updated_at   timestamptz NOT NULL DEFAULT now(),
    updated_by   uuid        NOT NULL,
    row_version  bigint      NOT NULL DEFAULT 1,
    deleted_at   timestamptz NULL,
    deleted_by   uuid        NULL,
    CONSTRAINT <table>_pk PRIMARY KEY (tenant_id, id),
    CONSTRAINT <table>_<parent>_fk FOREIGN KEY (tenant_id, <parent>_id) REFERENCES core.<parent> (tenant_id, id)
);

ALTER TABLE core.<table> OWNER TO <svc>_owner;

-- Row-level security (DB-05)
ALTER TABLE core.<table> ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.<table> FORCE ROW LEVEL SECURITY;
CREATE POLICY <table>_tenant_isolation ON core.<table>
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid)
    WITH CHECK (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- Keyset index for listing (DB-13); new table, so CONCURRENTLY is not needed here.
CREATE INDEX <table>_list_ix ON core.<table> (tenant_id, created_at DESC, id DESC) WHERE deleted_at IS NULL;

-- Adding a column to an existing, populated table: nullable or with a constant default (no rewrite).
-- ALTER TABLE core.<existing> ADD COLUMN <column> text NULL;

-- Index on a populated table goes in its OWN migration file, alone, as:
-- CREATE INDEX CONCURRENTLY IF NOT EXISTS <name> ON core.<existing> (tenant_id, <column>);
-- (Flyway: put `-- flyway:executeInTransaction=false` on the first line of that file.)

-- No grants on tables to <svc>_app (DB-02).
