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

sp_addrolemember 'userrole','alice';
sp_addrolemember 'userrole','bob';
GO

create procedure sp_test as 
select * from sys.all_columns;
go

grant execute on sp_test to userrole;
go