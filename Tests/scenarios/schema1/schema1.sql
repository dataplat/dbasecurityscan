use master;
GO

if exists (select * from sys.databases where name='schema1')
BEGIN
alter database schema1 set single_user with rollback immediate
drop database schema1
END
GO

create database schema1
go

use schema1;
go

create user schemaOwner without login;
go

create schema deleteable;
go

create schema unowned;
go

create schema owned  AUTHORIZATION schemaowner;
go

create procedure unowned.sp_test as 
select * from sys.all_columns
GO

create procedure owned.sp_test AS
select * from sys.all_columns
go

create user test without login;
go

grant select on SCHEMA::unowned to test;
go

-- select * from sys.database_role_members where member_principal_id=user_id('testuser') and role_principal_id = role

-- select is_rolemember('db_datareader','testuser') as 'member'


-- select role_id('db_datareader')

-- select * from sys.all_objects where name like '%role%'
