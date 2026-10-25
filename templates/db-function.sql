-- R__api.<name>.sql — repeatable migration, one routine per file (DB-08).
-- Purpose: <what it does>. Called by: <Svc>.Infrastructure.<Adapter>.<Method>.
-- Errors (DB-11, see db/<svc>/ERRORS.md): <code> when <condition>.
-- Replace every <placeholder>. Delete the example statements that do not apply.

CREATE OR REPLACE FUNCTION api.<name>(
    p_tenant_id    uuid,          -- DB-04: tenant first
    p_actor_id     uuid,          -- DB-04: actor second (audit fields)
    p_<id>         uuid,
    p_row_version  bigint,        -- for updates (DB-07, API-06)
    p_<field>      text
)
RETURNS core.<table>
LANGUAGE plpgsql
VOLATILE                          -- STABLE for read-only routines
SECURITY DEFINER                  -- DB-03
SET search_path = pg_catalog, core, pg_temp
AS $$
DECLARE
    v_row core.<table>;
BEGIN
    PERFORM set_config('app.tenant_id', p_tenant_id::text, true);   -- DB-05

    UPDATE core.<table> t
       SET <field>     = p_<field>,
           updated_at  = now(),
           updated_by  = p_actor_id,
           row_version = t.row_version + 1
     WHERE t.tenant_id   = p_tenant_id
       AND t.id          = p_<id>
       AND t.deleted_at IS NULL
       AND t.row_version = p_row_version
    RETURNING t.* INTO v_row;

    IF NOT FOUND THEN
        IF EXISTS (SELECT 1 FROM core.<table> t
                    WHERE t.tenant_id = p_tenant_id AND t.id = p_<id> AND t.deleted_at IS NULL) THEN
            RAISE EXCEPTION USING ERRCODE = 'P0412', MESSAGE = 'precondition-failed';
        END IF;
        RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = '<entity>-not-found';
    END IF;

    -- Outbox (only if this change publishes an event; same transaction, ADR-0012):
    -- INSERT INTO outbox.message (id, tenant_id, type, subject, payload, traceparent, created_at)
    -- VALUES (uuidv7(), p_tenant_id, 'com.workshop.<svc>.<entity>.<event>.v1', v_row.id::text,
    --         jsonb_build_object('<field>', v_row.<field>), current_setting('app.traceparent', true), now());

    RETURN v_row;
END;
$$;

ALTER FUNCTION api.<name>(uuid, uuid, uuid, bigint, text) OWNER TO <svc>_owner;
REVOKE ALL ON FUNCTION api.<name>(uuid, uuid, uuid, bigint, text) FROM PUBLIC;          -- DB-02
GRANT EXECUTE ON FUNCTION api.<name>(uuid, uuid, uuid, bigint, text) TO <svc>_app;       -- DB-02

COMMENT ON FUNCTION api.<name>(uuid, uuid, uuid, bigint, text) IS '<one-line purpose>';
