# vcf-automated-lab-deployment-esa-mock

## 🚀 Project Overview

This is a fork of William Lam's powerful [VCF Automated Lab Deployment](https://github.com/lamw/vcf-automated-lab-deployment) project, extended with full support for vSAN ESA using the Mock VIB. The primary goal is to enable fully automated deployment of a VCF Management Domain with vSAN ESA (Mock) in unsupported or non-standard environments — without relying on outdated JSON HCL tricks.

> 💡 Powered by William Lam's vSAN ESA Hardware Mock VIB: [Read more](https://williamlam.com/2025/02/vsan-esa-hardware-mock-vib-for-physical-esxi-deployment-for-vmware-cloud-foundation-vcf.html)

> 🔗 Visit William Lam’s website: [williamlam.com](https://williamlam.com)

> 📦 Original Repository: [github.com/lamw/vcf-automated-lab-deployment](https://github.com/lamw/vcf-automated-lab-deployment)

---

## 🙌 Tribute
I'm a huge fan of William Lam — his work around VMware and VCF automation has been an incredible source of knowledge and inspiration for many of us in the community. This project wouldn't exist without his innovative scripts, blog posts, and lab hacks.

---

## ⚙️ What's New In This Fork

### ✅ Native ESA Mock Support
- Seamless integration of `nested-vsan-esa-mock-hw.vib`
- Automatically sets Software Acceptance Level to `CommunitySupported`
- Uploads, installs, and restarts `vsanmgmtd` service — fully automated

### ✅ Customization Support
- New variable: `$MockFile` for defining custom mock file path

### ✅ Dynamic vcf-mgmt.json Update
When `$NestedESXiMGMTVSANESA = $true`, the following block is automatically added:
```json
"esaConfig": {
  "enabled": true
},
"hclFile": null
```

### ✅ Clean Automation
- No JSON HCL hacks
- No manual steps
- No ESA guesswork
- Just a working VCF Management Domain using vSAN ESA (Mock)

---

## 🧠 Lab Specs (Tested)
- **Server**: AMD EPYC 9454P 48-Core Processor
- **Memory**: 1TB RAM
- **Storage**: 2x 4TB Intel SSDPF2KX038T1
- **Hypervisor**: ESXi on bare metal
- **VCF Version**: 5.2.1

---

## 🎯 Purpose
To provide a fully automated solution for spinning up a VCF Management Domain with vSAN ESA (Mock). This lab is ideal for:
- Learning VCF internals
- Testing ESA in unsupported environments
- Rapid lab bring-ups for experimentation or validation

---

## 🔧 Key Variables
In your config:
```powershell
$NestedESXiMGMTVSANESA = $true
$MockFile = "/data/mock/nested-vsan-esa-mock-hw.vib"
```

---

## 🧪 Coming Soon
Automatic ESA Mock VIB deployment for **Workload Domains** — enabling full end-to-end automation, including ESA support without any manual intervention.

---

## 📬 Feedback & Contact
Feel free to reach out with suggestions, feedback, or issues. Always happy to collaborate and improve this project.

Connect with me on LinkedIn: [Stefan Gourguis](https://www.linkedin.com/in/stefan-gourguis-1ab6a570/)

---

## 📌 Hashtags
#VCF #Broadcom #VMware #vSAN #ESA #Automation #NestedLab #Homelab #WilliamLamInspired #vExpertStyle #RootServerEngineering #CloudFoundation
