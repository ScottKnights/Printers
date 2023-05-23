# Install required drivers. Create CSV with required fields.

function add-newprinter {
	param (
		[string]$printername,
		[string]$driver,
		[string]$portname,
		[string]$description,
		[string]$location,
		[string]$snmpcommunity="public",
		[string]$snmpindex="1"
	)
	if (-not (get-printerport $portname -ErrorAction silentlycontinue)) {
		"Creating port $portname"
		Add-PrinterPort -Name $portname -PrinterHostAddress $portname -snmp $snmpindex -snmpcommunity $snmpcommunity
	} else {
		"Port $portname already exists"
	}

	if (-not (get-printer $printername -ErrorAction silentlycontinue)) {
		"Creating printer $printername"
		Add-Printer -Name $printername -DriverName $driver -PortName $portname -RenderingMode ssr -location $location -comment $description
	} else {
		"Printer $printername already exists"
	}
}

$newprinters=import-csv -literalpath ".\printers.csv"

foreach ($printer in $newprinters) {
	add-newprinter -printername $printer.name -driver $printer.driver -portname $printer.port -description $printer.comment -location $printer.location
}