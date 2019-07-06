param(
 $resourceGroupName = 'a1100-Sandbox-USE',
 $StorageAccountName = 'a1100sandboxusediag',
 $ShareName = 'a1100-santosh'
 )
Connect-AzureRmAccount -Credential (Get-Credential -Message "Login prompt") | Out-Null
$Sak = Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $StorageAccountName
$Key = ($Sak | Select-Object -First 1).Value

$Mount = 'X:'  
$Rshare = '\\a1100sandboxusediag.file.core.windows.net\sss'
$cred = Get-Credential -UserName 'a1100sandboxusediag' -Message "login Prompt" 
Write-Host $Rshare
New-SmbMapping -LocalPath $Mount -RemotePath "$Rshare" -UserName $StorageAccountName -Password $Key

