# Author: William Lam
# Website: www.williamlam.com

# vCenter Server used to deploy VMware Cloud Foundation Lab
$VIServer = "FILL-ME-IN"
$VIUsername = "FILL-ME-IN"
$VIPassword = "FILL-ME-IN"

# Full Path to both the Nested ESXi & Cloud Builder OVA
$NestedESXiApplianceOVA = "/root/Nested_ESXi8.0u3_Appliance_Template_v1.ova"
$CloudBuilderOVA = "/root/VMware-Cloud-Builder-5.2.0.0-24108943_OVF10.ova"

# VCF Licenses or leave blank for evaluation mode (requires VCF 5.1.1 or later)
$VCSALicense = ""
$ESXILicense = ""
$VSANLicense = ""
$NSXLicense = ""

# VCF Configurations
$VCFManagementDomainPoolName = "vcf-m01-rp01"
$VCFManagementDomainJSONFile = "vcf-mgmt.json"
$VCFWorkloadDomainUIJSONFile = "vcf-commission-host-ui.json"
$VCFWorkloadDomainAPIJSONFile = "vcf-commission-host-api.json"

# Cloud Builder Configurations
$CloudbuilderVMHostname = "vcf-m01-cb01"
$CloudbuilderFQDN = "vcf-m01-cb01.tshirts.inc"
$CloudbuilderIP = "172.17.31.180"
$CloudbuilderAdminUsername = "admin"
$CloudbuilderAdminPassword = "VMw@re123!VMw@re123!"
$CloudbuilderRootPassword = "VMw@re123!VMw@re123!"

# SDDC Manager Configuration
$SddcManagerHostname = "vcf-m01-sddcm01"
$SddcManagerIP = "172.17.31.181"
$SddcManagerVcfPassword = "VMware1!VMware1!"
$SddcManagerRootPassword = "VMware1!VMware1!"
$SddcManagerRestPassword = "VMware1!VMware1!"
$SddcManagerLocalPassword = "VMware1!VMware1!"

# Nested ESXi VMs for Management Domain
$NestedESXiHostnameToIPsForManagementDomain = @{
    "vcf-m01-esx01"   = "172.17.31.185"
    "vcf-m01-esx02"   = "172.17.31.186"
    "vcf-m01-esx03"   = "172.17.31.187"
    "vcf-m01-esx04"   = "172.17.31.188"
}

# Nested ESXi VMs for Workload Domain
$NestedESXiHostnameToIPsForWorkloadDomain = @{
    "vcf-m01-esx05"   = "172.17.31.189"
    "vcf-m01-esx06"   = "172.17.31.190"
    "vcf-m01-esx07"   = "172.17.31.191"
    "vcf-m01-esx08"   = "172.17.31.192"
}

# Nested ESXi VM Resources for Management Domain
$NestedESXiMGMTvCPU = "12"
$NestedESXiMGMTvMEM = "78" #GB
$NestedESXiMGMTCachingvDisk = "4" #GB
$NestedESXiMGMTCapacityvDisk = "500" #GB
$NestedESXiMGMTBootDisk = "32" #GB

# Nested ESXi VM Resources for Workload Domain
$NestedESXiWLDVSANESA = $false
$NestedESXiWLDvCPU = "8"
$NestedESXiWLDvMEM = "36" #GB
$NestedESXiWLDCachingvDisk = "4" #GB
$NestedESXiWLDCapacityvDisk = "250" #GB
$NestedESXiWLDBootDisk = "32" #GB

# ESXi Network Configuration
$NestedESXiManagementNetworkCidr = "172.17.31.0/24" # should match $VMNetwork configuration
$NestedESXivMotionNetworkCidr = "172.17.32.0/24"
$NestedESXivSANNetworkCidr = "172.17.33.0/24"
$NestedESXiNSXTepNetworkCidr = "172.17.34.0/24"

# vCenter Configuration
$VCSAName = "vcf-m01-vc01"
$VCSAIP = "172.17.31.182"
$VCSARootPassword = "VMware1!"
$VCSASSOPassword = "VMware1!"
$EnableVCLM = $true

# NSX Configuration
$NSXManagerVIPHostname = "vcf-m01-nsx01"
$NSXManagerVIPIP = "172.17.31.183"
$NSXManagerNode1Hostname = "vcf-m01-nsx01a"
$NSXManagerNode1IP = "172.17.31.184"
$NSXRootPassword = "VMware1!VMware1!"
$NSXAdminPassword = "VMware1!VMware1!"
$NSXAuditPassword = "VMware1!VMware1!"

# General Deployment Configuration for Nested ESXi & Cloud Builder VM
$VMDatacenter = "San Jose"
$VMCluster = "Compute Cluster"
$VMNetwork = "sjc-comp-mgmt (1731)"
$VMDatastore = "comp-vsanDatastore"
$VMNetmask = "255.255.255.0"
$VMGateway = "172.17.31.1"
$VMDNS = "172.17.31.2"
$VMNTP = "172.17.31.2"
$VMPassword = "VMware1!"
$VMDomain = "tshirts.inc"
$VMSyslog = "172.17.31.182"
$VMFolder = "VCF"

#### DO NOT EDIT BEYOND HERE ####

$verboseLogFile = "vcf-lab-deployment.log"
$random_string = -join ((65..90) + (97..122) | Get-Random -Count 8 | % {[char]$_})
$VAppName = "Nested-VCF-Lab-$random_string"
$SeparateNSXSwitch = $false
$VCFVersion = ""

$preCheck = 1
$confirmDeployment = 1
$deployNestedESXiVMsForMgmt = 1
$deployNestedESXiVMsForWLD = 1
$deployCloudBuilder = 1
$moveVMsIntovApp = 1
$generateMgmJson = 1
$startVCFBringup = 1
$generateWldHostCommissionJson = 1
$uploadVCFNotifyScript = 0

$srcNotificationScript = "vcf-bringup-notification.sh"
$dstNotificationScript = "/root/vcf-bringup-notification.sh"

$StartTime = Get-Date

Function My-Logger {
    param(
    [Parameter(Mandatory=$true)][String]$message,
    [Parameter(Mandatory=$false)][String]$color="green"
    )

    $timeStamp = Get-Date -Format "MM-dd-yyyy_hh:mm:ss"

    Write-Host -NoNewline -ForegroundColor White "[$timestamp]"
    Write-Host -ForegroundColor $color " $message"
    $logMessage = "[$timeStamp] $message"
    $logMessage | Out-File -Append -LiteralPath $verboseLogFile
}

if($preCheck -eq 1) {
    # Detect VCF version based on Cloud Builder OVA (support is 5.1.0+)
    if($CloudBuilderOVA -match "5.2.0") {
        $VCFVersion = "5.2.0"
    } elseif($CloudBuilderOVA -match "5.1.1") {
        $VCFVersion = "5.1.1"
    } elseif($CloudBuilderOVA -match "5.1.0") {
        $VCFVersion = "5.1.0"
    } else {
        $VCFVersion = $null
    }

    if($VCFVersion -eq $null) {
        Write-Host -ForegroundColor Red "`nOnly VCF 5.1.0, 5.1.1 & 5.2 is currently supported ...`n"
        exit
    }

    if($VCFVersion -ge "5.2.0") {
        write-host "here"
        if( $CloudbuilderAdminPassword.ToCharArray().count -lt 15 -or $CloudbuilderRootPassword.ToCharArray().count -lt 15) {
            Write-Host -ForegroundColor Red "`nCloud Builder passwords must be 15 characters or longer ...`n"
            exit
        }
    }

    if(!(Test-Path $NestedESXiApplianceOVA)) {
        Write-Host -ForegroundColor Red "`nUnable to find $NestedESXiApplianceOVA ...`n"
        exit
    }

    if(!(Test-Path $CloudBuilderOVA)) {
        Write-Host -ForegroundColor Red "`nUnable to find $CloudBuilderOVA ...`n"
        exit
    }

    if($PSVersionTable.PSEdition -ne "Core") {
        Write-Host -ForegroundColor Red "`tPowerShell Core was not detected, please install that before continuing ... `n"
        exit
    }
}

if($confirmDeployment -eq 1) {
    Write-Host -ForegroundColor Magenta "`nPlease confirm the following configuration will be deployed:`n"

    Write-Host -ForegroundColor Yellow "---- VCF Automated Lab Deployment Configuration ---- "
    Write-Host -NoNewline -ForegroundColor Green "VMware Cloud Foundation Version: "
    Write-Host -ForegroundColor White $VCFVersion
    Write-Host -NoNewline -ForegroundColor Green "Nested ESXi Image Path: "
    Write-Host -ForegroundColor White $NestedESXiApplianceOVA
    Write-Host -NoNewline -ForegroundColor Green "Cloud Builder Image Path: "
    Write-Host -ForegroundColor White $CloudBuilderOVA

    Write-Host -ForegroundColor Yellow "`n---- vCenter Server Deployment Target Configuration ----"
    Write-Host -NoNewline -ForegroundColor Green "vCenter Server Address: "
    Write-Host -ForegroundColor White $VIServer
    Write-Host -NoNewline -ForegroundColor Green "VM Network: "
    Write-Host -ForegroundColor White $VMNetwork

    Write-Host -NoNewline -ForegroundColor Green "VM Storage: "
    Write-Host -ForegroundColor White $VMDatastore
    Write-Host -NoNewline -ForegroundColor Green "VM Cluster: "
    Write-Host -ForegroundColor White $VMCluster
    Write-Host -NoNewline -ForegroundColor Green "VM vApp: "
    Write-Host -ForegroundColor White $VAppName

    Write-Host -ForegroundColor Yellow "`n---- Cloud Builder Configuration ----"
    Write-Host -NoNewline -ForegroundColor Green "Hostname: "
    Write-Host -ForegroundColor White $CloudbuilderVMHostname
    Write-Host -NoNewline -ForegroundColor Green "IP Address: "
    Write-Host -ForegroundColor White $CloudbuilderIP

    if($deployNestedESXiVMsForMgmt -eq 1) {
        Write-Host -ForegroundColor Yellow "`n---- vESXi Configuration for VCF Management Domain ----"
        Write-Host -NoNewline -ForegroundColor Green "# of Nested ESXi VMs: "
        Write-Host -ForegroundColor White $NestedESXiHostnameToIPsForManagementDomain.count
        Write-Host -NoNewline -ForegroundColor Green "IP Address(s): "
        Write-Host -ForegroundColor White $NestedESXiHostnameToIPsForManagementDomain.Values
        Write-Host -NoNewline -ForegroundColor Green "vCPU: "
        Write-Host -ForegroundColor White $NestedESXiMGMTvCPU
        Write-Host -NoNewline -ForegroundColor Green "vMEM: "
        Write-Host -ForegroundColor White "$NestedESXiMGMTvMEM GB"
        Write-Host -NoNewline -ForegroundColor Green "Caching VMDK: "
        Write-Host -ForegroundColor White "$NestedESXiMGMTCachingvDisk GB"
        Write-Host -NoNewline -ForegroundColor Green "Capacity VMDK: "
        Write-Host -ForegroundColor White "$NestedESXiMGMTCapacityvDisk GB"
    }

    if($deployNestedESXiVMsForWLD -eq 1) {
        Write-Host -ForegroundColor Yellow "`n---- vESXi Configuration for VCF Workload Domain ----"
        Write-Host -NoNewline -ForegroundColor Green "# of Nested ESXi VMs: "
        Write-Host -ForegroundColor White $NestedESXiHostnameToIPsForWorkloadDomain.count
        Write-Host -NoNewline -ForegroundColor Green "IP Address(s): "
        Write-Host -ForegroundColor White $NestedESXiHostnameToIPsForWorkloadDomain.Values
        Write-Host -NoNewline -ForegroundColor Green "vCPU: "
        Write-Host -ForegroundColor White $NestedESXiWLDvCPU
        Write-Host -NoNewline -ForegroundColor Green "vMEM: "
        Write-Host -ForegroundColor White "$NestedESXiWLDvMEM GB"
        Write-Host -NoNewline -ForegroundColor Green "Caching VMDK: "
        Write-Host -ForegroundColor White "$NestedESXiWLDCachingvDisk GB"
        Write-Host -NoNewline -ForegroundColor Green "Capacity VMDK: "
        Write-Host -ForegroundColor White "$NestedESXiWLDCapacityvDisk GB"
    }

    Write-Host -NoNewline -ForegroundColor Green "`nNetmask "
    Write-Host -ForegroundColor White $VMNetmask
    Write-Host -NoNewline -ForegroundColor Green "Gateway: "
    Write-Host -ForegroundColor White $VMGateway
    Write-Host -NoNewline -ForegroundColor Green "DNS: "
    Write-Host -ForegroundColor White $VMDNS
    Write-Host -NoNewline -ForegroundColor Green "NTP: "
    Write-Host -ForegroundColor White $VMNTP
    Write-Host -NoNewline -ForegroundColor Green "Syslog: "
    Write-Host -ForegroundColor White $VMSyslog

    Write-Host -ForegroundColor Magenta "`nWould you like to proceed with this deployment?`n"
    $answer = Read-Host -Prompt "Do you accept (Y or N)"
    if($answer -ne "Y" -or $answer -ne "y") {
        exit
    }
    Clear-Host
}

if($deployNestedESXiVMsForMgmt -eq 1 -or $deployNestedESXiVMsForWLD -eq 1 -or $deployCloudBuilder -eq 1 -or $moveVMsIntovApp -eq 1) {
    My-Logger "Connecting to Management vCenter Server $VIServer ..."
    $viConnection = Connect-VIServer $VIServer -User $VIUsername -Password $VIPassword -WarningAction SilentlyContinue

    $datastore = Get-Datastore -Server $viConnection -Name $VMDatastore | Select -First 1
    $cluster = Get-Cluster -Server $viConnection -Name $VMCluster
    $vmhost = $cluster | Get-VMHost | Get-Random -Count 1
}

if($deployNestedESXiVMsForMgmt -eq 1) {
    $NestedESXiHostnameToIPsForManagementDomain.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
        $VMName = $_.Key
        $VMIPAddress = $_.Value

        $ovfconfig = Get-OvfConfiguration $NestedESXiApplianceOVA
        $networkMapLabel = ($ovfconfig.ToHashTable().keys | where {$_ -Match "NetworkMapping"}).replace("NetworkMapping.","").replace("-","_").replace(" ","_")
        $ovfconfig.NetworkMapping.$networkMapLabel.value = $VMNetwork
        $ovfconfig.common.guestinfo.hostname.value = "${VMName}.${VMDomain}"
        $ovfconfig.common.guestinfo.ipaddress.value = $VMIPAddress
        $ovfconfig.common.guestinfo.netmask.value = $VMNetmask
        $ovfconfig.common.guestinfo.gateway.value = $VMGateway
        $ovfconfig.common.guestinfo.dns.value = $VMDNS
        $ovfconfig.common.guestinfo.domain.value = $VMDomain
        $ovfconfig.common.guestinfo.ntp.value = $VMNTP
        $ovfconfig.common.guestinfo.syslog.value = $VMSyslog
        $ovfconfig.common.guestinfo.password.value = $VMPassword
        $ovfconfig.common.guestinfo.ssh.value = $true

        My-Logger "Deploying Nested ESXi VM $VMName ..."
        $vm = Import-VApp -Source $NestedESXiApplianceOVA -OvfConfiguration $ovfconfig -Name $VMName -Location $VMCluster -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin

        My-Logger "Adding vmnic2/vmnic3 to Nested ESXi VMs ..."
        $vmPortGroup = Get-VirtualNetwork -Name $VMNetwork -Location ($cluster | Get-Datacenter)
        if($vmPortGroup.NetworkType -eq "Distributed") {
            $vmPortGroup = Get-VDPortgroup -Name $VMNetwork
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -Portgroup $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -Portgroup $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        } else {
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -NetworkName $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -NetworkName $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        }

        $vm | New-AdvancedSetting -name "ethernet2.filter4.name" -value "dvfilter-maclearn" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
        $vm | New-AdvancedSetting -Name "ethernet2.filter4.onFailure" -value "failOpen" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile

        $vm | New-AdvancedSetting -name "ethernet3.filter4.name" -value "dvfilter-maclearn" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
        $vm | New-AdvancedSetting -Name "ethernet3.filter4.onFailure" -value "failOpen" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Updating vCPU Count to $NestedESXiMGMTvCPU & vMEM to $NestedESXiMGMTvMEM GB ..."
        Set-VM -Server $viConnection -VM $vm -NumCpu $NestedESXiMGMTvCPU -CoresPerSocket $NestedESXiMGMTvCPU -MemoryGB $NestedESXiMGMTvMEM -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Updating vSAN Cache VMDK size to $NestedESXiMGMTCachingvDisk GB & Capacity VMDK size to $NestedESXiMGMTCapacityvDisk GB ..."
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 2" | Set-HardDisk -CapacityGB $NestedESXiMGMTCachingvDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 3" | Set-HardDisk -CapacityGB $NestedESXiMGMTCapacityvDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Updating vSAN Boot Disk size to $NestedESXiMGMTBootDisk GB ..."
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 1" | Set-HardDisk -CapacityGB $NestedESXiMGMTBootDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Powering On $vmname ..."
        $vm | Start-Vm -RunAsync | Out-Null
    }
}

if($deployNestedESXiVMsForWLD -eq 1) {
    $NestedESXiHostnameToIPsForWorkloadDomain.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
        $VMName = $_.Key
        $VMIPAddress = $_.Value

        $ovfconfig = Get-OvfConfiguration $NestedESXiApplianceOVA
        $networkMapLabel = ($ovfconfig.ToHashTable().keys | where {$_ -Match "NetworkMapping"}).replace("NetworkMapping.","").replace("-","_").replace(" ","_")
        $ovfconfig.NetworkMapping.$networkMapLabel.value = $VMNetwork
        $ovfconfig.common.guestinfo.hostname.value = "${VMName}.${VMDomain}"
        $ovfconfig.common.guestinfo.ipaddress.value = $VMIPAddress
        $ovfconfig.common.guestinfo.netmask.value = $VMNetmask
        $ovfconfig.common.guestinfo.gateway.value = $VMGateway
        $ovfconfig.common.guestinfo.dns.value = $VMDNS
        $ovfconfig.common.guestinfo.domain.value = $VMDomain
        $ovfconfig.common.guestinfo.ntp.value = $VMNTP
        $ovfconfig.common.guestinfo.syslog.value = $VMSyslog
        $ovfconfig.common.guestinfo.password.value = $VMPassword
        $ovfconfig.common.guestinfo.ssh.value = $true

        My-Logger "Deploying Nested ESXi VM $VMName ..."
        $vm = Import-VApp -Source $NestedESXiApplianceOVA -OvfConfiguration $ovfconfig -Name $VMName -Location $VMCluster -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin

        My-Logger "Adding vmnic2/vmnic3 to Nested ESXi VMs ..."
        $vmPortGroup = Get-VirtualNetwork -Name $VMNetwork -Location ($cluster | Get-Datacenter)
        if($vmPortGroup.NetworkType -eq "Distributed") {
            $vmPortGroup = Get-VDPortgroup -Name $VMNetwork
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -Portgroup $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -Portgroup $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        } else {
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -NetworkName $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
            New-NetworkAdapter -VM $vm -Type Vmxnet3 -NetworkName $vmPortGroup -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        }

        $vm | New-AdvancedSetting -name "ethernet2.filter4.name" -value "dvfilter-maclearn" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
        $vm | New-AdvancedSetting -Name "ethernet2.filter4.onFailure" -value "failOpen" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile

        $vm | New-AdvancedSetting -name "ethernet3.filter4.name" -value "dvfilter-maclearn" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
        $vm | New-AdvancedSetting -Name "ethernet3.filter4.onFailure" -value "failOpen" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Updating vCPU Count to $NestedESXiWLDvCPU & vMEM to $NestedESXiWLDvMEM GB ..."
        Set-VM -Server $viConnection -VM $vm -NumCpu $NestedESXiWLDvCPU -CoresPerSocket $NestedESXiWLDvCPU -MemoryGB $NestedESXiWLDvMEM -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Updating vSAN Cache VMDK size to $NestedESXiWLDCachingvDisk GB & Capacity VMDK size to $NestedESXiWLDCapacityvDisk GB ..."
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 2" | Set-HardDisk -CapacityGB $NestedESXiWLDCachingvDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 3" | Set-HardDisk -CapacityGB $NestedESXiWLDCapacityvDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Updating vSAN Boot Disk size to $NestedESXiWLDBootDisk GB ..."
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 1" | Set-HardDisk -CapacityGB $NestedESXiWLDBootDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        # vSAN ESA requires NVMe Controller
        if($NestedESXiWLDVSANESA) {
            My-Logger "Updating storage controller to NVMe for vSAN ESA ..."
            $devices = $vm.ExtensionData.Config.Hardware.Device

            $newControllerKey = -102

            # Reconfigure 1 - Add NVMe Controller & Update Disk Mapping to new controller
            $deviceChanges = @()
            $spec = New-Object VMware.Vim.VirtualMachineConfigSpec

            $scsiController = $devices | where {$_.getType().Name -eq "ParaVirtualSCSIController"}
            $scsiControllerDisks = $scsiController.device

            $nvmeControllerAddSpec = New-Object VMware.Vim.VirtualDeviceConfigSpec
            $nvmeControllerAddSpec.Device = New-Object VMware.Vim.VirtualNVMEController
            $nvmeControllerAddSpec.Device.Key = $newControllerKey
            $nvmeControllerAddSpec.Device.BusNumber = 0
            $nvmeControllerAddSpec.Operation = 'add'
            $deviceChanges+=$nvmeControllerAddSpec

            foreach ($scsiControllerDisk in $scsiControllerDisks) {
                $device = $devices | where {$_.key -eq $scsiControllerDisk}

                $changeControllerSpec = New-Object VMware.Vim.VirtualDeviceConfigSpec
                $changeControllerSpec.Operation = 'edit'
                $changeControllerSpec.Device = $device
                $changeControllerSpec.Device.key = $device.key
                $changeControllerSpec.Device.unitNumber = $device.UnitNumber
                $changeControllerSpec.Device.ControllerKey = $newControllerKey
                $deviceChanges+=$changeControllerSpec
            }

            $spec.deviceChange = $deviceChanges

            $task = $vm.ExtensionData.ReconfigVM_Task($spec)
            $task1 = Get-Task -Id ("Task-$($task.value)")
            $task1 | Wait-Task | Out-Null

            # Reconfigure 2 - Remove PVSCSI Controller
            $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
            $scsiControllerRemoveSpec = New-Object VMware.Vim.VirtualDeviceConfigSpec
            $scsiControllerRemoveSpec.Operation = 'remove'
            $scsiControllerRemoveSpec.Device = $scsiController
            $spec.deviceChange = $scsiControllerRemoveSpec

            $task = $vm.ExtensionData.ReconfigVM_Task($spec)
            $task1 = Get-Task -Id ("Task-$($task.value)")
            $task1 | Wait-Task | Out-Null
        }

        My-Logger "Powering On $vmname ..."
        $vm | Start-Vm -RunAsync | Out-Null
    }
}

if($deployCloudBuilder -eq 1) {
    $ovfconfig = Get-OvfConfiguration $CloudBuilderOVA

    $networkMapLabel = ($ovfconfig.ToHashTable().keys | where {$_ -Match "NetworkMapping"}).replace("NetworkMapping.","").replace("-","_").replace(" ","_")
    $ovfconfig.NetworkMapping.$networkMapLabel.value = $VMNetwork
    $ovfconfig.common.guestinfo.hostname.value = $CloudbuilderFQDN
    $ovfconfig.common.guestinfo.ip0.value = $CloudbuilderIP
    $ovfconfig.common.guestinfo.netmask0.value = $VMNetmask
    $ovfconfig.common.guestinfo.gateway.value = $VMGateway
    $ovfconfig.common.guestinfo.DNS.value = $VMDNS
    $ovfconfig.common.guestinfo.domain.value = $VMDomain
    $ovfconfig.common.guestinfo.searchpath.value = $VMDomain
    $ovfconfig.common.guestinfo.ntp.value = $VMNTP
    $ovfconfig.common.guestinfo.ADMIN_USERNAME.value = $CloudbuilderAdminUsername
    $ovfconfig.common.guestinfo.ADMIN_PASSWORD.value = $CloudbuilderAdminPassword
    $ovfconfig.common.guestinfo.ROOT_PASSWORD.value = $CloudbuilderRootPassword

    My-Logger "Deploying Cloud Builder VM $CloudbuilderVMHostname ..."
    $vm = Import-VApp -Source $CloudBuilderOVA -OvfConfiguration $ovfconfig -Name $CloudbuilderVMHostname -Location $VMCluster -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin

    My-Logger "Powering On $CloudbuilderVMHostname ..."
    $vm | Start-Vm -RunAsync | Out-Null
}

if($moveVMsIntovApp -eq 1) {
    # Check whether DRS is enabled as that is required to create vApp
    if((Get-Cluster -Server $viConnection $cluster).DrsEnabled) {
        My-Logger "Creating vApp $VAppName ..."
        $rp = Get-ResourcePool -Name Resources -Location $cluster
        $VApp = New-VApp -Name $VAppName -Server $viConnection -Location $cluster

        if(-Not (Get-Folder $VMFolder -ErrorAction Ignore)) {
            My-Logger "Creating VM Folder $VMFolder ..."
            $folder = New-Folder -Name $VMFolder -Server $viConnection -Location (Get-Datacenter $VMDatacenter | Get-Folder vm)
        }

        if($deployNestedESXiVMsForMgmt -eq 1) {
            My-Logger "Moving Nested ESXi VMs into $VAppName vApp ..."
            $NestedESXiHostnameToIPsForManagementDomain.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
                $vm = Get-VM -Name $_.Key -Server $viConnection -Location $cluster | where{$_.ResourcePool.Id -eq $rp.Id}
                Move-VM -VM $vm -Server $viConnection -Destination $VApp -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
            }
        }

        if($deployNestedESXiVMsForWLD -eq 1) {
            My-Logger "Moving Nested ESXi VMs into $VAppName vApp ..."
            $NestedESXiHostnameToIPsForWorkloadDomain.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
                $vm = Get-VM -Name $_.Key -Server $viConnection -Location $cluster | where{$_.ResourcePool.Id -eq $rp.Id}
                Move-VM -VM $vm -Server $viConnection -Destination $VApp -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
            }
        }

        if($deployCloudBuilder -eq 1) {
            $cloudBuilderVM = Get-VM -Name $CloudbuilderVMHostname -Server $viConnection -Location $cluster | where{$_.ResourcePool.Id -eq $rp.Id}
            My-Logger "Moving $CloudbuilderVMHostname into $VAppName vApp ..."
            Move-VM -VM $cloudBuilderVM -Server $viConnection -Destination $VApp -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        }

        My-Logger "Moving $VAppName to VM Folder $VMFolder ..."
        Move-VApp -Server $viConnection $VAppName -Destination (Get-Folder -Server $viConnection $VMFolder) | Out-File -Append -LiteralPath $verboseLogFile
    } else {
        My-Logger "vApp $VAppName will NOT be created as DRS is NOT enabled on vSphere Cluster ${cluster} ..."
    }
}

if($generateMgmJson -eq 1) {
    if($SeparateNSXSwitch) { $useNSX = "false" } else { $useNSX = "true" }

    $esxivMotionNetwork = $NestedESXivMotionNetworkCidr.split("/")[0]
    $esxivMotionNetworkOctects = $esxivMotionNetwork.split(".")
    $esxivMotionGateway = ($esxivMotionNetworkOctects[0..2] -join '.') + ".1"
    $esxivMotionStart = ($esxivMotionNetworkOctects[0..2] -join '.') + ".101"
    $esxivMotionEnd = ($esxivMotionNetworkOctects[0..2] -join '.') + ".118"

    $esxivSANNetwork = $NestedESXivSANNetworkCidr.split("/")[0]
    $esxivSANNetworkOctects = $esxivSANNetwork.split(".")
    $esxivSANGateway = ($esxivSANNetworkOctects[0..2] -join '.') + ".1"
    $esxivSANStart = ($esxivSANNetworkOctects[0..2] -join '.') + ".101"
    $esxivSANEnd = ($esxivSANNetworkOctects[0..2] -join '.') + ".118"

    $esxiNSXTepNetwork = $NestedESXiNSXTepNetworkCidr.split("/")[0]
    $esxiNSXTepNetworkOctects = $esxiNSXTepNetwork.split(".")
    $esxiNSXTepGateway = ($esxiNSXTepNetworkOctects[0..2] -join '.') + ".1"
    $esxiNSXTepStart = ($esxiNSXTepNetworkOctects[0..2] -join '.') + ".101"
    $esxiNSXTepEnd = ($esxiNSXTepNetworkOctects[0..2] -join '.') + ".118"

    $hostSpecs = @()
    $count = 1
    $NestedESXiHostnameToIPsForManagementDomain.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
        $VMName = $_.Key
        $VMIPAddress = $_.Value

        $hostSpec = [ordered]@{
            "association" = "vcf-m01-dc01"
            "ipAddressPrivate" = [ordered]@{
                "ipAddress" = $VMIPAddress
                "cidr" = $NestedESXiManagementNetworkCidr
                "gateway" = $VMGateway
            }
            "hostname" = $VMName
            "credentials" = [ordered]@{
                "username" = "root"
                "password" = $VMPassword
            }
            "sshThumbprint" = "SHA256:DUMMY_VALUE"
            "sslThumbprint" = "SHA25_DUMMY_VALUE"
            "vSwitch" = "vSwitch0"
            "serverId" = "host-$count"
        }
        $hostSpecs+=$hostSpec
        $count++
    }

    $vcfConfig = [ordered]@{
        "skipEsxThumbprintValidation" = $true
        "managementPoolName" = $VCFManagementDomainPoolName
        "sddcId" = "vcf-m01"
        "taskName" = "workflowconfig/workflowspec-ems.json"
        "esxLicense" = "$ESXILicense"
        "ceipEnabled" = $true
        "ntpServers" = @($VMNTP)
        "dnsSpec" = [ordered]@{
            "subdomain" = $VMDomain
            "domain" = $VMDomain
            "nameserver" = $VMDNS
        }
        "sddcManagerSpec" = [ordered]@{
            "ipAddress" = $SddcManagerIP
            "netmask" = $VMNetmask
            "hostname" = $SddcManagerHostname
            "localUserPassword" = "$SddcManagerLocalPassword"
            "vcenterId" = "vcenter-1"
            "secondUserCredentials" = [ordered]@{
                "username" = "vcf"
                "password" = $SddcManagerVcfPassword
            }
            "rootUserCredentials" = [ordered]@{
                "username" = "root"
                "password" = $SddcManagerRootPassword
            }
            "restApiCredentials" = [ordered]@{
                "username" = "admin"
                "password" = $SddcManagerRestPassword
            }
        }
        "networkSpecs" = @(
            [ordered]@{
                "networkType" = "MANAGEMENT"
                "subnet" = $NestedESXiManagementNetworkCidr
                "gateway" = $VMGateway
                "vlanId" = "0"
                "mtu" = "1500"
                "portGroupKey" = "vcf-m01-cl01-vds01-pg-mgmt"
                "standbyUplinks" = @()
                "activeUplinks" = @("uplink1","uplink2")
            }
            [ordered]@{
                "networkType" = "VMOTION"
                "subnet" = $NestedESXivMotionNetworkCidr
                "gateway" = $esxivMotionGateway
                "vlanId" = "0"
                "mtu" = "9000"
                "portGroupKey" = "vcf-m01-cl01-vds01-pg-vmotion"
                "association" = "vcf-m01-dc01"
                "includeIpAddressRanges" = @(@{"startIpAddress" = $esxivMotionStart;"endIpAddress" = $esxivMotionEnd})
                "standbyUplinks" = @()
                "activeUplinks" = @("uplink1","uplink2")
            }
            [ordered]@{
                "networkType" = "VSAN"
                "subnet" = $NestedESXivSANNetworkCidr
                "gateway"= $esxivSANGateway
                "vlanId" = "0"
                "mtu" = "9000"
                "portGroupKey" = "vcf-m01-cl01-vds01-pg-vsan"
                "includeIpAddressRanges" = @(@{"startIpAddress" = $esxivSANStart;"endIpAddress" = $esxivSANEnd})
                "standbyUplinks" = @()
                "activeUplinks" = @("uplink1","uplink2")
            }
        )
        "nsxtSpec" = [ordered]@{
            "nsxtManagerSize" = "small"
            "nsxtManagers" = @(@{"hostname" = $NSXManagerNode1Hostname;"ip" = $NSXManagerNode1IP})
            "rootNsxtManagerPassword" = $NSXRootPassword
            "nsxtAdminPassword" = $NSXAdminPassword
            "nsxtAuditPassword" = $NSXAuditPassword
            "rootLoginEnabledForNsxtManager" = $true
            "sshEnabledForNsxtManager" = $true
            "overLayTransportZone" = [ordered]@{
                "zoneName" = "vcf-m01-tz-overlay01"
                "networkName" = "netName-overlay"
            }
            "vlanTransportZone" = [ordered]@{
                "zoneName" = "vcf-m01-tz-vlan01"
                "networkName" = "netName-vlan"
            }
            "vip" = $NSXManagerVIPIP
            "vipFqdn" = $NSXManagerVIPHostname
            "nsxtLicense" = $NSXLicense
            "transportVlanId" = "2005"
            "ipAddressPoolSpec" = [ordered]@{
                "name" = "vcf-m01-c101-tep01"
                "description" = "ESXi Host Overlay TEP IP Pool"
                "subnets" = @(
                    @{
                        "ipAddressPoolRanges" = @(@{"start" = $esxiNSXTepStart;"end" = $esxiNSXTepEnd})
                        "cidr" = $NestedESXiNSXTepNetworkCidr
                        "gateway" = $esxiNSXTepGateway
                    }
                )
            }
        }
        "vsanSpec" = [ordered]@{
            "vsanName" = "vsan-1"
            "vsanDedup" = "false"
            "licenseFile" = $VSANLicense
            "datastoreName" = "vcf-m01-cl01-ds-vsan01"
        }
        "dvSwitchVersion" = "7.0.0"
        "dvsSpecs" = @(
            [ordered]@{
                "dvsName" = "vcf-m01-cl01-vds01"
                "vcenterId" = "vcenter-1"
                "vmnics" = @("vmnic0","vmnic1")
                "mtu" = "9000"
                "networks" = @(
                    "MANAGEMENT",
                    "VMOTION",
                    "VSAN"
                )
                "niocSpecs" = @(
                    @{"trafficType"="VSAN";"value"="HIGH"}
                    @{"trafficType"="VMOTION";"value"="LOW"}
                    @{"trafficType"="VDP";"value"="LOW"}
                    @{"trafficType"="VIRTUALMACHINE";"value"="HIGH"}
                    @{"trafficType"="MANAGEMENT";"value"="NORMAL"}
                    @{"trafficType"="NFS";"value"="LOW"}
                    @{"trafficType"="HBR";"value"="LOW"}
                    @{"trafficType"="FAULTTOLERANCE";"value"="LOW"}
                    @{"trafficType"="ISCSI";"value"="LOW"}
                )
                "isUsedByNsxt" = $useNSX
            }
        )
        "clusterSpec" = [ordered]@{
            "clusterName" = "vcf-m01-cl01"
            "vcenterName" = "vcenter-1"
            "clusterEvcMode" = ""
            "vmFolders" = [ordered] @{
                "MANAGEMENT" = "vcf-m01-fd-mgmt"
                "NETWORKING" = "vcf-m01-fd-nsx"
                "EDGENODES" = "vcf-m01-fd-edge"
            }
            "clusterImageEnabled" = $EnableVCLM
        }
        "resourcePoolSpecs" =@(
            [ordered]@{
                "name" = "vcf-m01-cl01-rp-sddc-mgmt"
                "type" = "management"
                "cpuReservationPercentage" = 0
                "cpuLimit" = -1
                "cpuReservationExpandable" = $true
                "cpuSharesLevel" = "normal"
                "cpuSharesValue" = 0
                "memoryReservationMb" = 0
                "memoryLimit" = -1
                "memoryReservationExpandable" = $true
                "memorySharesLevel" = "normal"
                "memorySharesValue" = 0
            }
            [ordered]@{
                "name" = "vcf-m01-cl01-rp-sddc-edge"
                "type" = "network"
                "cpuReservationPercentage" = 0
                "cpuLimit" = -1
                "cpuReservationExpandable" = $true
                "cpuSharesLevel" = "normal"
                "cpuSharesValue" = 0
                "memoryReservationPercentage" = 0
                "memoryLimit" = -1
                "memoryReservationExpandable" = $true
                "memorySharesLevel" = "normal"
                "memorySharesValue" = 0
            }
            [ordered]@{
                "name" = "vcf-m01-cl01-rp-user-edge"
                "type" = "compute"
                "cpuReservationPercentage" = 0
                "cpuLimit" = -1
                "cpuReservationExpandable" = $true
                "cpuSharesLevel" = "normal"
                "cpuSharesValue" = 0
                "memoryReservationPercentage" = 0
                "memoryLimit" = -1
                "memoryReservationExpandable" = $true
                "memorySharesLevel" = "normal"
                "memorySharesValue" = 0
            }
            [ordered]@{
                "name" = "vcf-m01-cl01-rp-user-vm"
                "type" = "compute"
                "cpuReservationPercentage" = 0
                "cpuLimit" = -1
                "cpuReservationExpandable" = $true
                "cpuSharesLevel" = "normal"
                "cpuSharesValue" = 0
                "memoryReservationPercentage" = 0
                "memoryLimit" = -1
                "memoryReservationExpandable" = $true
                "memorySharesLevel" = "normal"
                "memorySharesValue" = 0
            }
        )
        "pscSpecs" = @(
            [ordered]@{
                "pscId" = "psc-1"
                "vcenterId" = "vcenter-1"
                "adminUserSsoPassword" = $VCSASSOPassword
                "pscSsoSpec" = @{"ssoDomain"="vsphere.local"}
            }
        )
        "vcenterSpec" = [ordered]@{
            "vcenterIp" = $VCSAIP
            "vcenterHostname" = $VCSAName
            "vcenterId" = "vcenter-1"
            "licenseFile" = $VCSALicense
            "vmSize" = "tiny"
            "storageSize" = ""
            "rootVcenterPassword" = $VCSARootPassword
        }
        "hostSpecs" = $hostSpecs
        "excludedComponents" = @("NSX-V", "AVN", "EBGP")
    }

    if($SeparateNSXSwitch) {
        $sepNsxSwitchSpec = [ordered]@{
            "dvsName" = "vcf-m01-nsx-vds01"
            "vcenterId" = "vcenter-1"
            "vmnics" = @("vmnic2","vmnic3")
            "mtu" = 9000
            "networks" = @()
            "isUsedByNsxt" = $true

        }
        $vcfConfig.dvsSpecs+=$sepNsxSwitchSpec
    }

    # License Later feature only applicable for VCF 5.1.1 and later
    if($VCFVersion -ge "5.1.1") {
        if($VCSALicense -eq "" -and $ESXILicense -eq "" -and $VSANLicense -eq "" -and $NSXLicense -eq "") {
            $EvaluationMode = $true
        } else {
            $EvaluationMode = $false
        }
        $vcfConfig.add("deployWithoutLicenseKeys",$EvaluationMode)
    }

    My-Logger "Generating Cloud Builder VCF Management Domain configuration deployment file $VCFManagementDomainJSONFile"
    $vcfConfig | ConvertTo-Json -Depth 20 | Out-File -LiteralPath $VCFManagementDomainJSONFile
}

if($generateWldHostCommissionJson -eq 1) {
    My-Logger "Generating Cloud Builder VCF Workload Domain Host Commission file $VCFWorkloadDomainUIJSONFile and $VCFWorkloadDomainAPIJSONFile for SDDC Manager UI and API"

    $commissionHostsUI= @()
    $commissionHostsAPI= @()
    $NestedESXiHostnameToIPsForWorkloadDomain.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
        $hostFQDN = $_.Key + "." + $VMDomain

        $tmp1 = [ordered] @{
            "hostfqdn" = $hostFQDN;
            "username" = "root";
            "password" = $VMPassword;
            "networkPoolName" = "$VCFManagementDomainPoolName";
            "storageType" = "VSAN";
        }
        $commissionHostsUI += $tmp1

        $tmp2 = [ordered] @{
            "fqdn" = $hostFQDN;
            "username" = "root";
            "password" = $VMPassword;
            "networkPoolId" = "TBD";
            "storageType" = "VSAN";
        }
        $commissionHostsAPI += $tmp2
    }

    $vcfCommissionHostConfigUI = @{
        "hostsSpec" = $commissionHostsUI
    }

    $vcfCommissionHostConfigUI | ConvertTo-Json -Depth 2 | Out-File -LiteralPath $VCFWorkloadDomainUIJSONFile
    $commissionHostsAPI | ConvertTo-Json -Depth 2 | Out-File -LiteralPath $VCFWorkloadDomainAPIJSONFile
}

if($startVCFBringup -eq 1) {
    My-Logger "Starting VCF Deployment Bringup ..."

    My-Logger "Waiting for Cloud Builder to be ready ..."
    while(1) {
        $pair = "${CloudbuilderAdminUsername}:${CloudbuilderAdminPassword}"
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
        $base64 = [System.Convert]::ToBase64String($bytes)

        try {
            if($PSVersionTable.PSEdition -eq "Core") {
                $requests = Invoke-WebRequest -Uri "https://$($CloudbuilderIP)/v1/sddcs" -Method GET -SkipCertificateCheck -TimeoutSec 5 -Headers @{"Authorization"="Basic $base64"}
            } else {
                $requests = Invoke-WebRequest -Uri "https://$($CloudbuilderIP)/v1/sddcs" -Method GET -TimeoutSec 5 -Headers @{"Authorization"="Basic $base64"}
            }
            if($requests.StatusCode -eq 200) {
                My-Logger "Cloud Builder is now ready!"
                break
            }
        }
        catch {
            My-Logger "Cloud Builder is not ready yet, sleeping for 120 seconds ..."
            sleep 120
        }
    }

    My-Logger "Submitting VCF Bringup request ..."

    $inputJson = Get-Content -Raw $VCFManagementDomainJSONFile
    $pwd = ConvertTo-SecureString $CloudbuilderAdminPassword -AsPlainText -Force
    $cred = New-Object Management.Automation.PSCredential ($CloudbuilderAdminUsername,$pwd)
    $bringupAPIParms = @{
        Uri         = "https://${CloudbuilderIP}/v1/sddcs"
        Method      = 'POST'
        Body        = $inputJson
        ContentType = 'application/json'
        Credential = $cred
    }
    $bringupAPIReturn = Invoke-RestMethod @bringupAPIParms -SkipCertificateCheck
    My-Logger "Open browser to the VMware Cloud Builder UI (https://${CloudbuilderFQDN}) to monitor deployment progress ..."
}

if($startVCFBringup -eq 1 -and $uploadVCFNotifyScript -eq 1) {
    if(Test-Path $srcNotificationScript) {
        $cbVM = Get-VM -Server $viConnection $CloudbuilderFQDN

        My-Logger "Uploading VCF notification script $srcNotificationScript to $dstNotificationScript on Cloud Builder appliance ..."
        Copy-VMGuestFile -Server $viConnection -VM $cbVM -Source $srcNotificationScript -Destination $dstNotificationScript -LocalToGuest -GuestUser "root" -GuestPassword $CloudbuilderRootPassword | Out-Null
        Invoke-VMScript -Server $viConnection -VM $cbVM -ScriptText "chmod +x $dstNotificationScript" -GuestUser "root" -GuestPassword $CloudbuilderRootPassword | Out-Null

        My-Logger "Configuring crontab to run notification check script every 15 minutes ..."
        Invoke-VMScript -Server $viConnection -VM $cbVM -ScriptText "echo '*/15 * * * * $dstNotificationScript' > /var/spool/cron/root" -GuestUser "root" -GuestPassword $CloudbuilderRootPassword | Out-Null
    }
}

if($deployNestedESXiVMsForMgmt -eq 1 -or $deployNestedESXiVMsForWLD -eq 1 -or $deployCloudBuilder -eq 1) {
    My-Logger "Disconnecting from $VIServer ..."
    Disconnect-VIServer -Server $viConnection -Confirm:$false
}

$EndTime = Get-Date
$duration = [math]::Round((New-TimeSpan -Start $StartTime -End $EndTime).TotalMinutes,2)

My-Logger "VCF Lab Deployment Complete!"
My-Logger "StartTime: $StartTime"
My-Logger "EndTime: $EndTime"
My-Logger "Duration: $duration minutes to Deploy Nested ESXi, CloudBuilder & initiate VCF Bringup"
