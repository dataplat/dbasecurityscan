$commandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
. "$PSScriptRoot\constants.ps1"



Describe "$commandName Integration Tests" {
    BeforeAll {
        # Reset normal1 database
        $srv = Connect-DbaInstance -SqlInstance $Script:appvSqlInstance -SqlCredential $Script:appvSqlCredential
        $query = Get-Content '.\Tests\scenarios\normal1\normal1.sql' -raw
        Remove-DbaDatabase -SqlInstance $Script:appvSqlInstance -SqlCredential $Script:appvSqlCredential -Database normal1 -Confirm:$false
        $srv.Databases['master'].ExecuteNonQuery($query)
    
        $config = New-DssConfig @script:appsplat -database normal1 -UserConfig
    }
    Context "Test removing errant user" {
        $config = New-DssConfig @script:appsplat -database normal1 -UserConfig
        New-DbaDbUser @script:appsplat -Database normal1 -UserName baduser
        $results = Invoke-DssTest @script:appsplat -database normal1 -UserConfig -Output -Config $config -Quiet
        It "BadUser should exist before fix" {
            'baduser' -in (Get-DbaDbUser @script:appsplat -Database normal1).name | Should -Be $True
        }
        Reset-DssUserSecurity @script:appsplat -database normal1 -TestResult $results
        It "BadUser should not exist after fix" {
            'baduser' -in (Get-DbaDbUser @script:appsplat -Database normal1).name | Should -Be $False
        }
    }

    Context "Test adding user to correct role" {
        Remove-DbaDbRoleMember @script:appsplat -database normal1 -User testuser -Role db_datareader -confirm:$false
        $results = Invoke-DssTest @script:appsplat -database normal1 -UserConfig -Output -Config $config -Quiet
        It "Results should contain 1 error" {
           $results.UsersResults.FailedCount | Should -Be 1
        }
        It "testuser Should not be in db_datareader before fix" {
            'testuser' -in (Get-DbaDbRoleMember @script:appsplat -database normal1 -role db_datareader).Username | Should -Be $False
        }
        Reset-DssUserSecurity @script:appsplat -database normal1 -TestResult $results
        It "testuser Should be in db_datareader after fix" {
            'testuser' -in (Get-DbaDbRoleMember @script:appsplat -database normal1 -role db_datareader).Username | Should -Be $True
        }
    }

    Context "Test adding missing permissions" {
        Invoke-DbaQuery @script:appsplat -Database normal1 -Query 'revoke ALTER on sp_perms to testuser'
        $results = Invoke-DssTest @script:appsplat -database normal1 -UserConfig -Output -Config $config -Quiet
        It "Permission should not exist before fix" {
            (Get-DbaUserPermission @Script:appsplat -Database normal1 -IncludePublicGuest | Where-Object { $_.Grantee -eq 'testuser' -and $_.Permission -eq 'ALTER' -and $_.Securable -eq 'sp_perms' } | Measure-Object).count | Should -Be 0
        }
        Reset-DssUserSecurity @script:appsplat -database normal1 -TestResult $results
        It "Permission should exist after fix" {
            (Get-DbaUserPermission @Script:appsplat -Database normal1 -IncludePublicGuest | Where-Object { $_.Grantee -eq 'testuser' -and $_.Permission -eq 'ALTER' -and $_.Securable -eq 'sp_perms' } | Measure-Object).count | Should -Be 1
        }

    }

    Context "Test Removing extraneous permissions" {
        Invoke-DbaQuery @script:appsplat -Database normal1 -Query 'Grant ALTER on sp_perms to readonly'
        $results = Invoke-DssTest @script:appsplat -database normal1 -UserConfig -Output -Config $config -Quiet
        It "Permission should exist before fix" {
            (Get-DbaUserPermission @Script:appsplat -Database normal1 -IncludePublicGuest | Where-Object { $_.Grantee -eq 'readonly' -and $_.Permission -eq 'ALTER' -and $_.Securable -eq 'sp_perms' } | Measure-Object).count | Should -Be 1
        }
        Reset-DssUserSecurity @script:appsplat -database normal1 -TestResult $results
        It "Permission should not exist after fix" {
            (Get-DbaUserPermission @Script:appsplat -Database normal1 -IncludePublicGuest | Where-Object { $_.Grantee -eq 'readonly' -and $_.Permission -eq 'ALTER' -and $_.Securable -eq 'sp_perms' } | Measure-Object).count | Should -Be 0
        }

    }
    AfterAll {
        # Reset normal1 database
        $query = Get-Content '.\Tests\scenarios\normal1\normal1.sql' -raw
        Remove-DbaDatabase -SqlInstance $Script:appvSqlInstance -SqlCredential $Script:appvSqlCredential -Database normal1 -Confirm:$false
        $srv.Databases['master'].ExecuteNonQuery($query)
    }    

}


