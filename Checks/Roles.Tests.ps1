param (
    [object]$config,
    [string]$SqlInstance,
    [PSCredential]$SqlCredential,
    [String]$Database,
    [switch]$IgnoreConfigCheck,
    [Switch]$IgnoreDatabaseCheck,
    [Switch]$IncludeSystemObjects
)

$roles = Get-DbaDbRole -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database
$roleMembers = Get-DbaDbRoleMember -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database
$permissions = Get-DbaUserPermission -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -IncludePublicGuest -IncludeSystemObjects:$IncludeSystemObjects | Where-Object {$_.GranteeType -eq 'DATABASE_ROLE'} | Select-Object permission, securable, grantee, schemaOwner -unique

if ($IgnoreConfigCheck -ne $true) {
    Describe "Testing role config against database" {
        ForEach ($case in $config.roles){
            Context "Checking role $($case.rolename)" {
                It "Role $($case.rolename) Should Exist (Config)" {
                    ($case.rolename -in $roles.name) | Should -BeTrue -Because "Role from config should be in db"
                }
            }

            Context "Checking Role $($case.rolename) membership" {
                Foreach ($user in $case.members){
                    It "User $($user.username) Should be a member of role $($case.rolename) (Config)" {
                        ($rolemembers | Where-Object {$_.username -eq $user.username -and $_.role -eq $case.rolename}) | Should -BeTrue
                    }
                }
            }

            Context "Checking Role $($case.rolename) permissions" {
                ForEach ($permission in $case.permissions) {
                    It "Role $($case.rolename) Should have $($permission.permission) on $($permission.securable) (Config)" {
                        ($permissions | Where-Object {$_.Grantee -eq $case.rolename -and $_.permission -eq $permission.permission -and $_.securable -eq $permission.securable -and $_.SchemaOwner -eq $permission.SchemaOwner}| Measure-Object).count | Should -Be 1
                    }
                }
            }
        }
    }
}

if ($IgnoreDatabaseCheck -ne $True) {
    Describe "Testing roles database against config" {
        ForEach ($role in $roles ) {
            Context "Checking for roles not in config (DB)" {
                It "Role $($role.Name) Should Be in config (DB)" {
                    $role.Name -in ($config.roles.rolename) | Should -BeTrue
                }
            }

            Context "Checking for $role role members not in config (DB)" {
                Foreach ($rm in ($roleMembers | Where-Object {$_.Role -eq $role.name})) {
                    It "Rolemember $($rm.UserName) Should Be in role $($role.name) (DB)" {
                        $rm.UserName -in ($config.roles | Where-Object {$_.RoleName -eq $role.name}).Members.username | Should -BeTrue
                    }
                }
            }

            Context "Testing Role $role permissions against config (DB)" {
                $rps = ($config.roles | Where-Object {$_.rolename -eq $role.name}).permissions | Group-Object Grantee, Permission, SchemaOwner, Securable
                ForEach ($perm in $permissions | Where-Object {$_.Grantee -eq $role.name}) {
                    It "Role $($role.name) should have $($perm.permission) on $($perm.securable) in schema $($perm.SchemaOwner) (DB)"{
                        "$($perm.Grantee), $($perm.permission), $($perm.SchemaOwner), $($perm.securable)" -in $rps.name | Should -BeTrue
                    }
                }
            }
        }
    }
}