param ($instrumentsData)

$instrumentsData = @('HS-SCIRG-PC:192.168.1.106:PCC:HS-SCIRG-PC:true');
$instrumentsData += @('HS-SCIRG-SH:192.168.1.140:SH:HS-SCIRG-SH:false');
$instrumentsData += @('HS-SCIRG-IM:192.168.1.160:IM:HS-SCIRG-IM:false');
$instrumentsData += @('HS-SCIRG-CH:192.168.1.150:CH:HS-SCIRG-CH:false')

$testData = $instrumentsData.split(";")

# Set the File Name Create The Document
$XmlWriter = [System.XML.XmlWriter]::Create("C:\InstrumentInfo.xml", $xmlsettings)
# Write the XML Decleration and set the XSL
$xmlWriter.WriteStartDocument()
$xmlWriter.WriteProcessingInstruction("InstrumentsInfo", 'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"')
$xmlsettings = New-Object System.Xml.XmlWriterSettings
$xmlsettings.Indent = $true
$xmlsettings.IndentChars = "    "

# Start the Root Element
$xmlWriter.WriteStartElement("InstrumentInfo")

$xmlWriter.WriteStartElement("Instruments")
foreach($data in $testData)
{
$testDatasystem = $data.split(":")
  
    $xmlWriter.WriteStartElement("Instrument") # <-- Start <Object>
        $xmlWriter.WriteElementString("NAME",$testDatasystem[0])
        $xmlWriter.WriteElementString("IP",$testDatasystem[1])
        $xmlWriter.WriteElementString("TYPE",$testDatasystem[2])
        $xmlWriter.WriteElementString("SERIAL_NO",$testDatasystem[3])
        $xmlWriter.WriteElementString("PRIMARY",$testDatasystem[4])
    $xmlWriter.WriteEndElement() # <-- End <Object>
}

$xmlWriter.WriteEndElement()
$xmlWriter.WriteEndElement() # <-- End <Root>
# End, Finalize and close the XML Document
$xmlWriter.WriteEndDocument()
$xmlWriter.Flush()
$xmlWriter.Close()

