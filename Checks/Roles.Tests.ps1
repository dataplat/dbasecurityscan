param (
    [object]$config,
    [string]$SqlInstance,
    [PSCredential]$SqlCredential,
    [String]$Database
)

$roles = Get-DbaDbRole -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database
$roleMembers = Get-DbaDbRoleMember -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database
$permissions = Get-DbaUserPermission -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database -IncludePublicGuest

ForEach ($case in $config.roles){
    Describe "Checking role $($case.rolename)" {
        It "$($case.rolename) Should Exist" {
            ($case.rolename -in $roles.name) | Should -BeTrue -Because "Role from config should be in db"
        }
    }

    Describe "Checking Role $($case.rolename) membership" {
        Foreach ($user in $case.members){
            It "$($user.username) Should be a member of $($case.rolename)" {
                ($rolemembers | Where-Object {$_.username -eq $user.username -and $_.role -eq $case.rolename}) | Should -BeTrue
            }
        }

        It "$($case.rolename) Should not contain members not defined in schema" {
            ($rolemembers | Where-Object {$_.role -eq $case.rolename -and $_.username -notin ($case.members.username)} | Measure-Object).count | Should -Be 0 -Because "No members should exist who aren't in the config "
        }
    
    }

    Describe "Checking Role $($case.rolename) permissions" {
        ForEach ($permission in $case.permissions) {
            It "Role $($case.rolename) Should have $($permission.permission) on $($permission.securable)" {
                ($permissions | Where-Object {$_.Grantee -eq $case.rolename -and $_.permission -eq $permission.permission -and $_.securable -eq $permission.securable -and $_.member -in $permission.member} | Measure-Object).count | Should -Be 1
            }
        }
    }
}