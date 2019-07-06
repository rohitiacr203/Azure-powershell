$instrumentsData = @('HS-SCIRG-PC:192.168.1.106:PCC:HS-SCIRG-PC:true');
$instrumentsData += @('HS-SCIRG-SH:192.168.1.140:SH:HS-SCIRG-SH:false');
$instrumentsData += @('HS-SCIRG-IM:192.168.1.160:IM:HS-SCIRG-IM:false');
$instrumentsData += @('HS-SCIRG-CH:192.168.1.150:CH:HS-SCIRG-CH:false')


Write-Output "Outside Invoke-Command, MyArray has a value of: $instrumentsData"

Invoke-Command -ComputerName "IOT" -ScriptBlock {"F:/InstrumentsInfo.ps1"} -ArgumentList $instrumentsData