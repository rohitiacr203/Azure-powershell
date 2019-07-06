[CmdletBinding()]
param(
     
    $containerName ="testblob",

    $StorageAccountName ="a1098lddashboard",    

    $StorageAccountKey ="QPM6Cn4E9JscUfLgvN4SUK2Mth/PwLecfuzGJP6sgoa4PKIUV/YQ0xJMrAl7iWCd/+Qd/Gd/JWF1rGPp6GnQKg==",    

    #$blob = "test.txt",

    $DestinationPath = "$HOME\Downloads"
)

$password = ConvertTo-SecureString 'Jaimatadi12345@' -AsPlainText -Force

$credential = New-Object System.Management.Automation.PSCredential ('singh.rohit@siemens-healthineers.com', $password)

Connect-AzureRmAccount -Credential $Credential -Subscription "132ed74f-9682-4dde-9a2a-88dcf3a30b5d" -Tenant "f82969ba-b995-4d80-8bfa-fd22c1d0557a"

echo script started >>c:\rohit.txt
"[$((Get-Date).ToString())]`tExecution started" | Out-Default  

$ErrorActionPreference = "Stop"


$azContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

$blobs = Get-AzureStorageBlob -Container $containerName -Context $azContext  

"[$((Get-Date).ToString())]`tsetting context" | Out-Default

foreach($blob in $blobs) {  

    Get-AzureStorageBlobContent -Container $containerName -Blob $blob.Name -Destination $DestinationPath ` -Context $azContext  
}
"[$((Get-Date).ToString())]`tFinished execution" | Out-Default  
echo script Ended >>c:\rohit1.txt