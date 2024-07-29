# Author: William Lam
# Website: www.williamlam.com

$sddcManagerFQDN = "FILL_ME_IN"
$sddcManagerUsername = "FILL_ME_IN"
$sddcManagerPassword = "FILL_ME_IN"

# License Later feature only applicable for VCF 5.1.1 and later
$LicenseLater = $true
$ESXILicense = ""
$VSANLicense = ""
$NSXLicense = ""

# Management Domain Configurations
$VCFManagementDomainPoolName = "vcf-m01-rp01"

# Workload Domain Configurations
$VCFWorkloadDomainAPIJSONFile = "vcf-commission-host-api.json"
$VCFWorkloadDomainName = "wld-w01"
$VCFWorkloadDomainOrgName = "vcf-w01"
$EnableVCLM = $true
$VLCMImageName = "Management-Domain-ESXi-Personality" # Ensure this label matches in SDDC Manager->Lifecycle Management->Image Management
$EnableVSANESA = $false

# vCenter Configuration
$VCSAHostname = "vcf-w01-vc01"
$VCSAIP = "172.17.31.120"
$VCSARootPassword = "VMware1!"

# NSX Configuration
$NSXManagerVIPHostname = "vcf-w01-nsx01"
$NSXManagerVIPIP = "172.17.31.121"
$NSXManagerNode1Hostname = "vcf-m01-nsx01a"
$NSXManagerNode1IP = "172.17.31.122"
$NSXManagerNode2Hostname = "vcf-m01-nsx01b"
$NSXManagerNode2IP = "172.17.31.123"
$NSXManagerNode3Hostname = "vcf-m01-nsx01c"
$NSXManagerNode3IP = "172.17.31.124"
$NSXAdminPassword = "VMware1!VMware1!"
$SeparateNSXSwitch = $false

$VMNetmask = "255.255.255.0"
$VMGateway = "172.17.31.1"
$VMDomain = "tshirts.inc"

#### DO NOT EDIT BEYOND HERE ####

$confirmDeployment = 1
$commissionHost = 1
$generateWLDDeploymentFile = 1
$startWLDDeployment = 1

$verboseLogFile = "vcf-workload-domain-deployment.log"
$VCFWorkloadDomainDeploymentJSONFile = "${VCFWorkloadDomainName}.json"

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

if(-Not (Get-InstalledModule -Name PowerVCF)) {
    My-Logger "PowerVCF module was not detected, please install by running: Install-Module PowerVCF"
    exit
}

if(!(Test-Path $VCFWorkloadDomainAPIJSONFile)) {
    Write-Host -ForegroundColor Red "`nUnable to find $VCFWorkloadDomainAPIJSONFile ...`n"
    exit
}

if($confirmDeployment -eq 1) {
    Write-Host -ForegroundColor Magenta "`nPlease confirm the following configuration will be deployed:`n"

    Write-Host -ForegroundColor Yellow "---- VCF Automated Workload Domain Deployment Configuration ---- "
    Write-Host -NoNewline -ForegroundColor Green "Workload Domain Name: "
    Write-Host -ForegroundColor White $VCFWorkloadDomainName
    Write-Host -NoNewline -ForegroundColor Green "Workload Domain Org Name: "
    Write-Host -ForegroundColor White $VCFWorkloadDomainOrgName
    Write-Host -NoNewline -ForegroundColor Green "Workload Domain Host Comission File: "
    Write-Host -ForegroundColor White $VCFWorkloadDomainAPIJSONFile

    Write-Host -ForegroundColor Yellow "`n---- Target SDDC Manager Configuration ---- "
    Write-Host -NoNewline -ForegroundColor Green "SDDC Manager Hostname: "
    Write-Host -ForegroundColor White $sddcManagerFQDN

    Write-Host -ForegroundColor Yellow "`n---- Workload Domain vCenter Server Configuration ----"
    Write-Host -NoNewline -ForegroundColor Green "vCenter Server Hostname: "
    Write-Host -ForegroundColor White "${VCSAHostname}.${VMDomain} (${VCSAIP})"

    Write-Host -ForegroundColor Yellow "`n---- Workload Domain NSX Server Configuration ----"
    Write-Host -NoNewline -ForegroundColor Green "NSX Manager VIP Hostname: "
    Write-Host -ForegroundColor White $NSXManagerVIPHostname"."$VMDomain
    Write-Host -NoNewline -ForegroundColor Green "NSX Manager VIP IP Address: "
    Write-Host -ForegroundColor White $NSXManagerVIPIP
    Write-Host -NoNewline -ForegroundColor Green "Node 1: "
    Write-Host -ForegroundColor White "${NSXManagerNode1Hostname}.${VMDomain} ($NSXManagerNode1IP)"
    Write-Host -NoNewline -ForegroundColor Green "Node 2: "
    Write-Host -ForegroundColor White "${NSXManagerNode2Hostname}.${VMDomain} ($NSXManagerNode2IP)"
    Write-Host -NoNewline -ForegroundColor Green "Node 3: "
    Write-Host -ForegroundColor White "${NSXManagerNode3Hostname}.${VMDomain} ($NSXManagerNode3IP)"

    Write-Host -ForegroundColor Magenta "`nWould you like to proceed with this deployment?`n"
    $answer = Read-Host -Prompt "Do you accept (Y or N)"
    if($answer -ne "Y" -or $answer -ne "y") {
        exit
    }
    Clear-Host
}

My-Logger "Logging into SDDC Manager ..."
Request-VCFToken -fqdn $sddcManagerFQDN -username $sddcManagerUsername -password $sddcManagerPassword | Out-Null

if($commissionHost -eq 1) {
    My-Logger "Retreiving VCF Management Domain $VCFManagementDomainPoolName PoolId ..."
    $mgmtPoolId = (Get-VCFNetworkPool $VCFManagementDomainPoolName).id

    My-Logger "Updating $VCFWorkloadDomainAPIJSONFile with PoolId value ..."
    $hostCommissionFile = (Get-Content -Raw $VCFWorkloadDomainAPIJSONFile | ConvertFrom-Json)

    foreach ($line in $hostCommissionFile) {
        $line.networkPoolId = $mgmtPoolId

        if($EnableVSANESA) {
            $line.storageType = "VSAN_ESA"
        }
    }
    $hostCommissionFile | ConvertTo-Json | Out-File -Force $VCFWorkloadDomainAPIJSONFile

    My-Logger "Validating ESXi host commission file $VCFWorkloadDomainAPIJSONFile ..."
    $commissionHostValidationResult = New-VCFCommissionedHost -json (Get-Content -Raw $VCFWorkloadDomainAPIJSONFile) -Validate

    if($commissionHostValidationResult.resultStatus) {
        $commissionHostResult = New-VCFCommissionedHost -json (Get-Content -Raw $VCFWorkloadDomainAPIJSONFile)
    } else {
        Write-Error "Validation of host commission file $VCFWorkloadDomainAPIJSONFile failed"
        break
    }

    My-Logger "Comissioning new ESXi hosts for Workload Domain deployment using $VCFWorkloadDomainAPIJSONFile ..."
    while( (Get-VCFTask ${commissionHostResult}.id).status -ne "Successful" ) {
        My-Logger "Host commission has not completed, sleeping for 30 seconds"
        Start-Sleep -Second 30
    }
}

if($generateWLDDeploymentFile -eq 1) {
    My-Logger "Retreiving unassigned ESXi hosts from SDDC Manager and creating Workload Domain JSON deployment file $VCFWorkloadDomainDeploymentJSONFile"
    $hostSpecs = @()
    foreach ($id in (Get-VCFhost -Status UNASSIGNED_USEABLE).id) {
        if($SeparateNSXSwitch) {
            $vmNics = @(
                @{
                    "id" = "vmnic0"
                    "vdsName" = "wld-w01-cl01-vds01"
                }
                @{
                    "id" = "vmnic1"
                    "vdsName" = "wld-w01-cl01-vds01"
                }
                @{
                    "id" = "vmnic2"
                    "vdsName" = "wld-w01-cl01-vds02"
                }
                @{
                    "id" = "vmnic3"
                    "vdsName" = "wld-w01-cl01-vds02"
                }
            )
        } else {
                $vmNics = @(
                @{
                    "id" = "vmnic0"
                    "vdsName" = "wld-w01-cl01-vds01"
                }
                @{
                    "id" = "vmnic1"
                    "vdsName" = "wld-w01-cl01-vds01"
                }
            )
        }

        $tmp = [ordered] @{
            "id" = $id
            "licenseKey" = $ESXILicense
            "hostNetworkSpec" = @{
                "vmNics" = $vmNics
            }
        }
        $hostSpecs += $tmp
    }

    $payload = [ordered] @{
        "domainName" = $VCFWorkloadDomainName
        "orgName" = $VCFWorkloadDomainOrgName
        "vcenterSpec" = @{
            "name" = "wld-vc-w01"
            "networkDetailsSpec" = @{
                "ipAddress" = $VCSAIP
                "dnsName" = $VCSAHostname + "." + $VMDomain
                "gateway" = $VMGateway
                "subnetMask" = $VMNetmask
            }
            "rootPassword" = $VCSARootPassword
            "datacenterName" = "wld-w01-dc01"
        }
        "computeSpec" = [ordered] @{
            "clusterSpecs" = @(
                [ordered] @{
                    "name" = "wld-w01-cl01"
                    "hostSpecs" = $hostSpecs
                    "datastoreSpec" = @{
                        "vsanDatastoreSpec" = @{
                            "failuresToTolerate" = "1"
                            "licenseKey" = $VSANLicense
                            "datastoreName" = "wld-w01-cl01-vsan01"
                        }
                    }
                    "networkSpec" = @{
                        "vdsSpecs" = @(
                            [ordered] @{
                                "name" = "wld-w01-cl01-vds01"
                                "portGroupSpecs" = @(
                                    @{
                                        "name" = "wld-w01-cl01-vds01-management"
                                        "transportType" = "MANAGEMENT"
                                    }
                                    @{
                                        "name" = "wld-w01-cl01-vds01-vmotion"
                                        "transportType" = "VMOTION"
                                    }
                                    @{
                                        "name" = "wld-w01-cl01-vds01-vsan"
                                        "transportType" = "VSAN"
                                    }
                                )
                            }
                        )
                        "nsxClusterSpec" = [ordered] @{
                            "nsxTClusterSpec" = @{
                                "geneveVlanId" = 2005
                                "ipAddressPoolSpec" = @{
                                    "name" = "wld-pool"
                                    "subnets" = @(
                                        [ordered] @{
                                            "cidr" = "10.0.5.0/24"
                                            "gateway" = "10.0.5.253"
                                            "ipAddressPoolRanges" = @(
                                                [ordered] @{
                                                    "start" = "10.0.5.1"
                                                    "end" = "10.0.5.128"
                                                }
                                            )
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
            )
        }
        "nsxTSpec" = [ordered] @{
            "nsxManagerSpecs" = @(
                [ordered] @{
                    "name" = $NSXManagerNode1Hostname
                    "networkDetailsSpec" = @{
                        "ipAddress" = $NSXManagerNode1IP
                        "dnsName" = $NSXManagerNode1Hostname + "." + $VMDomain
                        "gateway" = $VMGateway
                        "subnetMask" = $VMNetmask
                    }
                }
                [ordered] @{
                    "name" = $NSXManagerNode2Hostname
                    "networkDetailsSpec" = @{
                        "ipAddress" = $NSXManagerNode2IP
                        "dnsName" = $NSXManagerNode2Hostname + "." + $VMDomain
                        "gateway" = $VMGateway
                        "subnetMask" = $VMNetmask
                    }
                }
                [ordered] @{
                    "name" = $NSXManagerNode3Hostname
                    "networkDetailsSpec" = @{
                        "ipAddress" = $NSXManagerNode3IP
                        "dnsName" = $NSXManagerNode3Hostname + "." + $VMDomain
                        "gateway" = $VMGateway
                        "subnetMask" = $VMNetmask
                    }
                }
            )
            "vip" = $NSXManagerVIPIP
            "vipFqdn" = $NSXManagerVIPHostname + "." + $VMDomain
            "licenseKey" = $NSXLicense
            "nsxManagerAdminPassword" = $NSXAdminPassword
        }
    }

    if($SeparateNSXSwitch) {
        $payload.computeSpec.clusterSpecs.networkSpec.vdsSpecs+=@{"name"="wld-w01-cl01-vds02";"isUsedByNsxt"=$true}
    }

    if($LicenseLater) {
        if($ESXILicense -eq "" -and $VSANLicense -eq "" -and $NSXLicense -eq "") {
            $EvaluationMode = $true
        } else {
            $EvaluationMode = $false
        }
        $payload.add("deployWithoutLicenseKeys",$EvaluationMode)
    }

    if($EnableVSANESA) {
        $esaEnable = [ordered]@{
            "enabled" = $true
        }
        $payload.computeSpec.clusterSpecs.datastoreSpec.vsanDatastoreSpec.Add("esaConfig",$esaEnable)

        $payload.computeSpec.clusterSpecs.datastoreSpec.vsanDatastoreSpec.Remove("failuresToTolerate")
    }

    if($EnableVCLM) {
        $clusterImageId = (Get-VCFPersonality | where {$_.personalityName -eq $VLCMImageName}).personalityId

        if($clusterImageId -eq $null) {
            Write-Host -ForegroundColor Red "`nUnable to find vLCM Image named $VLCMImageName ...`n"
            exit
        }

        $payload.computeSpec.clusterSpecs.Add("clusterImageId",$clusterImageId)
    }

    $payload | ConvertTo-Json -Depth 12 | Out-File $VCFWorkloadDomainDeploymentJSONFile
}

if($startWLDDeployment -eq 1) {
    My-Logger "Starting Workload Domain deployment using file $VCFWorkloadDomainDeploymentJSONFile"
    $wldDeployment = New-VCFWorkloadDomain -json $VCFWorkloadDomainDeploymentJSONFile

    My-Logger "Open a browser to your SDDC Manager to monitor the deployment progress"
}

$EndTime = Get-Date
$duration = [math]::Round((New-TimeSpan -Start $StartTime -End $EndTime).TotalMinutes,2)

My-Logger "VCF Workload Domain Deployment Complete!"
My-Logger "StartTime: $StartTime"
My-Logger "EndTime: $EndTime"
My-Logger "Duration: $duration minutes to initiate Workload Domain deployment"