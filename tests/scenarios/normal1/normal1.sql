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

grant alter on sp_perms to testuser;
go

create view vw_select
AS
select * from sys.all_columns;
go

-- grant alter on sp_perms to READONLY;
-- go

-- create table TIMESTAMP(
--     col1 int
-- )

-- select * from sys.all_objects where is_ms_shipped=1 and type_desc='user_table'

-- group by type_desc

