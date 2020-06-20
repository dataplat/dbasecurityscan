use master
go

if exists (select * from sys.databases where name='roles1')
BEGIN
alter database roles1 set single_user with rollback immediate
drop database roles1
END
GO

create database roles1
go

use roles1
go

create user alice without login;
GO

create user bob without login;
GO

create user carol without login;
GO

create role userrole AUTHORIZATION dbo;
go

exec sp_addrolemember 'userrole','alice';
go

exec sp_addrolemember 'userrole','bob';
GO

exec sp_addrolemember 'db_datawriter','carol';
go

create procedure sp_test as 
select * from sys.all_columns;
go

grant execute on sp_test to userrole;
go

create role removerole AUTHORIZATION dbo;
go

--grant execute on sp_test to removerole;
