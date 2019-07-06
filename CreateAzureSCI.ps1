<#
.SYNOPSIS
	Creates 1 or more emulators on Azure based on an input XML configuration file.
	
	.Description
	The InstrumentInfo file from current DevOps automation can be used to configure Atellica emulators.  Disk images are vectored
	from ModuleBlobsInfo.xml.  Note that use of the '1' subnet will cause IPSec to block intra-module communications as of this writing in October 2018.
	InstrumentInfo.xml should use a subnet like 192.168.2.0 or other to avoid this IPSec Workflow issue.

Available switches and their default values are as follows:
	-InputFile	InstrumentInfo.XML file for configuration data
	-ModuleBlobs	Location of the file that points to the module disk images.  XML formatting similar to InstrumentInfo.XML
	-RGMax		Number or Emulators to create
	-Ord_RG		Starting ordinal index of module resource groups

	.Parameter -InputFile
	InstrumentInfo.xml file for configuring the module VMs.
	Default: "\\usndea3001ksrv\common\LowJ01\InstrumentsInfo.xml"
	
	.Parameter -ModuleBlobs		
	Location of the file that points to the module disk images.  XML formatting similar to InstrumentInfo.XML
	Default: "\\usndea3001ksrv\common\LowJ01\ModuleBlobsInfo.xml"
	
	.Parameter -RGMax
	Ordinal counter maximum value when creating more that 1 emulator resource group (vApp)
	Default: 1
	
	.Parameter -Ord_RG
	Starting appended value that is incremented to RGMax when creating multiple emulator resource groups
	Default: 0
	
	
	.Example
	.\CreateAzureSCI -Org_RG 4 -RGMax 5
	Creates 2 emulator resource groups.
	
	.Notes
	No Notes provided.
#>
Param ( $InputFile = "\\usndea3001ksrv\common\LowJ01\InstrumentsInfo.xml",
	$ModuleBlobs = "\\usndea3001ksrv\common\LowJ01\ModuleBlobsInfo.xml",
	$RGRoot = 'a1052_TestAtellicaSCI-',
	$RGMax = 1,
	$Ord_RG=0 )
#	$InputFile = "\\usndea3001ksrv\common\LowJ01\InstrumentsInfo.xml";$ModuleBlobs = "\\usndea3001ksrv\common\LowJ01\ModuleBlobsInfo.xml";$RGRoot = 'a1052_TestAtellicaSCI-';$RGMax = 1;$Ord_RG=0
Cls
<#
	The initial portion of the script checks AzureRM and connects to the subscription
#>
<#
	Variables:
		$MasterNSG = "a1052HyperV002-nsg"			A master security group that contains all possible Siemens Source Networks
		$PCCVMSize = "Standard_F8s_v2"				Module size for PCC module type
		$ModuleVMSize = "Standard_F4s_v2"			Module size for MM modules
		[xml]$xmlInstrumentDefinition = Get-Content $InputFile	Emulator InstrumentInfo file
		[xml]$ModuleDiskLocation = Get-Content $ModuleBlobs	Locations of blobs for emulator hard drives
		$PollMax = 900						Timeout interval
		$Location						Specifiy for better file upload/download performance
#>

$MasterNSG = "a1052HyperV002-nsg"
$PCCVMSize = "Standard_F8s_v2"
$ModuleVMSize = "Standard_F4s_v2"
[xml]$xmlInstrumentDefinition = Get-Content $InputFile
#Read module->DiskBlob definitions
[xml]$ModuleDiskLocation = Get-Content $ModuleBlobs	
$PollMax = 900
#	$Location = "South India"
$Location = "East US"
$AzureRMModule = @()
"[$((Get-Date).ToString())]`tFind correct AzureRM module or exit" | Out-Default

#	AzureRM version currently 6.6 but a better version should accomodate higher version numbers.  Didn't bother with good RegEx yet.
#	The code below was tested with 6.13 and still works, though not sure why.

$AzureRMModule +=  get-module -list | ? { $_.Name -like "AzureRM" } | ? { $_.Version -like "6.6.0" }
If ( $AzureRMModule.Count -lt 1 )
{
	"[$((Get-Date).ToString())]`tAzureRM module not installed.  Use an administrative PS session and run the command:"
	"[$((Get-Date).ToString())]`t`tInstall-Module AzureRM -Repository `'PSGallery`'"
	Exit 1
}


"[$((Get-Date).ToString())]`tCheck and load AzureRM" | Out-Default
If ( ( get-module | ? { $_.Name -like "AzureRM" } | ? { $_.Version -like "6.6.0" }).Count -lt 1 )
{
	"[$((Get-Date).ToString())]`tImport AzureRM module" | Out-Default
	import-module $AzureRMModule.path
}
"[$((Get-Date).ToString())]`tGet current running credentials" | Out-Default
$searcher = [adsisearcher]"(samaccountname=$env:USERNAME)"
"[$((Get-Date).ToString())]`tOpen Azure connection for $($searcher.FindOne().Properties.mail)" | Out-Default
Try
{
	$CheckConnection = Get-AzureRMResourceGroup -EA Stop
	If ( $CheckConnection.Count -eq 0 )
	{
		Throw "No Connection"
	}
}
Catch
{
	Clear-AzureProfile -Force
	$TenantId = 'f82969ba-b995-4d80-8bfa-fd22c1d0557a'
	$SubscriptionName = 'a1052_DX_DevOps_Azure_2'
	Login-AzureRmAccount -TenantId $TenantId
	$Context = Set-AzureRmContext -SubscriptionName $SubscriptionName
	$Subscription = Get-AzureRmSubscription -SubscriptionName $Context.Subscription.Name 
}
<#
	The body of the script loops through ordinal values until all emulator resource groups are created.
	In a more sophisticated script, an XML template would be used to describe the contents of the resource groups
	and iterated against in a similar manner.  The process illustrated below would be handled using XML templates instead, but
	would still follow similar logic.  The methods used below are more directly relevant for customization
#>
# Loop until all emulators are created
DO
{
	$destinationResourceGroup = "$($RGRoot)$($Ord_RG)"
	$Ord_RG += 1
	"[$((Get-Date).ToString())]`tCreate new ResourceGroup `'$($destinationResourceGroup)`'" | Out-Default
	$Result = New-AzureRmResourceGroup -Location $location `
	   -Name $destinationResourceGroup # Create a resource group
	If ($Result.ProvisioningState -like "Succeeded" )
	{
		"[$((Get-Date).ToString())]`tResourceGroup created successfully" | Out-Default
	}
	Else
	{
		"[$((Get-Date).ToString())]`tError creating resource group, aborting script." | Out-Default
		Throw "No resource group created"
	}
	"[$((Get-Date).ToString())]`tCreating network security group, copied from existing pre-defined group"
	$nsgName =  "$($destinationResourceGroup)_Nsg"
	$rdpRule = Get-AzureRmNetworkSecurityGroup -Name $MasterNSG -ResourceGroupName "a1052_SWI_Infrastructure_VMs" | 
		Get-AzureRmNetworkSecurityRuleConfig
	$nsg = New-AzureRmNetworkSecurityGroup `
	   -ResourceGroupName $destinationResourceGroup `
	   -Location $location `
	   -Name $nsgName -SecurityRules $rdpRule -warningaction:SilentlyContinue
	"[$((Get-Date).ToString())]`tGenerate virtual network name"
	$vnetName = "$($destinationResourceGroup)_Vnet"
	"[$((Get-Date).ToString())]`tEnumerate required modules"
	$Modules = $xmlInstrumentDefinition.InstrumentsInfo.Instruments.Instrument
	"[$((Get-Date).ToString())]`tCreating virtual subnets"
	$Octets = $Modules[0].IP.Split("`.")
	$MainNet = "$($Octets[0]).$($Octets[1]).0.0"
	$PrivateNet = "$($Octets[0]).$($Octets[1]).$($Octets[2]).0"
	$EmulatorSubnetConfig = New-AzureRmVirtualNetworkSubnetConfig `
		-Name "EmulatorLAN" `
		-AddressPrefix "$($PrivateNet)/24" `
		-NetworkSecurityGroup $nsg `
		-warningaction:SilentlyContinue
	"[$((Get-Date).ToString())]`tCreating Emulator Network"
	$vnet = New-AzureRmVirtualNetwork `
		-Name $vnetName -ResourceGroupName $destinationResourceGroup `
		-Location $location `
		-AddressPrefix "$($MainNet)/16" `
		-Subnet $EmulatorSubnetConfig `
		-warningaction:SilentlyContinue
	$vnet | Set-AzureRmVirtualNetwork | Out-Null
	$vnet = Get-AzureRmVirtualNetwork `
		-Name $vnetName `
		-ResourceGroupName $destinationResourceGroup
	"[$((Get-Date).ToString())]`tEnumerate disk sources"
	$DiskSources = $ModuleDiskLocation.ModuleBlobsInfo.BaseImages.BaseImage
	"[$((Get-Date).ToString())]`tIterate through VM object creation for resource group `'$($destinationResourceGroup)`'"
<#
	This emulator creation script creates each individual object needed by each VM.  It may be possible to create an XML template of an
	emulator Resaource Group and create an emulator from that, but at some point the following steps will be useful to map out customization
	or automation code associated with DevOps.  XML Templates might be a next step associated with Azure emulator creation.
#>
	Foreach ($Module in $Modules)
	{
		"[$((Get-Date).ToString())]`tEnumerate specific module disk(s)"
		$ModDiskList = $DiskSources | ? { $_.ModuleType -like $Module.Type }
		$ModOSDisk = $ModDiskList | ? { $_.DiskType -like "OS" }
		$ModDataDisk = $ModDiskList | ? { $_.DiskType -like "Data" }
		If ( $ModOSDisk.Count -gt 1 )
		{
			Throw "Only 1 OS disk per module type allowed"
			Exit 1
		}
		"[$((Get-Date).ToString())]`tCreate $($Module.Name) $($Module.Type) Module OS disk config." | Out-Default
		$ModOSDiskName = "$($Module.Name).OSDisk"
		$ModOSDiskConfig = New-AzureRmDiskConfig -AccountType Premium_LRS `
	    		-Location $location -CreateOption Import `
	    		-SourceUri $ModOSDisk.AzureStorageURI
		"[$((Get-Date).ToString())]`tCreate new $($Module.Type) OS disk" | Out-Default
		$ModOSDisk = New-AzureRmDisk -DiskName $ModOSDiskName -Disk `
	    		$ModOSDiskConfig `
	    		-ResourceGroupName $destinationResourceGroup
		If ( $Module.Type -like "CH" -or $Module.Type -like "IM" )
		{
			$Ordinal = 0
			$ModDDisk = @()
			ForEach ( $DataDisk in $ModDataDisk )
			{
				$ModDataDiskName = "$($Module.Name).Data.$($Ordinal)"
				"[$((Get-Date).ToString())]`tCreate $($Module.Name) $($Module.Type) Module Data disk config." | Out-Default
				$ModDataDiskConfig = New-AzureRmDiskConfig -AccountType Premium_LRS  `
		    			-Location $location -CreateOption Import `
		    			-SourceUri $DataDisk.AzureStorageURI
				"[$((Get-Date).ToString())]`tCreate new $($Module.Type) Data disk" | Out-Default
				$ModDDisk += New-AzureRmDisk -DiskName $ModDataDiskName -Disk `
		    			$ModDataDiskConfig `
		    			-ResourceGroupName $destinationResourceGroup
			}
		}
		$ModnicName = "$($Module.Name).nic"
		"[$((Get-Date).ToString())]`tCreating  $($Module.Name) $($Module.Type) module NIC interface `'$($ModnicName )`'"
		$Modnic = New-AzureRmNetworkInterface -Name $ModnicName `
	   		-ResourceGroupName $destinationResourceGroup `
			-Location $location -SubnetId $vnet.Subnets[0].Id 
		$Modnic.IpConfigurations[0].PrivateIpAllocationMethod = "Static"
		$Modnic.IpConfigurations[0].PrivateIpAddress = "$($Module.IP)"
		If ($Module.Type -like "PCC")
		{
			$pipName = "$($Module.Name).pip"
			$pip =  New-AzureRmPublicIpAddress -Name $pipName -ResourceGroupName $destinationResourceGroup -Location $location -AllocationMethod Dynamic -Force
			$Modnic.IpConfigurations[0].PublicIpAddress = $pip
		}
		Set-AzureRmNetworkInterface -NetworkInterface $Modnic | Out-Null
		$vmName = "$($Module.Name)"
		"[$((Get-Date).ToString())]`tPreparing configuration for VM $($vmName)"
		If ($Module.Type -like "PCC")
		{
			$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $PCCVMSize 
		}
		Else
		{
			$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $ModuleVMSize 
		}
		$vm = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $Modnic.Id
		$vm = Set-AzureRmVMOSDisk -VM $vm -ManagedDiskId $ModOSDisk.Id -StorageAccountType Premium_LRS `
			-DiskSizeInGB 186 -CreateOption Attach -Windows
#Code to check disk count and add if necessary would be better.
		If ( $Module.Type -like "CH" -or $Module.Type -like "IM" )
		{
			$Ordinal = 1
			ForEach ( $DataDisk in $ModDDisk )
			{
				$vm = Add-AzureRmVMDataDisk -VM $vm -ManagedDiskId $DataDisk.Id -StorageAccountType Premium_LRS `
					-DiskSizeInGB 96 -CreateOption Attach -Lun $Ordinal
				$Ordinal += 1
			}
		}
		"[$((Get-Date).ToString())]`tCreating VM $($vmName)"
		New-AzureRmVM -ResourceGroupName $destinationResourceGroup -Location $location -VM $vm -AsJob | Out-Null
	}
} While ( $Ord_RG -lt $RGMax )


	