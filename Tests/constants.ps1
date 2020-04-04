if (Test-Path $HOME\dbaSecurityScan-constants.ps1) {
    Write-Verbose "$HOME\dbaSecurityScan-constants.ps1 found."
    . $HOME\dbaSecurityScan-constants.ps1
} else {
    if ($ENV:APPVEYOR -and $IsLinux) { 
        $script:appvModuleroot = '/home/appveyor/projects/dbasecurityscan/'
    } elseif ($ENV:APPVEYOR) {
        $script:appvModuleroot = 'C:\projects\dbasecurityscan\'
    } elseif ($IsLinux) {
        $script:appvSqlInstance = "localhost:1433\SQL2019"
    } else[
        $script:appvModuleroot = 'c:\github\dbasecurityscan'
        $script:appvSqlInstance = "localhost\SQL2019"
    ]

    $script:appvPassword = ConvertTo-SecureString 'P@$sw0rdling' -AsPlainText -Force
    $script:appvSqlCredential = New-Object System.Management.Automation.PSCredential ('sa', $appvPassword)
    $script:IgnoreSQLCMD = $true
}