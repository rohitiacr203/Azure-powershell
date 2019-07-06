[CmdletBinding()]
param(
     
    $containerName ="rohittest",

    $StorageAccountName ="a1098lddashboard",    

    $StorageAccountKey ="i7tcVzqjGj94DTgHpB4R7VEifdJj4CeFX/pbnR5uPQmIiffFhaPscvklvzIp9tOlCOrmEXgCDo8sliAVrju0TQ==",    

    #$blob = "test.txt",

    $DestinationPath = "$HOME\Downloads"
)
$ErrorActionPreference = "Stop"

$password = ConvertTo-SecureString 'Jaimatadi12345@' -AsPlainText -Force

$credential = New-Object System.Management.Automation.PSCredential ('singh.rohit@siemens-healthineers.com', $password)

Connect-AzureRmAccount -Credential $Credential -Subscription "132ed74f-9682-4dde-9a2a-88dcf3a30b5d" -Tenant "f82969ba-b995-4d80-8bfa-fd22c1d0557a"


try {

    ## check for the Type of Azure module installed, if it is "Az" Module. It enables "Enable-AzureRmAlias" to support AzureRm Commands.
    If ( ( Get-InstalledModule | ? { $_.Name -like "Az" }).Count -lt 1 )
    {
        "[$((Get-Date).ToString())]`tAz Module was installed, So enabling AzureRmAlias which supports AzureRM module commands" | Out-Default
        Enable-AzureRmAlias
    }

    $azContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
    $blobs = Get-AzureStorageBlob -Container $containerName -Context $azContext 
    foreach ($blob in $blobs)
    {
        Get-AzStorageBlobContent -Container $containerName -Blob $blob -Force -Destination $DestinationPath -Context $azContext
    }
l}
catch {
    $Error[0]
} 
"[$((Get-Date).ToString())]`tFinished execution" | Out-Default