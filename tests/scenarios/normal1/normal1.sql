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