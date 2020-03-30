if (Test-Path $HOME\dbaSecurityScan-constants.ps1) {
    Write-Verbose "$HOME\dbaSecurityScan-constants.ps1 found."
    . $HOME\dbaSecurityScan-constants.ps1
} else {
    if ($ENV:APPVEYOR -and $IsLinux) { 
        $script:appvSqlInstance = "localhost"
    } else {
        $script:appvSqlInstance = "localhost\sql2017"
    }
    if ($ENV:APPVEYOR -and $IsLinux) { 
        $script:appvModuleroot = '/home/appveyor/projects/dbasecurityscan/'
    } elseif ($ENV:APPVEYOR -and $IsWindows)  {
        $script:appvModuleroot = 'C:\projects\dbasecurityscan\'
    } else {
        $script:appvModuleroot = 'c:\github\dbasecurityscan'
    }
    $script:appvPassword = ConvertTo-SecureString 'Password12!' -AsPlainText -Force
    $script:appvSqlCredential = New-Object System.Management.Automation.PSCredential ('sa', $appvPassword)
    $script:IgnoreSQLCMD = $true
}