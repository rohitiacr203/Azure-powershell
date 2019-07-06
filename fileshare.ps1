param(
 $subscriptionId = '132ed74f-9682-4dde-9a2a-88dcf3a30b5d',
 $resourceGroupName = 'a1098-LD-Dashboard-RG',
 $vmName = "HS-Test-Win10",
 $location = 'East US',
 $StorageAccountName = 'a1098lddashboard',
 $ShareName = 'remotefiles'
 )

#Connect-AzureRmAccount
#$Sak = Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName 'a1098-LD-Dashboard-RG' -Name 'a1098lddashboard'
$Sak = (Get-AzureRmStorageAccountKey -ResourceGroupName $StorageAccountName.resourceGroupName -Name $StorageAccountName.StorageAccountName | select -first 1).Value

#Connect-AzureRmAccount -Subscription "33bda070-7a6a-4b5b-a3bb-af738caf5494" -Credential (Get-Credential -Message "Login prompt") | Out-Null
$Sak = Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $StorageAccountName
$Key = ($Sak | Select-Object -First 1).Value 
$SAContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $Key

New-AzureStorageShare -Name $ShareName -Context $SAContext

$Mount = 'Z:' 
#Get-Smbmapping -LocalPath $Mount -ErrorAction SilentlyContinue | 
#Remove-Smbmapping -Force -ErrorAction SilentlyContinue 
$Rshare = "\\$StorageAccountName.file.core.windows.net\$ShareName" 
New-SmbMapping -LocalPath $Mount -RemotePath $Rshare -UserName $StorageAccountName -Password $Key

#Get-AzureStorageShare -Context $SACon | Format-List -Property *
#$cred = Get-Credential
#Invoke-Command –ComputerName 'HS-SCIRGRS-PC' -Credential $Cred –ScriptBlock {New-SmbMapping -LocalPath $Mount -RemotePath $Rshare -UserName $StorageAccountName -Password $Key}
