#!/bin/bash
set -e
set -x
echo "drop database if exists fb-flux" | mysql -uroot
echo "create database fb-flux" | mysql -uroot
mvn -pl :persistence-mysql liquibase:update -Dliquibase-maven-plugin.migration-folder=flux -Dliquibase-maven-plugin.dbname=fb-flux -Dliquibase-maven-plugin.username=root -Dliquibase-maven-plugin.password=omsairam
echo "drop database if exists fb-flux" | mysql -uroot
echo "create database fb-flux" | mysql -uroot
mvn -pl :persistence-mysql liquibase:update -Dliquibase-maven-plugin.migration-folder=flux_scheduler -Dliquibase-maven-plugin.dbname=fb-flux -Dliquibase-maven-plugin.username=root -Dliquibase-maven-plugin.password=omsairam
