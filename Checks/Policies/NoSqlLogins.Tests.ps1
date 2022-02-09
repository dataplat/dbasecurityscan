<# 
Description: Policy ensures that no login apart from sa is a SQL login

Reason: Want all user managed via ADS/windows
#>

param (
    [string]$SqlInstance,
    [PSCredential]$SqlCredential,
    [String]$Database
)

Describe "Making sure all logins except SA are windows logins" {
    It "Should have 0 logins that aren't windows logins or SA" {
        (Get-DbaLogin -sqlinstance $SqlInstance -SqlCredential $SqlCredential | Where-Object { $_.LoginType -ne 'WindowsUser' -and $_.name -ne 'sa'}).count | Should -Be 0 -Because "The only SQL login should be SA, all others should be Windows accounts"
    }
}
