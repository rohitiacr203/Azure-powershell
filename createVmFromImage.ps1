
$pw = "Siemens1234@" | ConvertTo-SecureString -AsPlainText -Force
$cred = [System.Management.Automation.PSCredential]::new('siemens',$pw)

Login-AzureRmAccount -Subscription "33bda070-7a6a-4b5b-a3bb-af738caf5494" -Credential (Get-Credential -Message "Login Prompt" -UserName "singh.rohit@siemens-healthineers.com")

$pw = "Siemens1234@" | ConvertTo-SecureString -AsPlainText -Force
$cred = [System.Management.Automation.PSCredential]::new('siemens',$pw)
New-AzureRmVm `
-ResourceGroupName "a1052-CLI-Golden-Images-EUS" `
-Name "a1098-HS-LD" `
-ImageName "Windows2016-Oct" `
-Location "EastUS" `
-VirtualNetworkName "a1098-HS-LD" `
-SubnetName "a1098-HS-LD" `
-Credential $cred `
-PublicIpAddressName "a1098-HS-LD-ip" 