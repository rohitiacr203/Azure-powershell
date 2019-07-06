
# Initialize common variables =================================================================
param(
 $TenantId = 'f82969ba-b995-4d80-8bfa-fd22c1d0557a',
 $SubscriptionName = 'a1052_DX_DevOps_Azure_2',
 $resourceGroupName = 'siemens',
 $vmName = "myVM",
 $location = 'East US',
 $vmSize = 'Standard_A1',
 $StorageAccountName = 'freesiemensiem040417110',
 $size = 'Standard_DS1_v2',
 $myvirtualnetwork = 'demo1895',
 $nsgName = 'name',
 $networkName = 'myTestNetworks',
 $VirtualNetworkAddress = '192.168.1.0/16',
 $subnetName = 'AzurePSTestNetworkSubnet',
 $subnetAddress = '192.168.1.0/24',
 $OSDiskName = 'MyClient',
 $ComputerName = 'MyClientVM',
 $OSDiskCaching = "ReadWrite",
 $OSCreateOption = "FromImage"

)

# MIM Servers to Auto Deploy
$VMRoles = @()
$VMRoles += ('PCC')
#$VMRoles += ('CC')
#$VMRoles += ('IA')
#$VMRoles += ('SH')

# Authenticate to the Azure Portal
Write-Host "Logging into Azure..." -BackgroundColor Green

$pw = "01000000d08c9ddf0115d1118c7a00c04fc297eb0100000013ea480cad3f3c498ef6ba1f16fcd6540000000002000000000003660000c0000000100000002a9c4b38c091c1c6745c99f647770be50000000004800000a0000000100000002932bb3f178b02090c3c463cab9e99e4200000001ecea8f7dde0a9fbd311611d9372fd9a70075311e69df7c3bcbf8d0c5632c4a1140000007d8661ded5c2e51c81b87175d55882a077dcc459" | 
    ConvertTo-SecureString -Force
$creds = [System.Management.Automation.PSCredential]::new('chandrakanth.sivaprakasam@siemens-healthineers.com',$pw)

Login-AzureRmAccount -Credential $creds

# Get the UserID and Password info that we want associated with the new VM's.
#$global:cred = Get-Credential -Message "Type the name and password for the local administrator account that will be created for your new VM(s)."

$pw = "windows12345@" | ConvertTo-SecureString -AsPlainText -Force
$cred = [System.Management.Automation.PSCredential]::new('siemens',$pw)

# select subscription
Write-Host "Selecting subscription $subscriptionId" -BackgroundColor DarkGreen
Select-AzureRmSubscription -SubscriptionID $subscriptionId


#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "Resource group '$resourceGroupName' does not exist. To create a new resource group, please enter a location.";
    #if(!$location) {
    #    $location = Read-Host "location";
    #}
    Write-Host "Creating resource group '$resourceGroupName' in location '$location'" -BackgroundColor Green
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
}
else{
    Write-Host "Using existing resource group '$resourceGroupName'" -BackgroundColo DarkMagenta
}

# To check the SA Name(Format) entered is valid
  $saExists = Get-AzureRmStorageAccountNameAvailability -Name $StorageAccountName
  $SaExist = $saExists.NameAvailable

if ($SaExist -eq 'True')
{
    Write-Host "Creating Storage Account"
    New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName `
                              -Name $StorageAccountName `
                              -Location $Location `
                              -Type Standard_LRS
}
else{
    Write-Host "Storage Account '$StorageAccountName' already Exists!" -BackgroundColor DarkMagenta
}

#******************************************************************************
# Virtual network Creation
#******************************************************************************

$rdpRule = New-AzureRmNetworkSecurityRuleConfig  -Name 'rdp-rule' `
                                                 -Description 'Allow RDP' `
                                                 -Access Allow -Protocol Tcp -Direction Inbound -Priority 100  `
                                                 -SourceAddressPrefix Internet -SourcePortRange *  `
                                                 -DestinationAddressPrefix * -DestinationPortRange 3389 
Write-Host "setting up RDP rule .." -BackgroundColor Green

#Network security group creation
$nsgExists = Get-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName
if($nsgExists -ne "Succeeded")
{
$networkSecurityGroup = New-AzureRmNetworkSecurityGroup -Name $nsgName `
                                                        -ResourceGroupName $resourceGroupName `
                                                        -Location $location  `
                                                        -SecurityRules $rdpRule -Force `
}
else{
    Write-Host "Network Security Group '$nsgName' already Exists!" -BackgroundColor DarkMagenta
}

#subnet creation
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName `
                                                      -AddressPrefix $subnetAddress `
                                                      -NetworkSecurityGroup $networkSecurityGroup

#Virtual Network creation
$Vnet = Get-AzureRmVirtualNetwork -Name $myvirtualnetwork -ResourceGroupName $resourceGroupName

if ($Vnet -eq $false)
{ 
$Vnet = New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName `
                                  -Name $networkName `
                                  -AddressPrefix $VirtualNetworkAddress `
                                  -Subnet $subnetConfig `
                                  -Location $location `
}
else{
    Write-Host "Virtual Network '$networkName' already Exists!" -BackgroundColor DarkMagenta
}


#Add OS info into vm(Disk configuration)
$diskName = 'myOSdisk'
$STA = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName
#$OSDiskUri = $STA.PrimaryEndpoints.Blob.ToString() + "vhds/" + $NewVM + ".vhd"
#$vm = Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $OSDiskUri -CreateOption fromImage 
#write-host "Added OS disk configuration to Vm" -BackgroundColor Green


# VM Config for each VM
$VMConfig = @()

# Create VMConfigs and add to an array
foreach ($NewVM in $VMRoles) {

    # Get the UserID and Password info that we want associated with the new VM's.
    #$global:cred = Get-Credential -Message "Type the name and password for the local administrator account that will be created for your new VM(s)."

    $publicIp = New-AzureRmPublicIpAddress -Name $NewVM -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Static -Force
    $vmNIC = New-AzureRmNetworkInterface -Name $NewVM -ResourceGroupName $resourceGroupName -Location $location -SubnetId $Vnet.Subnets[0].Id -PublicIpAddressId $publicIp.Id -Force `

    $vm = New-AzureRmVMConfig -VMName $NewVM -VMSize $vmSize
    $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName  -Credential $cred -ProvisionVMAgent -EnableAutoUpdate -TimeZone 'Pacific Standard Time'
    Write-Host "operating system settin..." -BackgroundColor Green

    $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName "MicrosoftWindowsServer" -offer "WindowsServer" -Skus "2012-R2-Datacenter" -Version "latest"
    $vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $vmNIC.Id 
    Write-Host "source image and NIC added ......" -BackgroundColor Green
    

    #$vm = Set-AzureRmVMOSDisk -VM $vm -Name "windowsvmosdisk" -VhdUri $osDiskUri -CreateOption fromImage
    #$vm = Add-AzureRmVMDataDisk -VM $vm -Name "windowsvmdatadisk" -VhdUri $DataDiskUri -CreateOption Empty -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 0
    #Write-Host "operating system setting..." -BackgroundColor Green

    $OSDiskUri = $STA.PrimaryEndpoints.Blob.ToString() + "vhds/" + $NewVM + ".vhd"
    $vm = Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $OSDiskUri -CreateOption FromImage -Windows
    write-host "Added OS disk configuration to Vm" -BackgroundColor Green
    
    # Add the Config to an Array
    $VMConfig = $vm
    Write-Host "Add the Config to an Array" -BackgroundColor Green

    New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $vm
    Write-Host "VM $NewVM created..." -BackgroundColor Green
}

