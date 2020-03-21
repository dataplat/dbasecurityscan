if (Test-Path $HOME\dbaSecurityScan-constants.ps1) {
    Write-Verbose "$HOME\dbaSecurityScan-constants.ps1 found."
    . $HOME\dbaSecurityScan-constants.ps1
} else {
    $script:appvSqlInstance = 'localhost\2017'
    $script:appvModuleroot = 'c:\github\dbaSecurityScan'
    $script:appvPassword = ConvertTo-SecureString 'Password12!' -AsPlainText -Force
    $script:appvSqlCredential = New-Object System.Management.Automation.PSCredential ('sa', $appvPassword)
}