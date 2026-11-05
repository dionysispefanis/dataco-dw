-- Creates the database and the three layers (schemas). 
IF DB_ID('DataCoDW') IS NULL
    CREATE DATABASE DataCoDW;
GO

USE DataCoDW;
GO

IF SCHEMA_ID('staging') IS NULL EXEC('CREATE SCHEMA staging');
IF SCHEMA_ID('clean')   IS NULL EXEC('CREATE SCHEMA clean');
IF SCHEMA_ID('dw')      IS NULL EXEC('CREATE SCHEMA dw');
GO