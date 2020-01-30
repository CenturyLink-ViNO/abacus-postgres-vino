#!/bin/bash


/bin/echo Creating database user \"abacus\"
sudo -u postgres psql -c "CREATE ROLE abacus WITH SUPERUSER LOGIN PASSWORD 'abacus';"

# this should be a abacusPostgres function - abacusPostgresAddToSearchPath
sudo -u postgres psql -c "ALTER ROLE abacus SET search_path TO abacus,abacus_auth,public;"

/bin/echo Creating database \"abacus\"
sudo -u postgres psql -c "CREATE DATABASE abacus WITH OWNER abacus;"

# this should be a abacusPostgres function - abacusPostgres ProcessSqlDir /opt/abacus/kaylee/etc/pgsql
/bin/echo Creating \"abacus\" schema in abacus database -----------------------------
for name in $(/bin/find /opt/abacus/abacus-postgres/etc/pgsql/ -maxdepth 1 -name "*.sql" | sort); do
    base=`basename $name`
    /bin/echo Running $base
    sudo -u postgres psql -f /opt/abacus/abacus-postgres/etc/pgsql/$base
done
/bin/echo ---------------------------------------------------------------------
