$sqlUser='sql1admin'
$sqlPasswd= ConvertTo-SecureString 'y^ezoBWAtK9wb*8Lyrrpted#' -AsPlainText -Force
$sqlCred=New-Object System.Management.Automation.PSCredential ($sqlUser, $sqlPasswd)
$sqlInstance='sb-sql1.sb.local\sql1'
$appsplat=@{
  SqlInstance =$sqlInstance
  SqlCredential = $sqlCred
}

import-module ./dbasecurityscan.psd1



$srv = Connect-DbaInstance @appsplat
$c = Get-Content './Tests/scenarios/roles1/roles1.sql' -Raw
$srv.Databases['master'].ExecuteNonQuery($c)

# create a new config
$config = New-DssConfig @appsplat -Database roles1

#remove config file
Remove-Item ./dss.json -Force

#write out the config to a file
$config | ConvertTo-Json -Depth 5 | Out-File ./dss.json

#take a look at the config file in vs code
code ./dss.json

#Add an extra permission to the role
Invoke-DbaQuery @appsplat -Database roles1 -Query "grant execute on sp_test to removerole"
?
#run a compare against the config.
$results = Invoke-DssTest @appsplat -Database roles1 -Config $config

#errors were returned so try a dryrun to see how they could be fixed
$dryRun = Reset-DssSecurity @appsplat -Database roles1 -TestResults $results -OutputOnly

#If happy with the dry run, tell the command to fix the issues
$realRun = Reset-DssSecurity @appsplat -Database roles1 -TestResults $results

#Run a final test to check that everything is in line again
$final = Invoke-DssTest @appsplat -Database roles1 -Config $config