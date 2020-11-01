<# 
Description: Policy ensures that no user is granted direct permissions to any of the base tables in the database

Reason: Make sure all users are members of a db role 
#>

param (
    [string]$SqlInstance,
    [PSCredential]$SqlCredential,
    [String]$Database
)

Describe "Making sure 'No user permissions on base tables is true" {
    It "Should have 0 user permissions on base tables" {
        (Get-DbaPermission -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database | Where-Object {$_.GranteeType -eq 'SQL_USER' -and $_.SecurableType -eq 'USER_TABLE'}).count | Should -Be 0 -Because "Users should be accessing base tables via views or stored procedurs"
    }
}
