﻿function Get-CUCMDeviceName {
    param(
        [Parameter(Mandatory)][String]$UserIDAssociatedWithDevice
    )

    $AXL = @"
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.cisco.com/AXL/API/9.1">
   <soapenv:Header/>
   <soapenv:Body>
      <ns:executeSQLQuery sequence="?">
        <sql>select device.name, enduser.userid from device, enduser, enduserdevicemap
            where device.pkid=enduserdevicemap.fkdevice and  
            enduser.pkid=enduserdevicemap.fkenduser and enduser.userid = '$UserIDAssociatedWithDevice'
        </sql>
      </ns:executeSQLQuery>
   </soapenv:Body>
</soapenv:Envelope>
"@
    $XmlContent = Invoke-CUCMSOAPAPIFunction -AXL $AXL -MethodName executeSQLQuery

    $XmlContent.Envelope.Body.executeSQLQueryResponse.return.row
}
function Remove-CUCMPhone {
    param(
        [Parameter(Mandatory)][String]$Name
    )

    $AXL = @"
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.cisco.com/AXL/API/9.1">
    <soapenv:Header/>
    <soapenv:Body>
        <ns:removePhone>
        <name>$Name</name>
        </ns:removePhone>
    </soapenv:Body>
</soapenv:Envelope>
"@

    Invoke-CUCMSOAPAPIFunction -AXL $AXL -MethodName removePhone
}

function Set-CUCMLine {
    param(
        [Parameter(Mandatory)][String]$DN,
        [Parameter(Mandatory)][String]$RoutePartition,
        [String]$Description,
        [String]$AlertingName,
        [String]$AsciiAlertingName
    )

    $AXL = @"
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.cisco.com/AXL/API/9.1">
   <soapenv:Header/>
   <soapenv:Body>
      <ns:updateLine sequence="?">
         <pattern>$DN</pattern>
         <routePartitionName>$RoutePartition</routePartitionName>
         <description>$Description</description>
         <alertingName>$AlertingName</alertingName>
         <asciiAlertingName>$AsciiAlertingName</asciiAlertingName>
    </ns:updateLine>
   </soapenv:Body>
</soapenv:Envelope>
"@

    Invoke-CUCMSOAPAPIFunction -AXL $AXL -MethodName updateLine
}


function Invoke-CUCMSOAPAPIFunction {
    param(
        [parameter(Mandatory)]$AXL,
        [parameter(Mandatory)]$MethodName
    )
    
    add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

    $Credential = Import-Clixml $env:USERPROFILE\CUCMCredential.txt   
    $Result = Invoke-WebRequest -ContentType "text/xml;charset=UTF-8" -Headers @{"SOAPAction"="CUCM:DB ver=9.1 $MethodName"} -Body $AXL -Uri https://ter-cucm-pub1:8443/axl/ -Method Post -Credential $Credential -SessionVariable AXLWebSession
    $XmlContent = [xml]$Result.Content
    $XmlContent
}

function New-CUCMCredential {
    $CUCMCredential = Get-Credential
    $CUCMCredential | Export-Clixml $env:USERPROFILE\CUCMCredential.txt
}