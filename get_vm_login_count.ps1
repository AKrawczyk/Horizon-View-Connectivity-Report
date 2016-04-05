#####
## 07/03/2016
# Created By: Aaron Krawczyk - Aaron.krawczyk@cit.ie
# Based on Script Created By: Andre Leibovici - @andreleibovici - myvirtualcloud.net
#
# EXAMPLE
# Runuing on Connection Broker as View admin
# .\get_vm_login_count
######

# Function to write logs to file and screen
Function Write-And-Log {
 
[CmdletBinding()]
Param(
   [Parameter(Mandatory=$True,Position=1)]
   [ValidateNotNullOrEmpty()]
   [string]$LogFile,
   [Parameter(Mandatory=$True,Position=2)]
   [ValidateNotNullOrEmpty()]
   [string]$line,
 
   [Parameter(Mandatory=$False,Position=3)]
   [int]$Severity=0,
 
   [Parameter(Mandatory=$False,Position=4)]
   [string]$type="terse"
 
  
)
 
$timestamp = (Get-Date -Format ("[yyyy-MM-dd HH:mm:ss] "))
$ui = (Get-Host).UI.RawUI
 
switch ($Severity) {
 
        {$_ -gt 0} {$ui.ForegroundColor = "red"; $type ="full"; $LogEntry = $timestamp + ":Error: " + $line; break;}
        {$_ -eq 0} {$ui.ForegroundColor = "green"; $LogEntry = $timestamp + ":Info: " + $line; break;}
        {$_ -lt 0} {$ui.ForegroundColor = "yellow"; $LogEntry = $timestamp + ":Warning: " + $line; break;}
 
}
switch ($type) {
  
        "terse"   {Write-Output $LogEntry; break;}
        "full"    {Write-Output $LogEntry; $LogEntry | Out-file $LogFile -Append; break;}
        "logonly" {$LogEntry | Out-file $LogFile -Append; break;}
    
}
 
$ui.ForegroundColor = "white"
 
}

#variables
$ScriptRoot = Split-Path $MyInvocation.MyCommand.Path
$StartTime = Get-Date -Format "yyyyMMddHHmmss_"
$logdir = $ScriptRoot + "\Logs\"
$logfilename = $logdir + "VM_Login_Count.log"
$logfilename2 = $logdir + "VM_Connection_Count.csv"
$logfilename3 = $logdir + "User_Connection_Count.csv"
$now = (Get-Date).AddDays(0)
$LoginTables =@()
$LoginSummerys =@()

#of course you need to adjust variables below.
$startdate = (Get-Date).AddDays(-1)
$DisplayDate = Get-Date $startdate -Format "dddd dd MMMM yyyy"
$emailto = "cloudAdmin@company.com"
$emailcc = "Admin@company.com"
$emailfrom = "ConnectionServer@company.com"
$smtpserver = "smtp.company.com"
 
#hit ENTER.
$cr_lf = "`r`n"
 
#start PowerShell transcript
#Start-Transcript -Path $transcriptfilename

#test for log directory, create if needed
if ( -not (Test-Path $logdir)) {
New-Item -type directory -path $logdir 2>&1 > $null
}

Remove-Item -Path ($logdir + "\*.*") -Confirm:$false -Force:$true -ErrorAction SilentlyContinue 2>&1 > $null

#load VMware PowerCLI snap-in
$vmsnapin = Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue
$Error.Clear()

#Checks if the snap-in loaded and logs any issues or exits if snapin did not load
if ($vmsnapin -eq $null) {
Add-PSSnapin VMware.VimAutomation.Core
if ($error.Count -eq 0) {
write-and-log $logfilename "PowerCLI VimAutomation.Core Snap-in was successfully enabled." 0 "terse"
}
else{
write-and-log $logfilename "Could not enable PowerCLI VimAutomation.Core Snap-in, exiting script" 1 "terse"
Exit
}
}
else{
write-and-log $logfilename "PowerCLI VimAutomation.Core Snap-in is already enabled" 0 "terse"
}
 
#load View PowerCLI snap-in
$viewsnapin = Get-PSSnapin VMware.View.Broker -ErrorAction SilentlyContinue
$Error.Clear()

#Checks if the snap-in loaded and logs any issues or exits if snapin did not load
if ($viewsnapin -eq $null) {
Add-PSSnapin VMware.View.Broker
if ($error.Count -eq 0) {
write-and-log $logfilename "PowerCLI View.Broker Snap-in was successfully enabled." 0 "terse"
}
else{
write-and-log $logfilename "Could not enable PowerCLI View.Brokere Snap-in, exiting script" 1 "terse"
Exit
}
}
else{
write-and-log $logfilename "PowerCLI View.Broker Snap-in is already enabled" 0 "terse"
}

$error.clear()

#This Function merges data gathered from events and dekstops, outputting new object containing the following properties - Machine_id,UserDisplayName,Pool,Hostname 
function EventToDesktop {
  param(
    $Events,
    $Desktops
  )

  foreach ( $row1 in $Events ) {
    foreach ( $row2 in $Desktops ) {
      if ( $row1.machineid -eq $row2.machine_id ) {
        # Begin Merger of Events and Desktops
        New-Object PSCustomObject -Property @{
          "Machine_id" = $row1.machineid
          "UserDisplayName" = $row1.userdisplayname
          "Pool" = $row2.pool_id
          "Hostname" = $row2.name
        } | Select-Object Machine_id,UserDisplayName,Pool,Hostname
      }
    }
  }
}        

# Starts a time to monitor how long the script takes to run	
$stop_watch = [Diagnostics.Stopwatch]::StartNew()

# Gets logs from View Events where the user CONNECTED or RECONNECTED
write-and-log $logfilename "Loading View Event Reports......." 0 "full"
$event = Get-EventReport -viewName user_events -startDate $startdate | Where {($_.eventtype -eq "AGENT_CONNECTED") -or ($_.eventtype -eq "AGENT_RECONNECTED")}

# Starts to merge the data gathered from the View Events Logs and combine them the data from the Get-DesktopVM view cmdlet
write-and-log $logfilename "Analysing View Event Reports for Connections from $startdate to $Now......." 0 "full"
$NewEvent = EventToDesktop $Event $(Get-DesktopVM)

# Creats object for output to csv, gets the connection count, gets the daily concurrency, the max concurrency and how many users connected
$Logins = $newevent | Group-Object -Property Hostname, Pool | Select-Object Count,@{n="Hostname";e={$_.Values[0]}},@{n="Pool";e={$_.Values[1]}} | Where-Object {$_.hostname}
$LoginCount = $Logins | Measure-Object -Property Count -sum | select-object -Property Sum
$sum = $LoginCount.sum
$ConcurrencyCount = Get-EventReport -viewName user_count_events -startDate ((Get-Date).AddDays(-1))  | select-object -Property usercount
$Concurrency = $ConcurrencyCount.usercount
$MaxConcurrencyCount = get-monitor | group-object totalsessionshigh | select-object name | where-object {$_.name}
$MaxConcurrency = $MaxConcurrencyCount.name
$Users = $newevent | Group-Object userdisplayname | Select-Object Count,@{n="UserID";e={$_.Values[0]}} | Where-Object {$_.userid}
$UserCount = $users | measure
$Usersum = $UserCount.Count

# Writes output to log file, csv and email
write-and-log $logfilename "vDesktop Daily Connection Count = $sum" 0 "full"
write-and-log $logfilename "vDesktop Users Connecting Daily = $Usersum" 0 "full"
write-and-log $logfilename "vDesktop Daily Concurrent Count = $concurrency" 0 "full"
write-and-log $logfilename "vDesktop Max Concurrent Count = $maxconcurrency" 0 "full"
 
$Logins | sort-object -Property Pool | Export-Csv -Path $logfilename2  -NoTypeInformation
$Users | sort-object -Property Pool | Export-Csv -Path $logfilename3  -NoTypeInformation

$messageadmin = "Hi All," + $cr_lf + $cr_lf
$messageadmin += ("Please see attachement for vDesktops connection list." + $cr_lf + $cr_lf)
$messageadmin += ("vDesktop Daily Connection Count = $sum" + $cr_lf)
$messageadmin += ("vDesktop Users Connecting Daily = $usersum" + $cr_lf)
$messageadmin += ("vDesktop Daily Concurrent Count = $concurrency" + $cr_lf)
$messageadmin += ("vDesktop Max Concurrent Count = $maxconcurrency" + $cr_lf + $cr_lf)
$messageadmin += ("Breakdown of vDesktop Pool Connections;" + $cr_lf)
$messageadmin += ("     Pool Name                          Number of Connections" + $cr_lf)
$messageadmin += ("     ---------                          ---------------------" + $cr_lf)

# Checks each pool and outputs the pool connects to log file and email
$Pools = Get-Pool
$Poolids = $NewEvent | Group-Object -Property Pool | Select-Object Count,@{n="Pool";e={$_.Values[0]}} | Where-Object {$_.Pool}
foreach ($pool in $pools){
$pool_id = $pool.pool_id
$PoolLog = $Poolids | where-object {$_.Pool -contains $Pool_id}
if ($PoolLog.pool -eq $Pool_id){
$PoolLogCount = $PoolLog.count
write-and-log $logfilename "Pool $pool_id has had $PoolLogCount Logins" 0 "full"
$messageadmin += ("     " + $pool_id.PadRight(35, ' ') + $PoolLogCount + $cr_lf)
}
else {
write-and-log $logfilename "Pool $pool_id has had 0 Logins" 0 "full"
$messageadmin += ("     " + $Pool_id.PadRight(35, ' ') + "0" + $cr_lf)
}
}

# Writes email signature
$messageadmin += $cr_lf
$messageadmin += ("Thank You" + $cr_lf)
$messageadmin += ("Cloud Support Team" + $cr_lf)
$messageadmin += ("IT" + $cr_lf)
$messageadmin += ("Company" + $cr_lf)
$messageadmin += ("-----------------------------------------------" + $cr_lf)  
$messageadmin += "E: CloudAdmin@company.com" 
 
#let's spam sysadmins further.
Send-mailmessage -to $emailto -cc $emailcc -from $emailfrom -subject "VDI Conectivity Report Dated $DisplayDate" -body $messageadmin -Attachments $logfilename2, $logfilename3 -SmtpServer $smtpserver
write-and-log $logfilename "Email Sent" 0 "full"

# Stops the timer and logs the time the script took to run
$stop_watch.Stop()
$elapsed_seconds = ($stop_watch.elapsedmilliseconds)/1000
write-and-log $logfilename "VDI Connectivity Report created in $("{0:N2}" -f $elapsed_seconds) seconds" 0 "full"
