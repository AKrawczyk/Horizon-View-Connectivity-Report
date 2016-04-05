# Horizon-View-Connectivity-Report</br>
PowerShell with PowerCLI script to report on Horizon View Connectivity</br>
</br>
Created By: Aaron Krawczyk - Aaron.krawczyk@cit.ie</br>
Based on Script Created By: Andre Leibovici - @andreleibovici - myvirtualcloud.net</br>
</br>
#Setup</br>
Script must be run on Connection Broker (Horizon View Connection Server) as View admin user.</br>
The Connection Broker must have both PowerShell, VMMware PowerCLI and View PowerCLI installed on it.</br>
</br>
# How to install PowerShell, VMWare PowerCLI and View PowerCLI</br>
PowerShell comes a part of Windows 2008, 2012 and 2016</br>
View PowerCLI comes as part of the Horizon View Connection Server install</br>
Goto VMWare.com and download VMWare PowerCLI 5.5</br>
Install VMWare PowerCLI 5.5</br>
</br>
# How to configure the script</br>
Edit the PowerShell script and enter the informion relevent to your orgisnation</br>
$emailto</br>
$emailcc</br>
$emailfrom</br>
$smtpserver</br>
edit 'Write email signature' section
</br>
# How to run the script</br>
1. Open Powershell command windows</br>
2. .\get_vm_login_count</br>
</br>
Log Files</br>
The script will write out information to a log file and CSV.</br>
This will be located in a sub folder of the script called 'Logs'.</br>
