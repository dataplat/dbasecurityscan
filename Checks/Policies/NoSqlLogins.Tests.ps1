<# 
Description: Policy ensures that no login apart from sa is a SQL login

Reason: Want all user managed via ADS/windows
#>

param (
    [string]$SqlInstance,
    [PSCredential]$SqlCredential,
    [String]$Database
)

Describe "Making sure 'No user permissions on base tables is true" {
    It "Should have 0 user permissions on base tables" {
        (Get-DbaPermission -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database | Where-Object { $_.GranteeType -eq 'SQL_USER' -and $_.SecurableType -eq 'USER_TABLE' }).count | Should -Be 0 -Because "Users should be accessing base tables via views or stored procedurs"
    }
}
