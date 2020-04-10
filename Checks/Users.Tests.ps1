param (
    [object]$config,
    [string]$SqlInstance,
    [PSCredential]$SqlCredential,
    [String]$Database
)

$dbUsers = Get-DbaDbUser -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database
$dbUserRoles = Get-DbaDbRoleMember -SqlInstance $sqlinstance -SqlCredential $SqlCredential -Database $database -IncludeSystemUser
# $dbRoles = Get-DbaDbRole -SqlInstance $sqlinstance -SqlCredential $SqlCredential -Database $database 
$testPermissions = Get-DbaUserPermission -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -IncludePublicGuest 
Describe "Test config against database" {
    Foreach ($case in $config.users) {
        Context "Checking $($case.username)" {
            It "$($case.username) should exist in database" {
                $case.username | Should -BeIn $dbUsers.Name -Because "User Should exist"
            }
            if (($case.roles | Measure-Object).count -gt 0){
                # Check user is in specified Roles
                Foreach ($role in $case.roles){
                    It "$($case.username) should be a member of $role (Config)" {
                        $role | Should -BeIn ($dbUserRoles | Where-Object {$_.Username -eq $case.username}).Role
                    }
                }
            }
            $testRoles = $dbUserRoles | where-Object {$_.UserName -eq $case.UserName}
            # Check the user isn't a member of any unspecified roles
            ForEach ($role in $testRoles){
                It "$($case.username) Should be in $($role.Role) (DB)" {
                    $role.Role | Should -BeIn $case.roles -Because "User should only be in the specified roles"
                }
            }

            if (($case.Permissions | Measure-Object).Count -ge 1) {
                # Go through to check the specified permissions are there
                Foreach($permission in $case.Permissions){
                    It "Should have assigned $($case.userName) permission $($permission.permission) on $($permission.securable) in $($permission.SchemaOwner)" {
                        ($testPermissions | Where-Object {$_.Grantee -eq $case.username -and $_.Securable -eq $permission.securable -and $_.permission -eq $permission.permission} | Measure-Object).count | Should -Be 1
                    }

                }
            }

            if (($testPermissions | Where-Object {$_.Grantee -eq $case.username} | Measure-Object).count -gt 0) {
            # Go through again to make sure no unspecified permissions are there
                $groupPermissions = $case.permissions | Group-Object schemaowner, securable, permission
                Foreach ($permission in $testPermissions | Where-Object { $_.Grantee -eq $case.username } ) {
                    It "User $($case.userName) Should Only have $($permission.permission) on $($permission.securable) in $($permission.SchemaOwner)" {
                        "$($permission.SchemaOwner), $($permission.securable), $($permission.permission)" -in $groupPermissions.name | Should -Be $True -Because "Should only have defined permissions"
                    }
                }
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