# Your Management vCenter Server that will be used to deploy the VMware Cloud Foundation Lab
$VIServer = "FILL_ME_IN"
$VIUsername = "FILL_ME_IN"
$VIPassword = "FILL_ME_IN"

# General Deployment Configuration for your Nested ESXi & Cloud Builder VM
$VMDatacenter = "Datacenter"
$VMCluster = "Cluster"
$VMNetwork = "Workloads"
$VMDatastore = "vsanDatastore"
$VMNetmask = "255.255.0.0"
$VMGateway = "172.16.1.53"
$VMDNS = "172.16.1.3"
$VMNTP = "172.16.1.53"
$VMPassword = "VMware1!"
$VMDomain = "vcf.lab"
$VMSyslog = "172.16.30.100"
$VMFolder = "wlam-vcf52"

# Full Path to both the Nested ESXi & Cloud Builder OVA
$NestedESXiApplianceOVA = "/data/images/Nested_ESXi8.0u3c_Appliance_Template_v1.ova"
$CloudBuilderOVA = "/data/images/VMware-Cloud-Builder-5.2.1.1-24397777_OVF10.ova"

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
$CloudbuilderFQDN = "vcf-m01-cb01.vcf.lab"
$CloudbuilderIP = "172.16.30.61"
$CloudbuilderAdminUsername = "admin"
$CloudbuilderAdminPassword = "VMware1!VMware1!"
$CloudbuilderRootPassword = "VMware1!VMware1!"

# SDDC Manager Configuration
$SddcManagerHostname = "vcf-m01-sddcm01"
$SddcManagerIP = "172.16.30.62"
$SddcManagerVcfPassword = "VMware1!VMware1!"
$SddcManagerRootPassword = "VMware1!VMware1!"
$SddcManagerRestPassword = "VMware1!VMware1!"
$SddcManagerLocalPassword = "VMware1!VMware1!"

# Nested ESXi VMs for Management Domain
$NestedESXiHostnameToIPsForManagementDomain = @{
    "vcf-m01-esx01"   = "172.16.30.63"
    "vcf-m01-esx02"   = "172.16.30.64"
    "vcf-m01-esx03"   = "172.16.30.65"
    "vcf-m01-esx04"   = "172.16.30.66"
}

# Nested ESXi VMs for Workload Domain
$NestedESXiHostnameToIPsForWorkloadDomain = @{
    "vcf-w01-esx01"   = "172.16.30.72"
    "vcf-w01-esx02"   = "172.16.30.73"
    "vcf-w01-esx03"   = "172.16.30.74"
    "vcf-w01-esx04"   = "172.16.30.75"
}

# Nested ESXi VM Resources for Management Domain
$NestedESXiMGMTvCPU = "12"
$NestedESXiMGMTvMEM = "96" #GB
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
$NestedESXiManagementNetworkCidr = "172.16.0.0/16" # should match $VMNetwork configuration
$NestedESXivMotionNetworkCidr = "172.30.32.0/24"
$NestedESXivSANNetworkCidr = "172.30.33.0/24"
$NestedESXiNSXTepNetworkCidr = "172.30.34.0/24"

# vCenter Configuration
$VCSAName = "vcf-m01-vc01"
$VCSAIP = "172.16.30.67"
$VCSARootPassword = "VMware1!"
$VCSASSOPassword = "VMware1!"
$EnableVCLM = $true

# NSX Configuration
$NSXManagerSize = "medium"
$NSXManagerVIPHostname = "vcf-m01-nsx01"
$NSXManagerVIPIP = "172.16.30.68"
$NSXManagerNode1Hostname = "vcf-m01-nsx01a"
$NSXManagerNode1IP = "172.16.30.69"
$NSXRootPassword = "VMware1!VMware1!"
$NSXAdminPassword = "VMware1!VMware1!"
$NSXAuditPassword = "VMware1!VMware1!"