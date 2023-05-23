# Read all printers on source print server that use a TCPIP port
# Create them on the print server the script is run from

# Name of source print server
$SourceServer='SOURCEPRINTSERVER'

$Printers=get-printer -computername $SourceServer
ForEach ($Printer in $Printers)
{
	$PortName=($Printer).portname
	if ($PortName -like '*.*')
	{	
		$PrinterName=($Printer).name
		$PrinterDriver=($Printer).drivername
		$ShareName=($Printer).sharename
		$PrinterPort=Get-PrinterPort $PortName -ComputerName $SourceServer
		$SNMPIndex=($PrinterPort).snmpindex
		$SNMPCommunity=($PrinterPort).snmpcommunity
		
		# Map the printer to pull down the driver
		$AddPrinterConnection = Invoke-WmiMethod -Path Win32_Printer -Name AddPrinterConnection -ArgumentList ([string]::Concat('\\', $SourceServer, '\', $ShareName)) -EnableAllPrivileges 

		# Delete the mapped printer
		Remove-Printer -name "\\$SourceServer\$ShareName"

		# Create the port and printer
		Add-PrinterPort -Name $PortName -PrinterHostAddress $PortName -SNMP $SNMPIndex -SNMPcommunity $SNMPCommunity
		Add-Printer -Name $PrinterName -DriverName $PrinterDriver -PortName $PortName -ShareName $ShareName -RenderingMode ssr
	}
}