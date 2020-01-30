\o /dev/null
\set VERBOSITY terse
SET client_min_messages=WARNING;

\c vino

create or replace function createSchema(schemaNameParam text) returns void as $$
   begin
      if not exists(select schema_name FROM information_schema.schemata WHERE schema_name = schemaNameParam) then
         execute 'CREATE SCHEMA if not exists ' || schemaNameParam || ' AUTHORIZATION abacus ;';
--         execute 'GRANT USAGE ON SCHEMA ' || schemaNameParam || ' to admins;';
--         execute 'GRANT USAGE ON SCHEMA ' || schemaNameParam || ' to users;';
         raise info 'created % schema', schemaNameParam;
      end if;
   end
$$ language plpgsql;

select createSchema('abacus');

create or replace function abacus.setTablePermissions(tableNameParam text) returns void as $$
   begin
--      execute 'GRANT ALL ON TABLE ' || tableNameParam || ' TO GROUP admins ;';
--      execute 'GRANT SELECT, DELETE on TABLE ' || tableNameParam || ' to GROUP users ;';
      execute 'GRANT ALL ON TABLE ' || tableNameParam || ' TO GROUP abacus ;';
      execute 'ALTER TABLE ' || tableNameParam || ' OWNER TO abacus ;';
   end;
$$ language plpgsql;

create or replace function abacus.schemaExists(schemaNameParam text) returns boolean as $$
   begin
      return exists(select schema_name FROM information_schema.schemata WHERE schema_name = schemaNameParam);
   end;
$$ language plpgsql;

create or replace function abacus.tableExists(schemaNameParam text, tableNameParam text) returns boolean as $$
   begin
      return exists(select * from pg_catalog.pg_tables where tablename = tableNameParam and schemaname = schemaNameParam);
   end;
$$ language plpgsql;

create or replace function abacus.triggerExists(triggerNameParam text) returns boolean as $$
   begin
      return exists(select * from pg_catalog.pg_trigger where tgname = triggerNameParam);
   end;
$$ language plpgsql;

