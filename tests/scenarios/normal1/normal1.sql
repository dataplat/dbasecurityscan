create database normal1
go

use normal1
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

grant exec on sp_perms to testuser;
go

create view vw_select
AS
select * from sys.all_columns;
go

grant select on vw_select to READONLY;
go