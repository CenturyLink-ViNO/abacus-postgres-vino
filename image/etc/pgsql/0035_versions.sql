\o /dev/null
\set VERBOSITY terse
SET client_min_messages=WARNING;
\c vino

-- ===================================================================================================================

do $$
   begin
      if (not exists(select * from pg_catalog.pg_tables where tablename = 'version_information' and schemaname = 'abacus')) then
         create table if not exists abacus.version_information
         (
            type        text,
            name        text,
            schema_name text,
            major       int,
            minor       int,
            fix         int,
            build       int,
            primary key(type, name, schema_name)
         );
         execute 'GRANT ALL ON TABLE abacus.version_information TO GROUP abacus ;';
         execute 'ALTER TABLE abacus.version_information OWNER TO abacus ;';
         raise info 'created abacus.version_information table';
      end if;
   end;
$$;
-- ===================================================================================================================

create or replace function abacus.tableExists(schemaNameParam text, tableNameParam text) returns boolean as $$
   begin
      return
         exists(select * from pg_catalog.pg_tables where tablename = tableNameParam and schemaname = schemaNameParam);
   end;
$$ language plpgsql;

-- ===================================================================================================================

create or replace function abacus.removeTableVersion(schemaNameParam text, tableNameParam text) returns void as $$
   begin
      delete from abacus.version_information
         where type = 'table' and
               name = tableNameParam and
               schema_name = schemaNameParam;
   end;
$$ language plpgsql;

-- ===================================================================================================================

create or replace function abacus.tableVersion(schemaNameParam text,
                                               tableNameParam text,
                                               majorParam int,
                                               minorParam int,
                                               fixParam int,
                                               buildParam int) returns void as $$
   begin
      if (exists(select * from abacus.version_information
                    where type = 'table' and name = tableNameParam and schema_name = schemaNameParam)) then
         update abacus.version_information
            set major = majorParam, minor = minorParam, fix = fixParam, build = buildParam
            where type = 'table' and name = tableNameParam and schema_name = schemaNameParam;
      else
         insert into abacus.version_information(type, name, schema_name, major, minor, fix, build)
            values('table', tableNameParam, schemaNameParam, majorParam, minorParam, fixParam, buildParam);
      end if;
   end;
$$ language plpgsql;

-- ===================================================================================================================

create or replace function abacus.tableVersion(schemaNameParam text, tableNameParam text) returns abacus.version_information as $$
   declare ret abacus.version_information;
   begin
      if (exists(select * from abacus.version_information
                    where type = 'table' and name = tableNameParam and schema_name = schemaNameParam)) then
         select * into ret from abacus.version_information
            where type = 'table' and name = tableNameParam and schema_name = schemaNameParam;
      else
         ret.type = 'table';
         ret.name = tableNameParam;
         ret.schema_name = schemaNameParam;
         ret.major = -1;
         ret.minor = -1;
         ret.fix = -1;
         ret.build = -1;
      end if;
      return ret;
   end;
$$ language plpgsql;

select abacus.tableVersion('abacus', 'version_information', 1,0,0,0);

-- ===================================================================================================================

create or replace function abacus.initializeTable(schemaNameParam          text,
                                                  tableNameParam           text,
                                                  majorParam               int,
                                                  minorParam               int,
                                                  fixParam                 int,
                                                  buildParam               int) returns void as $$
   begin
      raise info 'initializing table [%.%] at version [%.%.%.%]',
         schemaNameParam, tableNameParam, majorParam, minorParam, fixParam, buildParam;
      perform abacus.tableVersion(schemaNameParam, tableNameParam, majorParam, minorParam, fixParam, buildParam);
      perform abacus.setTablePermissions(schemaNameParam || '.' || tableNameParam);
   end;
$$ language plpgsql;

-- ===================================================================================================================

do $$
   declare version abacus.version_information;
   declare schemaName text;
   declare tableName text;
   begin
      tableName := 'install_log';
      schemaName := 'abacus';
      version := abacus.tableVersion(schemaName, tableName);
      case version.major
         when -1 then
            CREATE TABLE if not exists abacus.install_log
            (
               name text,
               type text,
               major int,
               minor int,
               revision int,
               fix int,
               buildid text,
               ts timestamp
            );
            perform abacus.initializeTable(schemaName, tableName, 1,0,0,0);
         else
           raise info '%.% table at version [%.%.%.%]', schemaName, tableName, version.major, version.minor, version.fix, version.build;
      end case;
   end
$$;

-- ===================================================================================================================
