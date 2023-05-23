<#
    .SYNOPSIS
	Install a local print queue via Intune.
    .DESCRIPTION
	Deploy a printer to Windows endpoint using Intune
	Intune did not have a native method of deploying printers, not sure if it does yet.
	This script will allow you to deploy local print queues using a driver hosted on SharePoint.

	Upload the required Driver as a zip file to OneDrive, sharepoint or some other web source
	The zip file should contain a single folder containing the driver files
	Make a note of the driver name, the folder name in the archive and .INF file name 
	Generate a link to the driver package. Add &download=1 to the end to turn it into a direct link if on OneDrive or Sharepoint
	Edit the printer and driver package settings to match your print device
	Upload the script to Intune under Device Configuration -> Powershell Scripts
	Ensure the 'Run script in 64 bit PowerShell Host' option is set to yes or running pnputil.exe will fail on x64 machines
	Assign to groups containing the required machines/users
	See https://docs.microsoft.com/en-us/intune/intune-management-extension for more information
#>

# ==================== Printer and Port Settings ============================
# Printer queue name
	$QueueName='Canon test queue'
# IP Address of printer port
	$PortName='192.168.4.8'
# SNMPIndex Index
	$SNMPIndex=1
# SNMPIndex Community String
	$SNMPCommunityString='public'

# == Driver package settings ==
# Link to Driver package download
	$DriverLink="https://tenant.sharepoint.com/<LINK>&download=1"
# Printer driver name
	$DriverName='Canon Generic Plus UFR II'
# Name of the Folder inside the driver package zip file
	$DriverFolder='CanonUFRII'
# Inf filename in the driver package
	$INFFile='CNLB0MA64.INF'
# Path the driver package zip file is saved to
	$DriverSavePath='C:\temp\CNLB0MA64.zip'
# Path the driver package zip file extracts to
	$ZipPath='c:\temp\zip'

# ==================== DON'T MODIFY BELOW THIS LINE ============================

# Exit if printer already exists
if (get-printer $QueueName -erroraction 'silentlycontinue') {return}

# Create zip path folder if required
if (-not (test-path $ZipPath -erroraction 'silentlycontinue')) {New-Item -ItemType directory -Path $ZipPath}

# Download and install the driver package if it doesn't already exist
if (-not (get-printerdriver $DriverName -erroraction 'silentlycontinue')) {
	Invoke-WebRequest $DriverLink -OutFile $DriverSavePath;
	Expand-Archive -Path $DriverSavePath -DestinationPath $ZipPath
	Start-Process -FilePath "pnputil.exe" -Args "/add-driver $ZipPath\$DriverFolder\$INFFile /install" -Verb RunAs -Wait
	Add-PrinterDriver -Name $DriverName
}

# Add printer port if it doesn't exist
if (-not (get-printerport $PortName -erroraction 'silentlycontinue')) {
	if ($SNMPIndex -eq $null -or $SNMPCommunityString -eq $null) {
		Add-PrinterPort -Name $PortName -PrinterHostAddress $PortName
	} else 	{
		Add-PrinterPort -Name $PortName -PrinterHostAddress $PortName -SNMPIndex $SNMPIndex -SNMPIndexcommunity $SNMPCommunityString
	}
}

Add-Printer -Name $QueueName -DriverName $DriverName -PortName $PortName
if (test-path $ZipPath) {Remove-Item $ZipPath -Recurse}
if (test-path $DriverSavePath) {Remove-Item $DriverSavePath}

