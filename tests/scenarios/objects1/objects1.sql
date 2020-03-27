create database objects1
go

use objects1
go


create procedure sp_test
as
select * from sys.all_columns;
go

create view vw_view
AS
select * from sys.all_columns;
GO

create user user1 without login;
create user user2 without login;

grant EXECUTE on sp_test to user1;
grant ALTER on sp_test to user2;
GO

grant SELECT, UPDATE, DELETE on vw_view to user2
GO


