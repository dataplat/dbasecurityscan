$commandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
. "$PSScriptRoot\constants.ps1"

$script:database = 'objects1'

Describe "$commandName Integration Tests" {
    BeforeAll {
        # Reset database
        $srv = Connect-DbaInstance -SqlInstance $Script:appvSqlInstance -SqlCredential $Script:appvSqlCredential
        $query = Get-Content '.\Tests\scenarios\objects1\objects1.sql' -raw
        Remove-DbaDatabase -SqlInstance $Script:appvSqlInstance -SqlCredential $Script:appvSqlCredential -Database $script:database -Confirm:$false
        $srv.Databases['master'].ExecuteNonQuery($query)
    
        $config = New-DssConfig @script:appsplat -database $script:database -ObjectConfig
    }

        Context "Test removing errant object permission" {
            $config = New-DssConfig @script:appsplat -database $script:database -ObjectConfig
            $sqlQuery = "GRANT execute on dbo.sp_test to user2"
            $sqlCheckQuery = "select 
                                count(1) as result
                            from 
                                sys.database_permissions dp 
                            where 
                                object_name(major_id)='sp_test' and 
                                USER_NAME(grantee_principal_id)='user2' and 
                                permission_name='EXECUTE'
                            "
            $null = Invoke-DbaQuery @script:appsplat -database $script:database -Query $sqlQuery
            $results = Invoke-DssTest @script:appsplat -database $script:database -ObjectConfig -Config $config -Quiet
            It "Permission should exist before fix" {
                $check = Invoke-DbaQuery @script:appsplat -database $script:database -Query $sqlCheckQuery
                $check.result | Should -Be 1
            }
            Reset-DssObjectSecurity @script:appsplat -database $script:database -TestResult $results
            It "Permission should not exist after fix" {
                $check = Invoke-DbaQuery @script:appsplat -database $script:database -Query $sqlCheckQuery
                $check.result | Should -Be 0
            }
        }

        Context "Test Adding missing object permission" {
            $config = New-DssConfig @script:appsplat -database $script:database -ObjectConfig
            $sqlQuery = "revoke execute on dbo.sp_test from user1"
            $sqlCheckQuery = "select 
                                count(1) as result
                            from 
                                sys.database_permissions dp 
                            where 
                                object_name(major_id)='sp_test' and 
                                USER_NAME(grantee_principal_id)='user1' and 
                                permission_name='EXECUTE'
                            "
            $null = Invoke-DbaQuery @script:appsplat -database $script:database -Query $sqlQuery
            $results = Invoke-DssTest @script:appsplat -database $script:database -ObjectConfig -Config $config -Quiet
            It "Permission Should not exist before fix" {
                $check = Invoke-DbaQuery @script:appsplat -database $script:database -Query $sqlCheckQuery
                $check.result | Should -Be 0
            }
            Reset-DssObjectSecurity @script:appsplat -database $script:database -TestResult $results
            It "Permission Should exist after fix" {
                $check = Invoke-DbaQuery @script:appsplat -database $script:database -Query $sqlCheckQuery
                $check.result | Should -Be 1
            }
        }

    }
