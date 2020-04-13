$commandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
. "$PSScriptRoot\constants.ps1"

$script:database = 'normal1'

Describe "$commandName Integration Tests" {
    BeforeAll {
        # Reset database
        $srv = Connect-DbaInstance -SqlInstance $Script:appvSqlInstance -SqlCredential $Script:appvSqlCredential
        $query = Get-Content '.\Tests\scenarios\normal1\normal1.sql' -raw
        Remove-DbaDatabase -SqlInstance $Script:appvSqlInstance -SqlCredential $Script:appvSqlCredential -Database $script:database -Confirm:$false
        $srv.Databases['master'].ExecuteNonQuery($query)
    
        $config = New-DssConfig @script:appsplat -database $script:database -UserConfig
    }
    Context "Test removing errant user" {
        $config = New-DssConfig @script:appsplat -database $script:database -UserConfig
        New-DbaDbUser @script:appsplat -Database $script:database -UserName baduser
        $results = Invoke-DssTest @script:appsplat -database $script:database -UserConfig -Output -Config $config -Quiet
        It "BadUser should exist before fix" {
            'baduser' -in (Get-DbaDbUser @script:appsplat -Database $script:database).name | Should -Be $True
        }
        Reset-DssUserSecurity @script:appsplat -database $script:database -TestResult $results
        It "BadUser should not exist after fix" {
            'baduser' -in (Get-DbaDbUser @script:appsplat -Database $script:database).name | Should -Be $False
        }
    }

    Context "Test adding user to correct role" {
        Remove-DbaDbRoleMember @script:appsplat -database $script:database -User testuser -Role db_datareader -confirm:$false
        $results = Invoke-DssTest @script:appsplat -database $script:database -UserConfig -Output -Config $config -Quiet
        It "Results should contain 1 error" {
           $results.UsersResults.FailedCount | Should -Be 1
        }
        It "testuser Should not be in db_datareader before fix" {
            'testuser' -in (Get-DbaDbRoleMember @script:appsplat -database $script:database -role db_datareader).Username | Should -Be $False
        }
        Reset-DssUserSecurity @script:appsplat -database $script:database -TestResult $results
        It "testuser Should be in db_datareader after fix" {
            'testuser' -in (Get-DbaDbRoleMember @script:appsplat -database $script:database -role db_datareader).Username | Should -Be $True
        }
    }

    Context "Test adding missing permissions" {
        Invoke-DbaQuery @script:appsplat -Database $script:database -Query 'revoke ALTER on sp_perms to testuser'
        $results = Invoke-DssTest @script:appsplat -database $script:database -UserConfig -Output -Config $config -Quiet
        It "Permission should not exist before fix" {
            (Get-DbaUserPermission @Script:appsplat -Database $script:database -IncludePublicGuest | Where-Object { $_.Grantee -eq 'testuser' -and $_.Permission -eq 'ALTER' -and $_.Securable -eq 'sp_perms' } | Measure-Object).count | Should -Be 0
        }
        Reset-DssUserSecurity @script:appsplat -database $script:database -TestResult $results
        It "Permission should exist after fix" {
            (Get-DbaUserPermission @Script:appsplat -Database $script:database -IncludePublicGuest | Where-Object { $_.Grantee -eq 'testuser' -and $_.Permission -eq 'ALTER' -and $_.Securable -eq 'sp_perms' } | Measure-Object).count | Should -Be 1
        }

    }

    Context "Test Removing extraneous permissions" {
        Invoke-DbaQuery @script:appsplat -Database $script:database -Query 'Grant ALTER on sp_perms to readonly'
        $results = Invoke-DssTest @script:appsplat -database $script:database -UserConfig -Output -Config $config -Quiet
        It "Permission should exist before fix" {
            (Get-DbaUserPermission @Script:appsplat -Database $script:database -IncludePublicGuest | Where-Object { $_.Grantee -eq 'readonly' -and $_.Permission -eq 'ALTER' -and $_.Securable -eq 'sp_perms' } | Measure-Object).count | Should -Be 1
        }
        Reset-DssUserSecurity @script:appsplat -database $script:database -TestResult $results
        It "Permission should not exist after fix" {
            (Get-DbaUserPermission @Script:appsplat -Database $script:database -IncludePublicGuest | Where-Object { $_.Grantee -eq 'readonly' -and $_.Permission -eq 'ALTER' -and $_.Securable -eq 'sp_perms' } | Measure-Object).count | Should -Be 0
        }

    }
    AfterAll {
        # Reset $script:database database
        $query = Get-Content '.\Tests\scenarios\normal1\normal1.sql' -raw
        Remove-DbaDatabase -SqlInstance $Script:appvSqlInstance -SqlCredential $Script:appvSqlCredential -Database $script:database -Confirm:$false
        $srv.Databases['master'].ExecuteNonQuery($query)
    }    

}


