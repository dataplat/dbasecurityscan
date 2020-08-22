$commandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
. "$PSScriptRoot\constants.ps1"

$script:database = 'all1'

Describe "$commandName Integration Tests" {
    BeforeAll {
        # Reset database
        $srv = Connect-DbaInstance -SqlInstance $Script:appvSqlInstance -SqlCredential $Script:appvSqlCredential
        $query = Get-Content '.\Tests\scenarios\all1\all1.sql' -raw
        Remove-DbaDatabase -SqlInstance $Script:appvSqlInstance -SqlCredential $Script:appvSqlCredential -Database $script:database -Confirm:$false
        $srv.Databases['master'].ExecuteNonQuery($query) 

        $schemaAddSql = "create schema notwanted"
        $schemaAddFixSql = "drop schema notwanted"
        $schemaAddCheckSql = "select count(1) as 'count' from sys.schemas where name='notwanted'"


        $schemaDropPermissionSql = "revoke select on schema::testing from schemaread;"
        $schemaDropPermissionFixSql = "grant select on schema::testing to schemaread;"
        $schemaDropPermissionCheckSql = "                
                        select 
                            count(1) as 'count'
                        from 
                            sys.database_permissions sdperm 
                                inner join sys.schemas ss on sdperm.major_id=ss.schema_id
                                inner join sys.database_principals sdp on sdperm.grantee_principal_id = sdp.principal_id
                        where class_desc='SCHEMA' 
                        and ss.name='testing' and sdp.name='schemaread' and sdperm.permission_name='SELECT'
                    "

        $userRevokeRoleSql = "exec sp_droprolemember 'db_datareader','testuser'"
        $userRevokeRoleFixSql = "exec sp_addrolemember 'db_datareader','testuser'"
        $userRevokeRoleCheckSql = "select is_rolemember('db_datareader','testuser') as 'member'"

        $userAddPermSql = "grant alter on sp_perms to schemaread"
        $userAddPermFixSql = "revoke alter on sp_perms from schemaread"
        $userAddPermCheckSql = "select count(1) as count from sys.database_permissions where major_id=object_id('sp_perms') and grantee_principal_id=user_id('schemaread')"
    
        $roleDropSql = "drop role PesterTest"
        $roleDropFixSql = "create role PesterTest authorization dbo"
        $roleDropCheckSql = "select count(1) as 'count' from sys.database_principals where type_desc='DATABASE_ROLE' and name='PesterTest'"

        $roleMemberAddSql = "exec sp_addrolemember 'PesterTest2','schemaread'"
        $roleMemberFixSql = "exec sp_droprolemember 'PesterTest2','schemaread'"
        $roleMemberCheckSql = "select IS_ROLEMEMBER('PesterTest2','schemaread') as 'member'"
    }

    Context "Test For output Only" {
        $config = New-DssConfig -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -database $script:database
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaAddSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaDropPermissionSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userAddPermSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userRevokeRoleSql
        # New-DbaDbRole @script:appsplat -database $script:database -Role PesterTest2
        # New-DbaDbRole @script:appsplat -database $script:database -Role PesterTest
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleDropSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleMemberAddSql

        $schemaAddCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaAddCheckSql
        $schemaDropPermissionCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaDropPermissionCheckSql
        $userRevokeRoleCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userRevokeRoleCheckSql
        $userAddPermCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userAddPermCheckSql
        $roleDropCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleDropCheckSql
        $roleMemberCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleMemberCheckSql
        

        $results = Invoke-DssTest -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -database $script:database -Config $config -Quiet
        It "Results should contain 4 User errors" {
            $results.UsersResults.FailedCount | Should -Be 4
        }
        It "Results should contain 2 Schema errors" {
            $results.SchemaResults.FailedCount | Should -Be 2
        }
        It "Schema 'notwanted' Should Exist before fix" {
            $schemaAddCheck.count | Should -Be 1
        }
        It "schemaread should not have select on schemaread before fix" {
            $schemaDropPermissionCheck.count | Should -Be 0
        }
        It "testuser Should not be in db_datareader before fix" {
            $userRevokeRoleCheck.member | Should -Be 0
        }
        It "schemaread Should  have alter on sp_perms before fix" {
            $userAddPermCheck.count | Should -Be 1
        }
        It "Results Should contain 3 Role errors" {
            $results.RolesResults.FailedCount | Should -Be 3
        }
        It "Role PesterTest should not exist before fix" {
            $roleDropCheck.count | Should -Be 0
        }
        It "schemaread Should Be a member of userrole" {
            $roleMemberCheck.member | Should -Be 1
        }
        
        $output = Reset-DssSecurity -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -database $script:database -TestResult $results -OutputOnly

        $schemaAddCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaAddCheckSql
        $schemaDropPermissionCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaDropPermissionCheckSql
        $userRevokeRoleCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userRevokeRoleCheckSql
        $userAddPermCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userAddPermCheckSql
        $roleDropCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleDropCheckSql
        $roleMemberCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleMemberCheckSql
        
        It "Schema 'notwanted' Should Still Exist post fix" {
            $schemaAddCheck.count | Should -Be 1
        }
        It "schemaread should Still not have select on schemaread post fix" {
            $schemaDropPermissionCheck.count | Should -Be 0
        }
        It "testuser Should still not be in db_datareader post fix" {
            $userRevokeRoleCheck.member | Should -Be 0
        }
        It "schemaread Should still have alter on sp_perms post fix" {
            $userAddPermCheck.count | Should -Be 1
        }

        It "Should have returned 9 items in output" {
            ($output | Measure-Object).count | Should -Be 9
        }
        It "Role PesterTest should not exist before fix" {
            $roleDropCheck.count | Should -Be 0
        }
        It "schemaread Should Be a member of userrole" {
            $roleMemberCheck.member | Should -Be 1
        }

        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaAddFixSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaDropPermissionFixSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userAddPermFixSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userRevokeRoleFixSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleDropFixSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleMemberFixSql
    }
    

    Context "Test for Add Only" {
        $config = New-DssConfig -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -database $script:database
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaAddSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaDropPermissionSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userAddPermSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userRevokeRoleSql
        # New-DbaDbRole @script:appsplat -database $script:database -Role PesterTest2
        # New-DbaDbRole @script:appsplat -database $script:database -Role PesterTest
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleDropSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleMemberAddSql

        $schemaAddCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaAddCheckSql
        $schemaDropPermissionCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaDropPermissionCheckSql
        $userRevokeRoleCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userRevokeRoleCheckSql
        $userAddPermCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userAddPermCheckSql
        $roleDropCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleDropCheckSql
        $roleMemberCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleMemberCheckSql

        $results = Invoke-DssTest -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -database $script:database -Config $config -Quiet
        It "Results should contain 4 User errors" {
            $results.UsersResults.FailedCount | Should -Be 4
        }
        It "Results should contain 2 Schema errors" {
            $results.SchemaResults.FailedCount | Should -Be 2
        }
        It "Schema 'notwanted' Should Exist before fix" {
            $schemaAddCheck.count | Should -Be 1
        }
        It "schemaread should not have select on schema testing before fix" {
            $schemaDropPermissionCheck.count | Should -Be 0
        }
        It "testuser Should not be in db_datareader before fix" {
            $userRevokeRoleCheck.member | Should -Be 0
        }
        It "schemaread Should  have alter on sp_perms before fix" {
            $userAddPermCheck.count | Should -Be 1
        }
        It "Results Should contain 3 Role errors" {
            $results.RolesResults.FailedCount | Should -Be 3
        }
        It "Role PesterTest should not exist before fix" {
            $roleDropCheck.count | Should -Be 0
        }
        It "schemaread Should Be a member of userrole" {
            $roleMemberCheck.member | Should -Be 1
        }
        
        $output = Reset-DssSecurity -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -database $script:database -TestResult $results -AddOnly

        $schemaAddCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaAddCheckSql
        $schemaDropPermissionCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaDropPermissionCheckSql
        $userRevokeRoleCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userRevokeRoleCheckSql
        $userAddPermCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userAddPermCheckSql
        $roleDropCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleDropCheckSql
        $roleMemberCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleMemberCheckSql

        It "Schema 'notwanted' Should Still Exist post fix (AddOnly)" {
            $schemaAddCheck.count | Should -Be 1
        }
        It "schemaread should have select on schema testing  post fix (AddOnly)" {
            $schemaDropPermissionCheck.count | Should -Be 1
        }
        It "testuser Should be in db_datareader post fix (AddOnly)" {
            $userRevokeRoleCheck.member | Should -Be 1
        }
        It "schemaread Should still have alter on sp_perms post fix (AddOnly)" {
            $userAddPermCheck.count | Should -Be 1
        }

        It "Should only have performed 'Add' fixes" {
            ($output | Where-Object { $_.Action -ne 'Add' } | Measure-Object).count | Should -Be 0
        }
        It "Role PesterTest exist post fix (AddOnly)" {
            $roleDropCheck.count | Should -Be 1
        }
        It "schemaread Should Be a member of userrole still (AddOnly)" {
            $roleMemberCheck.member | Should -Be 1
        }



        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaAddFixSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaDropPermissionFixSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userAddPermFixSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userRevokeRoleFixSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleDropFixSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleMemberFixSql
    }

     Context "Test for Drop Only" {
        $config = New-DssConfig -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -database $script:database
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaAddSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaDropPermissionSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userAddPermSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userRevokeRoleSql
        # New-DbaDbRole @script:appsplat -database $script:database -Role PesterTest2
        # New-DbaDbRole @script:appsplat -database $script:database -Role PesterTest
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleDropSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleMemberAddSql

        $schemaAddCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaAddCheckSql
        $schemaDropPermissionCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaDropPermissionCheckSql
        $userRevokeRoleCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userRevokeRoleCheckSql
        $userAddPermCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userAddPermCheckSql
        $roleDropCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleDropCheckSql
        $roleMemberCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleMemberCheckSql

        $results = Invoke-DssTest -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -database $script:database -Config $config -Quiet
        It "Results should contain 4 User errors" {
            $results.UsersResults.FailedCount | Should -Be 4
        }
        It "Results should contain 2 Schema errors" {
            $results.SchemaResults.FailedCount | Should -Be 2
        }
        It "Schema 'notwanted' Should Exist before fix" {
            $schemaAddCheck.count | Should -Be 1
        }
        It "schemaread should not have select on schema testing before fix" {
            $schemaDropPermissionCheck.count | Should -Be 0
        }
        It "testuser Should not be in db_datareader before fix" {
            $userRevokeRoleCheck.member | Should -Be 0
        }
        It "schemaread Should  have alter on sp_perms before fix" {
            $userAddPermCheck.count | Should -Be 1
        }
        It "Results Should contain 3 Role errors" {
            $results.RolesResults.FailedCount | Should -Be 3
        }
        It "Role PesterTest should not exist before fix" {
            $roleDropCheck.count | Should -Be 0
        }
        It "schemaread Should Be a member of userrole" {
            $roleMemberCheck.member | Should -Be 1
        }

        $output = Reset-DssSecurity -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -database $script:database -TestResult $results -RemoveOnly

        $schemaAddCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaAddCheckSql
        $schemaDropPermissionCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaDropPermissionCheckSql
        $userRevokeRoleCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userRevokeRoleCheckSql
        $userAddPermCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userAddPermCheckSql
        $roleDropCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleDropCheckSql
        $roleMemberCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleMemberCheckSql

        It "Schema 'notwanted' Should Not Exist post fix (DropOnly)" {
            $schemaAddCheck.count | Should -Be 0
        }
        It "schemaread should have select on schema testing  post fix (DropOnly)" {
            $schemaDropPermissionCheck.count | Should -Be 0
        }
        It "testuser Should be in db_datareader post fix (DropOnly)" {
            $userRevokeRoleCheck.member | Should -Be 0
        }
        It "schemaread Should still have alter on sp_perms post fix (DropOnly)" {
            $userAddPermCheck.count | Should -Be 0
        }
        It "Role PesterTest should still not exist before fix (DropOnly)" {
            $roleDropCheck.count | Should -Be 0
        }
        It "schemaread Should Not Be a member of userrole (DropOnly)" {
            $roleMemberCheck.member | Should -Be 0
        }

        It "Should only have performed 'Drop' fixes" {
            ($output | Where-Object { $_.Action -ne 'Drop' } | Measure-Object).count | Should -Be 0
        }

        # Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaAddFixSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaDropPermissionFixSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userAddPermFixSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userRevokeRoleFixSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleDropFixSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleMemberFixSql
     }

    Context "Test for All fixes" {
        $config = New-DssConfig -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -database $script:database
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaAddSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaDropPermissionSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userAddPermSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userRevokeRoleSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleDropSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleMemberAddSql

        $schemaAddCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaAddCheckSql
        $schemaDropPermissionCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaDropPermissionCheckSql
        $userRevokeRoleCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userRevokeRoleCheckSql
        $userAddPermCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userAddPermCheckSql
        $roleDropCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleDropCheckSql
        $roleMemberCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleMemberCheckSql


        $results = Invoke-DssTest -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -database $script:database -Config $config -Quiet
        It "Results should contain 4 User errors" {
            $results.UsersResults.FailedCount | Should -Be 4
        }
        It "Results should contain 2 Schema errors" {
            $results.SchemaResults.FailedCount | Should -Be 2
        }
        It "Schema 'notwanted' Should Exist before fix" {
            $schemaAddCheck.count | Should -Be 1
        }
        It "schemaread should not have select on schema testing before fix" {
            $schemaDropPermissionCheck.count | Should -Be 0
        }
        It "testuser Should not be in db_datareader before fix" {
            $userRevokeRoleCheck.member | Should -Be 0
        }
        It "schemaread Should  have alter on sp_perms before fix" {
            $userAddPermCheck.count | Should -Be 1
        }
        It "Results Should contain 3 Role errors" {
            $results.RolesResults.FailedCount | Should -Be 3
        }
        It "Role PesterTest should not exist before fix" {
            $roleDropCheck.count | Should -Be 0
        }
        It "schemaread Should Be a member of userrole" {
            $roleMemberCheck.member | Should -Be 1
        }
        
        $output = Reset-DssSecurity -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -database $script:database -TestResult $results

        $schemaAddCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaAddCheckSql
        $schemaDropPermissionCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaDropPermissionCheckSql
        $userRevokeRoleCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userRevokeRoleCheckSql
        $userAddPermCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userAddPermCheckSql
        $roleDropCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleDropCheckSql
        $roleMemberCheck = Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleMemberCheckSql

        It "Schema 'notwanted' Should Not Exist post fix (All Fixes)" {
            $schemaAddCheck.count | Should -Be 0
        }
        It "schemaread should have select on schema testing  post fix (All Fixes)" {
            $schemaDropPermissionCheck.count | Should -Be 1
        }
        It "testuser Should be in db_datareader post fix (All Fixes)" {
            $userRevokeRoleCheck.member | Should -Be 1
        }
        It "schemaread Should not have alter on sp_perms post fix (All Fixes)" {
            $userAddPermCheck.count | Should -Be 0
        }

        It "Role PesterTest should exist post fix (All Fixes)" {
            $roleDropCheck.count | Should -Be 1
        }
        It "schemaread Should Not Be a member of userrole post fix (All Fixes)" {
            $roleMemberCheck.member | Should -Be 0
        }

        $postResults = Invoke-DssTest -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -database $script:database -Config $config -Quiet

        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $schemaDropPermissionFixSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userAddPermFixSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $userRevokeRoleFixSql
        # Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleDropFixSql
        Invoke-DbaQuery -sqlinstance $script:appvsqlinstance -sqlcredential $script:appvsqlcredential -Database $script:database -Query $roleMemberFixSql
    }
}