# Author: William Lam
# Website: www.williamlam.com

# vCenter Server used to deploy VMware Cloud Foundation Lab
$VIServer = "FILL-ME-IN"
$VIUsername = "FILL-ME-IN"
$VIPassword = "FILL-ME-IN"

# Full Path to both the Nested ESXi 7.0u1d & Cloud Builder oVA
$NestedESXiApplianceOVA = "C:\Users\william\Desktop\VCF\Nested_ESXi7.0u1d_Appliance_Template_v1.ova"
$CloudBuilderOVA = "C:\Users\william\Desktop\VCF\VMware-Cloud-Builder-4.2.0.0-17559673_OVF10.ova"

# VCF Required Licenses
$VCSALicense = "FILL-ME-IN"
$ESXILicense = "FILL-ME-IN"
$VSANLicense = "FILL-ME-IN"
$NSXLicense = "FILL-ME-IN"

# Cloud Builder Configurations
$CloudbuilderVMName = "vcf-m01-cb01"
$CloudbuilderHostname = "vcf-m01-cb01.tshirts.inc"
$CloudbuilderIP = "172.17.31.180"
$CloudbuilderAdminUsername = "admin"
$CloudbuilderAdminPassword = "VMw@re123!"
$CloudbuilderRootPassword = "VMw@re123!"

# SDDC Manager Configuration
$SddcManagerName = "vcf-m01-sddcm01"
$SddcManagerIP = "172.17.31.181"
$SddcManagerVcfPassword = "VMware1!VMware1!"
$SddcManagerRootPassword = "VMware1!VMware1!"
$SddcManagerRestPassword = "VMware1!VMware1!"
$SddcManagerLocalPassword = "VMware1!VMware1!"

# Nested ESXi VMs to deploy
$NestedESXiHostnameToIPs = @{
    "vcf-m01-esx01"   = "172.17.31.185"
    "vcf-m01-esx02"   = "172.17.31.186"
    "vcf-m01-esx03"   = "172.17.31.187"
    "vcf-m01-esx04"   = "172.17.31.188"
}

# Nested ESXi VM Resources
$NestedESXivCPU = "8"
$NestedESXivMEM = "38" #GB
$NestedESXiCachingvDisk = "4" #GB
$NestedESXiCapacityvDisk = "60" #GB
$NestedESXiBootDisk = "32" #GB

# ESXi Configuration
$NestedESXiManagementNetworkCidr = "172.17.31.0/24" # should match $VMNetwork configuration

# vCenter Configuration
$VCSAName = "vcf-m01-vc01"
$VCSAIP = "172.17.31.182"
$VCSARootPassword = "VMware1!"
$VCSASSOPassword = "VMware1!"

# NSX Configuration
$NSXManagerVIPName = "vcf-m01-nsx01"
$NSXManagerVIPIP = "172.17.31.183"
$NSXManagerNode1Name = "vcf-m01-nsx01a"
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

$preCheck = 1
$confirmDeployment = 1
$deployNestedESXiVMs = 1
$deployCloudBuilder = 1
$moveVMsIntovApp = 1
$generateJson = 1

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
    Write-Host -ForegroundColor White $CloudbuilderHostname
    Write-Host -NoNewline -ForegroundColor Green "IP Address: "
    Write-Host -ForegroundColor White $CloudbuilderIP

    Write-Host -ForegroundColor Yellow "`n---- vESXi Configuration ----"
    Write-Host -NoNewline -ForegroundColor Green "# of Nested ESXi VMs: "
    Write-Host -ForegroundColor White $NestedESXiHostnameToIPs.count
    Write-Host -NoNewline -ForegroundColor Green "vCPU: "
    Write-Host -ForegroundColor White $NestedESXivCPU
    Write-Host -NoNewline -ForegroundColor Green "vMEM: "
    Write-Host -ForegroundColor White "$NestedESXivMEM GB"
    Write-Host -NoNewline -ForegroundColor Green "Caching VMDK: "
    Write-Host -ForegroundColor White "$NestedESXiCachingvDisk GB"
    Write-Host -NoNewline -ForegroundColor Green "Capacity VMDK: "
    Write-Host -ForegroundColor White "$NestedESXiCapacityvDisk GB"
    Write-Host -NoNewline -ForegroundColor Green "IP Address(s): "
    Write-Host -ForegroundColor White $NestedESXiHostnameToIPs.Values
    Write-Host -NoNewline -ForegroundColor Green "Netmask "
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

if($deployNestedESXiVMs -eq 1 -or $deployCloudBuilder -eq 1) {
    My-Logger "Connecting to Management vCenter Server $VIServer ..."
    $viConnection = Connect-VIServer $VIServer -User $VIUsername -Password $VIPassword -WarningAction SilentlyContinue

    $datastore = Get-Datastore -Server $viConnection -Name $VMDatastore | Select -First 1
    $cluster = Get-Cluster -Server $viConnection -Name $VMCluster
    $datacenter = $cluster | Get-Datacenter
    $vmhost = $cluster | Get-VMHost | Select -First 1
}

if($deployNestedESXiVMs -eq 1) {
    $NestedESXiHostnameToIPs.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
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

        My-Logger "Adding vmnic2/vmnic3 for `"$VMNetwork`" and `"$VMNetwork`" to passthrough to Nested ESXi VMs ..."
        New-NetworkAdapter -VM $vm -Type Vmxnet3 -NetworkName $VMNetwork -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        New-NetworkAdapter -VM $vm -Type Vmxnet3 -NetworkName $VMNetwork -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        $vm | New-AdvancedSetting -name "ethernet2.filter4.name" -value "dvfilter-maclearn" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
        $vm | New-AdvancedSetting -Name "ethernet2.filter4.onFailure" -value "failOpen" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile

        $vm | New-AdvancedSetting -name "ethernet3.filter4.name" -value "dvfilter-maclearn" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
        $vm | New-AdvancedSetting -Name "ethernet3.filter4.onFailure" -value "failOpen" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Updating vCPU Count to $NestedESXivCPU & vMEM to $NestedESXivMEM GB ..."
        Set-VM -Server $viConnection -VM $vm -NumCpu $NestedESXivCPU -MemoryGB $NestedESXivMEM -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Updating vSAN Cache VMDK size to $NestedESXiCachingvDisk GB & Capacity VMDK size to $NestedESXiCapacityvDisk GB ..."
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 2" | Set-HardDisk -CapacityGB $NestedESXiCachingvDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 3" | Set-HardDisk -CapacityGB $NestedESXiCapacityvDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Updating vSAN Boot Disk size to $NestedESXiBootDisk GB ..."
        Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 1" | Set-HardDisk -CapacityGB $NestedESXiBootDisk -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

        My-Logger "Powering On $vmname ..."
        $vm | Start-Vm -RunAsync | Out-Null
    }
}

if($deployCloudBuilder -eq 1) {
    $ovfconfig = Get-OvfConfiguration $CloudBuilderOVA

    $networkMapLabel = ($ovfconfig.ToHashTable().keys | where {$_ -Match "NetworkMapping"}).replace("NetworkMapping.","").replace("-","_").replace(" ","_")
    $ovfconfig.NetworkMapping.$networkMapLabel.value = $VMNetwork
    $ovfconfig.common.guestinfo.hostname.value = $CloudbuilderHostname
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

    My-Logger "Deploying Cloud Builder VM $CloudbuilderVMName ..."
    $vm = Import-VApp -Source $CloudBuilderOVA -OvfConfiguration $ovfconfig -Name $CloudbuilderVMName -Location $VMCluster -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin

    My-Logger "Powering On $CloudbuilderVMName ..."
    $vm | Start-Vm -RunAsync | Out-Null
}

if($moveVMsIntovApp -eq 1) {
    My-Logger "Creating vApp $VAppName ..."
    $VApp = New-VApp -Name $VAppName -Server $viConnection -Location $cluster

    if(-Not (Get-Folder $VMFolder -ErrorAction Ignore)) {
        My-Logger "Creating VM Folder $VMFolder ..."
        $folder = New-Folder -Name $VMFolder -Server $viConnection -Location (Get-Datacenter $VMDatacenter | Get-Folder vm)
    }

    if($deployNestedESXiVMs -eq 1) {
        My-Logger "Moving Nested ESXi VMs into $VAppName vApp ..."
        $NestedESXiHostnameToIPs.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
            $vm = Get-VM -Name $_.Key -Server $viConnection
            Move-VM -VM $vm -Server $viConnection -Destination $VApp -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
        }
    }

    if($deployCloudBuilder -eq 1) {
        $cloudBuilderVM = Get-VM -Name $CloudbuilderVMName -Server $viConnection
        My-Logger "Moving $CloudbuilderVMName into $VAppName vApp ..."
        Move-VM -VM $cloudBuilderVM -Server $viConnection -Destination $VApp -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
    }

    My-Logger "Moving $VAppName to VM Folder $VMFolder ..."
    Move-VApp -Server $viConnection $VAppName -Destination (Get-Folder -Server $viConnection $VMFolder) | Out-File -Append -LiteralPath $verboseLogFile
}

if($deployNestedESXiVMs -eq 1 -or $deployCloudBuilder -eq 1) {
    My-Logger "Disconnecting from $VIServer ..."
    Disconnect-VIServer -Server $viConnection -Confirm:$false
}

if($generateJson -eq 1) {
    if($SeparateNSXSwitch) { $useNSX = "false" } else { $useNSX = "true" }

    $vcfStartConfig1 = @"
{
    "skipEsxThumbprintValidation": true,
    "managementPoolName": "vcf-m01-rp01",
    "sddcManagerSpec": {
        "secondUserCredentials": {
        "username": "vcf",
        "password": "$SddcManagerVcfPassword"
        },
        "ipAddress": "$SddcManagerIP",
        "netmask": "$VMNetmask",
        "hostname": "$SddcManagerName",
        "rootUserCredentials": {
        "username": "root",
        "password": "$SddcManagerRootPassword"
        },
        "restApiCredentials": {
        "username": "admin",
        "password": "$SddcManagerRestPassword"
        },
        "localUserPassword": "$SddcManagerLocalPassword",
        "vcenterId": "vcenter-1"
    },
    "sddcId": "vcf-m01",
    "esxLicense": "$ESXILicense",
    "taskName": "workflowconfig/workflowspec-ems.json",
    "ceipEnabled": true,
    "ntpServers": ["$VMNTP"],
    "dnsSpec": {
        "subdomain": "$VMDomain",
        "domain": "$VMDomain",
        "nameserver": "$VMDNS"
    },
    "networkSpecs": [
        {
        "networkType": "MANAGEMENT",
        "subnet": "$NestedESXiManagementNetworkCidr",
        "gateway": "$VMGateway",
        "vlanId": "0",
        "mtu": "1500",
        "portGroupKey": "vcf-m01-cl01-vds01-pg-mgmt",
        "standbyUplinks":[],
        "activeUplinks":[
            "uplink1",
            "uplink2"
        ]
        },
        {
        "networkType": "VMOTION",
        "subnet": "10.0.3.0/24",
        "gateway": "10.0.3.1",
        "vlanId": "0",
        "mtu": "9000",
        "portGroupKey": "vcf-m01-cl01-vds01-pg-vmotion",
        "association": "vcf-m01-dc01",
        "includeIpAddressRanges": [{"endIpAddress": "10.0.3.8","startIpAddress": "10.0.3.5"}],
        "standbyUplinks":[],
        "activeUplinks":[
            "uplink1",
            "uplink2"
        ]
        },
        {
        "networkType": "VSAN",
        "subnet": "10.0.4.0/24",
        "gateway": "10.0.4.1",
        "vlanId": "0",
        "mtu": "9000",
        "portGroupKey": "vcf-m01-cl01-vds01-pg-vsan",
        "includeIpAddressRanges": [{"endIpAddress": "10.0.4.8", "startIpAddress": "10.0.4.5"}],
        "standbyUplinks":[],
        "activeUplinks":[
            "uplink1",
            "uplink2"
        ]
        }
    ],
    "nsxtSpec":
    {
        "nsxtManagerSize": "small",
        "nsxtManagers": [
        {
            "hostname": "$NSXManagerNode1Name",
            "ip": "$NSXManagerNode1IP"
        }
        ],
        "rootNsxtManagerPassword": "$NSXRootPassword",
        "nsxtAdminPassword": "$NSXAdminPassword",
        "nsxtAuditPassword": "$NSXAuditPassword",
        "rootLoginEnabledForNsxtManager": "true",
        "sshEnabledForNsxtManager": "true",
        "overLayTransportZone": {
            "zoneName": "vcf-m01-tz-overlay01",
            "networkName": "netName-overlay"
        },
        "vlanTransportZone": {
            "zoneName": "vcf-m01-tz-vlan01",
            "networkName": "netName-vlan"
        },
        "vip": "$NSXManagerVIPIP",
        "vipFqdn": "$NSXManagerVIPName",
        "nsxtLicense": "$NSXLicense",
        "transportVlanId": 2005,
        "ipAddressPoolSpec" : {
          "name" : "vcf-m01-c101-tep01",
          "description" : "ESXi Host Overlay TEP IP Pool",
          "subnets" : [ {
            "ipAddressPoolRanges" : [ {
              "start" : "172.16.14.101",
              "end" : "172.16.14.108"
            } ],
            "cidr" : "172.16.14.0/24",
            "gateway" : "172.16.14.1"
          } ]
        }
    },
    "vsanSpec": {
        "vsanName": "vsan-1",
        "vsanDedup": "false",
        "licenseFile": "$VSANLicense",
        "datastoreName": "vcf-m01-cl01-ds-vsan01"
    },
    "dvSwitchVersion": "7.0.0",
    "dvsSpecs": [
        {
        "dvsName": "vcf-m01-cl01-vds01",
        "vcenterId":"vcenter-1",
        "vmnics": [
            "vmnic0",
            "vmnic1"
        ],
        "mtu": 9000,
        "networks":[
            "MANAGEMENT",
            "VMOTION",
            "VSAN"
        ],
        "niocSpecs":[
            {
            "trafficType":"VSAN",
            "value":"HIGH"
            },
            {
            "trafficType":"VMOTION",
            "value":"LOW"
            },
            {
            "trafficType":"VDP",
            "value":"LOW"
            },
            {
            "trafficType":"VIRTUALMACHINE",
            "value":"HIGH"
            },
            {
            "trafficType":"MANAGEMENT",
            "value":"NORMAL"
            },
            {
            "trafficType":"NFS",
            "value":"LOW"
            },
            {
            "trafficType":"HBR",
            "value":"LOW"
            },
            {
            "trafficType":"FAULTTOLERANCE",
            "value":"LOW"
            },
            {
            "trafficType":"ISCSI",
            "value":"LOW"
            }
        ],
        "isUsedByNsxt": $useNSX
        }
"@

    $vcfNetworkConfig = @"

        ,{
            "dvsName": "vcf-m01-nsx-vds01",
            "vcenterId":"vcenter-1",
            "vmnics": [
                "vmnic2",
                "vmnic3"
            ],
            "mtu": 9000,
            "networks":[
            ],
            "isUsedByNsxt": true
        }
"@

    if($SeparateNSXSwitch) {
        $vcfStartConfig1 = $vcfStartConfig1 + $vcfNetworkConfig
    }

    $vcfStartConfig2 =
@"

    ],
    "clusterSpec":
    {
        "clusterName": "vcf-m01-cl01",
        "vcenterName": "vcenter-1",
        "clusterEvcMode": "",
        "vmFolders": {
        "MANAGEMENT": "vcf-m01-fd-mgmt",
        "NETWORKING": "vcf-m01-fd-nsx",
        "EDGENODES": "vcf-m01-fd-edge"
        }
    },
    "resourcePoolSpecs": [{
        "name": "vcf-m01-cl01-rp-sddc-mgmt",
        "type": "management",
        "cpuReservationPercentage": 0,
        "cpuLimit": -1,
        "cpuReservationExpandable": true,
        "cpuSharesLevel": "normal",
        "cpuSharesValue": 0,
        "memoryReservationMb": 0,
        "memoryLimit": -1,
        "memoryReservationExpandable": true,
        "memorySharesLevel": "normal",
        "memorySharesValue": 0
    }, {
        "name": "vcf-m01-cl01-rp-sddc-edge",
        "type": "network",
        "cpuReservationPercentage": 0,
        "cpuLimit": -1,
        "cpuReservationExpandable": true,
        "cpuSharesLevel": "normal",
        "cpuSharesValue": 0,
        "memoryReservationPercentage": 0,
        "memoryLimit": -1,
        "memoryReservationExpandable": true,
        "memorySharesLevel": "normal",
        "memorySharesValue": 0
    }, {
        "name": "vcf-m01-cl01-rp-user-edge",
        "type": "compute",
        "cpuReservationPercentage": 0,
        "cpuLimit": -1,
        "cpuReservationExpandable": true,
        "cpuSharesLevel": "normal",
        "cpuSharesValue": 0,
        "memoryReservationPercentage": 0,
        "memoryLimit": -1,
        "memoryReservationExpandable": true,
        "memorySharesLevel": "normal",
        "memorySharesValue": 0
    }, {
        "name": "vcf-m01-cl01-rp-user-vm",
        "type": "compute",
        "cpuReservationPercentage": 0,
        "cpuLimit": -1,
        "cpuReservationExpandable": true,
        "cpuSharesLevel": "normal",
        "cpuSharesValue": 0,
        "memoryReservationPercentage": 0,
        "memoryLimit": -1,
        "memoryReservationExpandable": true,
        "memorySharesLevel": "normal",
        "memorySharesValue": 0
        }]
    ,
    "pscSpecs": [
        {
        "pscId": "psc-1",
        "vcenterId": "vcenter-1",
        "adminUserSsoPassword": "$VCSASSOPassword",
        "pscSsoSpec": {
            "ssoDomain": "vsphere.local"
        }
        }
    ],
    "vcenterSpec": {
        "vcenterIp": "$VCSAIP",
        "vcenterHostname": "$VCSAName",
        "vcenterId": "vcenter-1",
        "licenseFile": "$VCSALicense",
        "vmSize": "tiny",
        "storageSize": "",
        "rootVcenterPassword": "$VCSARootPassword"
    },
    "hostSpecs": [
"@

        $vcfMiddleConfig = ""

        $count = 1
        $NestedESXiHostnameToIPs.GetEnumerator() | Sort-Object -Property Value | Foreach-Object {
            $VMName = $_.Key
            $VMIPAddress = $_.Value

            $vcfMiddleConfig += @"

    {
        "association": "vcf-m01-dc01",
        "ipAddressPrivate": {
            "ipAddress": "$VMIPAddress",
            "cidr": "$NestedESXiManagementNetworkCidr",
            "gateway": "$VMGateway"
        },
        "hostname": "$VMName",
        "credentials": {
            "username": "root",
            "password": "$VMPassword"
        },
        "sshThumbprint": "SHA256:DUMMY_VALUE",
        "sslThumbprint": "SHA25_DUMMY_VALUE",
        "vSwitch": "vSwitch0",
        "serverId": "host-$count"
    },
"@
    $count++
    }
    $vcfMiddleConfig = $vcfMiddleConfig.Substring(0,$vcfMiddleConfig.Length-1)

    $vcfEndConfig = @"

    ],
    "excludedComponents": ["NSX-V", "AVN", "EBGP"]
}
"@

    $vcfConfig = $vcfStartConfig1 + $vcfStartConfig2 + $vcfMiddleConfig + $vcfEndConfig

    My-Logger "Generating Cloud Builder VCF configuration deployment file vcf-config.json"
    $vcfConfig  | Out-File -LiteralPath vcf-config.json
}

$EndTime = Get-Date
$duration = [math]::Round((New-TimeSpan -Start $StartTime -End $EndTime).TotalMinutes,2)

My-Logger "VCF Lab Deployment Complete!"
My-Logger "StartTime: $StartTime"
My-Logger "  EndTime: $EndTime"
My-Logger " Duration: $duration minutes to Deploy Nested ESXi and Import CloudBuilder"