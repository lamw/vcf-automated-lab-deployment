$sddcManagerFQDN = "FILL_ME_IN"
$sddcManagerUsername = "administrator@vsphere.local"
$sddcManagerPassword = "VMware1!"

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
$VCSAIP = "172.16.30.76"
$VCSARootPassword = "VMware1!VMware1!"

# NSX Configuration
$NSXManagerVIPHostname = "vcf-w01-nsx01"
$NSXManagerVIPIP = "172.16.30.77"
$NSXManagerNode1Hostname = "vcf-w01-nsx01a"
$NSXManagerNode1IP = "172.16.30.78"
$NSXManagerNode2Hostname = "vcf-w01-nsx01b"
$NSXManagerNode2IP = "172.16.30.79"
$NSXManagerNode3Hostname = "vcf-w01-nsx01c"
$NSXManagerNode3IP = "172.16.30.80"
$NSXAdminPassword = "VMware1!VMware1!"
$SeparateNSXSwitch = $false

$VMNetmask = "255.255.0.0"
$VMGateway = "172.16.1.53"
$VMDomain = "vcf.lcm"