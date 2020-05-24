use master;
go

if exists (select * from sys.databases where name='all1')
BEGIN
alter database all1 set single_user with rollback immediate
drop database all1
END
GO

create database all1
go

use all1
go

create user testuser without login;
GO

exec sp_addrolemember 'db_datareader','testuser';
exec sp_addrolemember 'db_datawriter','testuser';
GO

create user readonly without login;
GO

exec sp_addrolemember 'db_datareader','readonly';
go

create procedure sp_perms
as
select * from sys.all_columns;
go

grant alter on sp_perms to testuser;
go

create view vw_select
AS
select * from sys.all_columns;
go

create role PesterTest;
GO

create role PesterTest2;
GO

create schema testing AUTHORIZATION readonly;
GO

create user schemaread without login;
go

grant select on schema::testing to schemaread;
go
