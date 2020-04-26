$commandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
. "$PSScriptRoot\constants.ps1"

$script:database = 'roles1'

Describe "$commandName Integration Tests" {
    BeforeAll {
        # Reset normal1 database

        $srv = Connect-DbaInstance -SqlInstance $Script:appvSqlInstance -SqlCredential $Script:appvSqlCredential
        $query = Get-Content '.\Tests\scenarios\roles1\roles1.sql' -raw
        Remove-DbaDatabase -SqlInstance $Script:appvSqlInstance -SqlCredential $Script:appvSqlCredential -Database $script:database -Confirm:$false
        $srv.Databases['master'].ExecuteNonQuery($query)


    }
    Context "Add a missing Role" {
        $config = New-DssConfig @script:appsplat -Database $database -RoleConfig
        $null = Remove-DbaDbRole @script:appsplat -database $database -Role RemoveRole -Confirm:$false

        $role = Get-DbaDbRole @script:appsplat -database $database -Role RemoveRole
        It "Role should not exist before test"{
            $null -eq $role | Should -BeTrue
        }
        $results = Invoke-DssTest @script:appsplat -Database $database -Config $config -RoleConfig -Quiet
        $fix = Reset-DssRoleSecurity @script:appsplat -Database $database -TestResult $results
        $role = Get-DbaDbRole @script:appsplat -database $database -Role RemoveRole
        It "Should have fixed 1 error" {
            ($fix | Measure-Object).count | Should -Be 1
        }
        It "Should have fixed the right error" {
            $fix.Resolution -eq "Adding Role" | Should -BeTrue
        }
        It "Role Should exist post fix" {
            $role.name -eq 'RemoveRole' | Should -BeTrue
        }
        It "userroole Should Exist" {
            $null -eq (Get-DbaDbRole @Script:appsplat -database roles1 -role userrole) | Should -BeFalse
        }
    }

    Context "Add a missing RoleMember" {
        $config = New-DssConfig @script:appsplat -Database $database -RoleConfig
        $null = Remove-DbaDbRoleMember @script:appsplat -Database $database -Role userrole -User Alice -Confirm:$false

        $roleMember = Get-DbaDbRoleMember @script:appsplat -Database $database -Role userrole | Where-Object { $_.Username -eq 'Alice'}
        It "User should not be a member before test"{
            $null -eq $roleMember | Should -BeTrue
        }
        $results = Invoke-DssTest @script:appsplat -Database $database -Config $config -RoleConfig -Quiet
        $fix = Reset-DssRoleSecurity @script:appsplat -Database $database -TestResult $results
        $roleMember = Get-DbaDbRoleMember @script:appsplat -Database $database -Role userrole | Where-Object { $_.Username -eq 'Alice' }
        It "Should have fixed 1 error" {
            ($fix | Measure-Object).count | Should -Be 1
        }
        It "Should have fixed the right error" {
            $fix.Resolution -eq "Adding User to Role" | Should -BeTrue
        }
        It "Role Should exist post fix" {
            $rolemember.UserName -eq 'Alice' | Should -BeTrue
        }
        It "userroole Should Exist" {
            $null -eq (Get-DbaDbRole @Script:appsplat -database roles1 -role userrole) | Should -BeFalse
        }
    }

    Context "Grant a missing Role permission" {
        $config = New-DssConfig @script:appsplat -Database $database -RoleConfig

        $revokeSql = "Revoke execute on sp_test from userrole"
        $null = Invoke-DbaQuery @script:appsplat -Database roles1 -Query $revokeSql

        $perm = Get-DbaUserPermission @script:appsplat -Database $database -IncludePublicGuest  | Where-Object { $_.GranteeType -eq 'DATABASE_ROLE' -and $_.Grantee -eq 'userrole' -and $_.Securable -eq 'sp_test' -and $_.Permission -eq 'EXECUTE'} 

        It "Permission Should not exist before test" {
            $null -eq $perm | Should -BeTrue    
        } 
        $results = Invoke-DssTest @script:appsplat -Database $database -Config $config -RoleConfig -Quiet
        $fix = Reset-DssRoleSecurity @script:appsplat -Database $database -TestResult $results
        $perm = Get-DbaUserPermission @script:appsplat -Database $database -IncludePublicGuest | Where-Object { $_.GranteeType -eq 'DATABASE_ROLE' -and $_.Grantee -eq 'userrole' -and $_.Securable -eq 'sp_test' -and $_.Permission -eq 'EXECUTE' } 

        It "Should have fixed 1 error" {
            ($fix | Measure-Object).count | Should -Be 1
        }
        It "Should have fixed the right error" {
            $fix.Resolution -eq "Granting permission to role" | Should -BeTrue
        }
        It "Permission Should exist post test"{
            $null -eq $perm | Should -BeFalse
        }
        It "userroole Should Exist" {
            $null -eq (Get-DbaDbRole @Script:appsplat -database roles1 -role userrole) | Should -BeFalse
        }
    }

    Context "Remove an extraneous Role" {
        
        $config = New-DssConfig @script:appsplat -Database $database -RoleConfig
        $addRole = New-DbaDbRole @script:appsplat -Database $database -Role NewTestRole
        
        $role = Get-DbaDbRole @script:appsplat -Database $database -Role NewTestRole
        It "Role NewTestRole Should exist before test" {
            $null -eq $role | Should -BeFalse
        }
        $results = Invoke-DssTest @script:appsplat -Database $database -Config $config -RoleConfig -Quiet
        $fix = Reset-DssRoleSecurity @script:appsplat -Database $database -TestResult $results
        $role = Get-DbaDbRole @script:appsplat -Database $database -Role NewTestRole
        It "Should have fixed 1 error" {
            ($fix | Measure-Object).count | Should -Be 1
        }
        It "Should have fixed the right error" {
            $fix.Resolution -eq "Remove Role" | Should -BeTrue
        }
        It "Role Should not exist post test"{
            $null -eq $role | Should -BeTrue
        }
    }

    Context "Removing an extraneous Role Member" {
        $config = New-DssConfig @script:appsplat -Database $database -RoleConfig
        $null = Add-DbaDbRoleMember @script:appsplat -Database $database -Role userrole -User carol -confirm:$false
        It "Carol Should be in Role userrole before fix" {
            (Get-DbaDbRoleMember @script:appsplat -Database $database -Role userrole | Where-Object {$_.UserName -eq 'carol'} | Measure-Object).count | Should -Be 1
        }
        $results = Invoke-DssTest @script:appsplat -Database $database -Config $config -RoleConfig -Quiet
        $fix = Reset-DssRoleSecurity @script:appsplat -Database $database -TestResult $results
        It "Should have fixed 1 error" {
            ($fix | Measure-Object).count | Should -Be 1
        }
        It "Should have fixed the right error" {
            $fix.Resolution -eq "Removing User from Role" | Should -BeTrue
        }
        It "Carol Should Not Be in Role userrole post fix" {
            $null -ne (Get-DbaDbRoleMember @script:appsplat -Database $database -Role userrole | Where-Object {$_.UserName -eq 'carol'} | Measure-Object).count | Should -BeTrue 
        }
    }


    Context "Revoke an extraneous Role Permission" {
        $config = New-DssConfig @script:appsplat -Database $database -RoleConfig

        $grantSql = "grant execute on sp_test to RemoveRole"
        Invoke-DbaQuery @script:appsplat -database $database -Query $grantSql
        $perm = Get-DbaUserPermission @script:appsplat -Database $database -IncludePublicGuest | Where-Object { $_.GranteeType -eq 'DATABASE_ROLE' -and $_.Grantee -eq 'RemoveRole' -and $_.Securable -eq 'sp_test' -and $_.Permission -eq 'EXECUTE' } 
        It "Permission Should exist before Test" {
            $null -eq $perm | Should -BeFalse
        }
        $results = Invoke-DssTest @script:appsplat -Database $database -Config $config -RoleConfig -Quiet
        $fix = Reset-DssRoleSecurity @script:appsplat -Database $database -TestResult $results
        It "Should have fixed 1 error" {
            ($fix | Measure-Object).count | Should -Be 1
        }
        It "Should have fixed the right error" {
            $fix.Resolution -eq "Revoking permission from role" | Should -BeTrue
        }
        $perm = Get-DbaUserPermission @script:appsplat -Database $database -IncludePublicGuest | Where-Object { $_.GranteeType -eq 'DATABASE_ROLE' -and $_.Grantee -eq 'RemoveRole' -and $_.Securable -eq 'sp_test' -and $_.Permission -eq 'EXECUTE' } 
        It "Permission Should Not exist post Test" {
            $null -eq $perm | Should -BeTrue
        }
    }
}