if (Test-Path $HOME\dbaSecurityScan-constants.ps1) {
    Write-Verbose "$HOME\dbaSecurityScan-constants.ps1 found."
    . $HOME\dbaSecurityScan-constants.ps1
} else {
    $script:appvSqlInstance = "localhost\sql2017"
    if ($ENV:APPVEYOR -and $IsLinux) { 
        $script:appvModuleroot = 
    } elseif ($ENV:APPVEYOR -and $IsWindows)  {
        $script:appvModuleroot = '/home/appveyor/projects/dbasecurityscan/'
    } else {
        $script:appvModuleroot = 'C:\projects\dbasecurityscan\'
    }
    $script:appvPassword = ConvertTo-SecureString 'Password12!' -AsPlainText -Force
    $script:appvSqlCredential = New-Object System.Management.Automation.PSCredential ('sa', $appvPassword)
    $script:IgnoreSQLCMD = $false
}