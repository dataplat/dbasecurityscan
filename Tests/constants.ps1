if (Test-Path $HOME\dbaSecurityScan-constants.ps1) {
    Write-Verbose "$HOME\dbaSecurityScan-constants.ps1 found."
    . $HOME\dbaSecurityScan-constants.ps1
} else {
    if ($ENV:APPVEYOR -and $IsLinux) { 
        $script:appvModuleroot = '/home/appveyor/projects/dbasecurityscan/'
    } elseif ($ENV:APPVEYOR) {
        $script:appvModuleroot = 'C:\projects\dbasecurityscan\'
    } else {
        $script:appvModuleroot = 'c:\github\dbasecurityscan'
    }
    $script:appvSqlInstance = "localhost\SQL2019"
    $script:appvPassword = ConvertTo-SecureString 'P@ssword!!' -AsPlainText -Force
    $script:appvSqlCredential = New-Object System.Management.Automation.PSCredential ('sa', $appvPassword)
    $script:IgnoreSQLCMD = $true
}