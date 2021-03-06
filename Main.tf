/*
This Template aimed to provide a basic IaaS deployment Using Terraform Module
All Network Compute and storage are available in the form of module
*/
######################################################################
# Access to Azure
######################################################################


# Configure the Microsoft Azure Provider with Azure provider variable defined in AzureDFProvider.tf

provider "azurerm" {

    subscription_id = "${var.AzureSubscriptionID}"
    client_id       = "${var.AzureClientID}"
    client_secret   = "${var.AzureClientSecret}"
    tenant_id       = "${var.AzureTenantID}"
}


######################################################################
# Foundations resources, including ResourceGroup and vNET
######################################################################

# Creating the ResourceGroup


module "ResourceGroup" {

    #Module Location
    #source = "./Modules/ResourceGroup"
    source = "github.com/dfrappart/Terra-AZModuletest//Modules//ResourceGroup/"
    #Module variable
    RGName                  = "${var.RSGName}"
    RGLocation              = "${var.AzureRegion}"
    EnvironmentTag          = "${var.EnvironmentTag}"
    EnvironmentUsageTag     = "${var.EnvironmentUsageTag}"
}

# Creating vNET

module "vNet" {

    #Module location
    #source = "./Modules/vNet"
    source = "github.com/dfrappart/Terra-AZModuletest//Modules//vNet/"

    #Module variable
    vNetName                = "TestModule-vNet"
    RGName                  = "${module.ResourceGroup.Name}"
    vNetLocation            = "${var.AzureRegion}"
    vNetAddrespace          = "${var.vNetIPRange}"
    EnvironmentTag          = "${var.EnvironmentTag}"
    EnvironmentUsageTag     = "${var.EnvironmentUsageTag}"


}

module "NSGWin" {

    #Module location
    #source = "./Modules/NSG"
    source = "github.com/dfrappart/Terra-AZModuletest//Modules//NSG/"

    #Module variable
    NSGName                 = "NSGWin"
    RGName                  = "${module.ResourceGroup.Name}"
    NSGLocation             = "${var.AzureRegion}"
    EnvironmentTag          = "${var.EnvironmentTag}"
    EnvironmentUsageTag     = "${var.EnvironmentUsageTag}"


}

module "SubnetWin" {

    #Module location
    #source = "./Modules/Subnet"
    source = "github.com/dfrappart/Terra-AZModuletest//Modules//Subnet/"

    #Module variable
    SubnetName                  = "SubnetWin"
    RGName                      = "${module.ResourceGroup.Name}"
    vNetName                    = "${module.vNet.Name}"
    Subnetaddressprefix         = "${lookup(var.SubnetAddressRange, 0)}"
    NSGid                       = "${module.NSGWin.Id}"
    EnvironmentTag              = "${var.EnvironmentTag}"
    EnvironmentUsageTag         = "${var.EnvironmentUsageTag}"

}

module "NSGRule-NSGWin-AllowRDP" {

    #Module location
    #source = "./Modules/NSGRule"
    source = "github.com/dfrappart/Terra-AZModuletest//Modules//NSGRule/"

    #Module variable
    RGName                              = "${module.ResourceGroup.Name}"
    NSGReference                        = "${module.NSGWin.Name}"
    NSGRuleName                         = "NSGRule-NSGWin-AllowRDP"
    NSGRulePriority                     = "1001"
    NSGRuleDirection                    = "inbound"
    NSGRuleProtocol                     = "tcp"
    NSGRuleSourcePortRange              = "*"
    NSGRuleDestinationPortRange         = "3389"
    NSGRuleSourceAddressPrefix          = "*"
    NSGRuleDestinationAddressPrefix     = "${module.SubnetWin.AddressPrefix}"
}

module "NSGLinux" {

    #Module location
    #source = "./Modules/NSG"
    source = "github.com/dfrappart/Terra-AZModuletest//Modules//NSG/"

    #Module variable
    NSGName                 = "NSGLinux"
    RGName                  = "${module.ResourceGroup.Name}"
    NSGLocation             = "${module.ResourceGroup.Location}"
    EnvironmentTag          = "${var.EnvironmentTag}"
    EnvironmentUsageTag     = "${var.EnvironmentUsageTag}"


}

module "SubnetLinux" {

    #Module location
    #source = "./Modules/Subnet"
    source = "github.com/dfrappart/Terra-AZModuletest//Modules//Subnet/"

    #Module variable
    SubnetName                  = "SubnetLinux"
    RGName                      = "${module.ResourceGroup.Name}"
    vNetName                    = "${module.vNet.Name}"
    Subnetaddressprefix         = "${lookup(var.SubnetAddressRange, 1)}"
    NSGid                       = "${module.NSGLinux.Id}"
    EnvironmentTag              = "${var.EnvironmentTag}"
    EnvironmentUsageTag         = "${var.EnvironmentUsageTag}"

}

module "NSGRule-NSGLinux-AllowSSH" {

    #Module location
    #source = "./Modules/NSGRule"
    source = "github.com/dfrappart/Terra-AZModuletest//Modules//NSGRule/"

    #Module variable
    RGName                              = "${module.ResourceGroup.Name}"
    NSGReference                        = "${module.NSGLinux.Name}"
    NSGRuleName                         = "NSGRule-NSGLinux-AllowSSH"
    NSGRulePriority                     = "1001"
    NSGRuleDirection                    = "inbound"
    NSGRuleProtocol                     = "tcp"
    NSGRuleSourcePortRange              = "*"
    NSGRuleDestinationPortRange         = "22"
    NSGRuleSourceAddressPrefix          = "*"
    NSGRuleDestinationAddressPrefix     = "${module.SubnetLinux.AddressPrefix}"
}



module "LinuxVMAS" {

    #module location
    #source = "./Modules/AvailabilitySet"
    source = "github.com/dfrappart/Terra-AZModuletest//Modules//AvailabilitySet/"

    #Module variable
    ASName                      = "LinuxVMAS"
    ASLocation                  = "${var.AzureRegion}"
    RGName                      = "${module.ResourceGroup.Name}"
    EnvironmentTag              = "${var.EnvironmentTag}"
    EnvironmentUsageTag         = "${var.EnvironmentUsageTag}"
}



module "LinuxVMs" {

    #Module location
    #source = "./Modules/CentOSVM"
    source = "github.com/dfrappart/Terra-AZModuletest//Modules//CentOSVM/"

    #Module variables
    CentOSVMName            = "LinuxVM"
    CentOSVMcount           = 2
    CentOSVMLocation        = "${var.AzureRegion}"
    CentOSVMRG              = "${module.ResourceGroup.Name}"
    CentOSVMSize            = "${lookup(var.VMSize, 4)}"
    CentOSVMAdminPassword   = "${var.VMAdminPassword}"
    CentOSVMS-ASID          = "${module.LinuxVMAS.Id}"
    CentOSVMStorageTier     = "${lookup(var.Manageddiskstoragetier, 0)}"
    CentOSSSHKey            = "${var.AzurePublicSSHKey}"
    CentOSDataDiskSize     = "127"
    TargetSubnetId          = "${module.SubnetLinux.Id}"
    #PublicIPID              = "${module.PublicIP.Id}"
}









