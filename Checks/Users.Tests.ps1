param (
    [object]$config,
    [string]$SqlInstance,
    [PSCredential]$SqlCredential,
    [String]$Database
)

$dbUsers = Get-DbaDbUser -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database
$dbUserRoles = Get-DbaDbRoleMember -SqlInstance $sqlinstance -SqlCredential $SqlCredential -Database $database -IncludeSystemUser
# $dbRoles = Get-DbaDbRole -SqlInstance $sqlinstance -SqlCredential $SqlCredential -Database $database 
Describe "Test config against database" {
    Foreach ($case in $config.users) {
        Context "Checking $($case.username)" {
            It "$($case.username) should exist in database" {
                $case.username | Should -BeIn $dbUsers.Name -Because "User Should exist"
            }
            if ($case.roles.count -gt 0){
                Foreach ($role in $case.roles){
                    It "$($case.username) should be a member of $role (Config)" {
                        $role | Should -BeIn ($dbUserRoles | Where-Object {$_.Username -eq $case.username}).Role
                    }
                }
            }
            $testRoles = $dbUserRoles | where-Object {$_.UserName -eq $case.UserName}
            ForEach ($role in $testRoles){
                It "$($case.username) Should be in $($role.Role) (DB)" {
                    $role.Role | Should -BeIn $case.roles -Because "User should only be in the specified roles"
                }
            }

            if ($case.Permissions.Count -ge 1) {
                $testPermissions =  Get-DbaUserPermission -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -IncludePublicGuest
                # Go through to check the specified permissions are there
                Foreach($permission in $case.Permissions){
                    It "Should have assigned $($case.userName) permission $($permission.permission) on $($permission.securable)" {
                        ($testPermissions | Where-Object {$_.Grantee -eq $case.username -and $_.Securable -eq $permission.securable -and $_.permission -eq $permission.permission} | Measure-Object).count | Should -Be 1
                    }

                }
                # Go through again to make sure no other permissions are there
                #Foreach ($permission in $testPermissions){
                #     It "Should not have assigned $($case.userName) $($permission.permission) on $($permission.securable)" {
                #         ($testPermissions | Where-Object {$_.Grantee -eq $case.username -and $_.Securable -notin ($case.permissions.securable) -and $_.permission -notin ($case.permissions.permission)} | Measure-Object).Count | Should -Be 0 -Because "Should only have defined permissions"
                #     }
                #    $testPermissions | Where-Object {$_.Grantee -eq $case.username -and $_.Securable -notin ($case.permissions.securable) -and $_.permission -notin ($case.permissions.permission)}
            # }
            }
        }
    }
}

Describe "Test databse against config" {
    Context "Checking for no extra objects" {
        ForEach ($user in $dbUsers) {
            It "Database user $($user.name) should be in config" {
                $user.name -in $config.users.username | Should -Be True
            }
        }
    }
}