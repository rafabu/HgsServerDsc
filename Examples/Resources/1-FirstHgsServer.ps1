$HgsDomainCredential = New-Object System.Management.Automation.PSCredential ("hgs\MyNiceAdmin", (ConvertTo-SecureString "8erBahn!" -AsPlainText -Force))
$SafeModeAdministratorPassword = New-Object System.Management.Automation.PSCredential ("notUsed", (ConvertTo-SecureString "11erRaus!" -AsPlainText -Force))

$HgsDomainName = "hgs.lab01.rabuzu.cloud"
$HgsServerIPAddress = "l01h-hgs-001.hgs.lab01.rabuzu.cloud"


configuration TestHGSInstall
    {

    Import-DscResource -ModuleName HgsServerDsc
    IMport-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName PSDscResources


        Node $ConfigurationData.AllNodes.where{$_.Role -imatch 'HGS'}.NodeName
        {
            WindowsFeature HostGuardianServiceRole {
                Name   = "HostGuardianServiceRole"
                IncludeAllSubFeature = $true
            }
            WindowsFeature RSAT-AD-PowerShell {
                Name   = "RSAT-AD-PowerShell"
                IncludeAllSubFeature = $true
            }

            WindowsFeature RSAT-Clustering-PowerShell {
                Name   = "RSAT-Clustering-PowerShell"
                IncludeAllSubFeature = $true
            }
        }

        Node $ConfigurationData.AllNodes.where{$_.Role -imatch 'primary-hgs'}.NodeName
        {
            HgsServerInstall PrimaryMember {
                HgsDomainName = $HgsDomainName
                SafeModeAdministratorPassword = $SafeModeAdministratorPassword
	            Reboot = $false
                DependsOn = "[WindowsFeature]HostGuardianServiceRole"
           }
        }

        Node $ConfigurationData.AllNodes.where{$_.Role -imatch 'secondary-hgs'}.NodeName
        {
            xWaitForADDomain WaitForPrimary {
            DomainName = $HgsDomainName
            DependsOn = "[WindowsFeature]HostGuardianServiceRole"
            }

            HgsServerInstall SecondaryMember {
                HgsDomainName = $HgsDomainName
                HgsDomainCredential = $HgsDomainCredential
	            HgsServerIPAddress = $HgsServerIPAddress
	            SafeModeAdministratorPassword = $SafeModeAdministratorPassword
	            Reboot = $false
                DependsOn = "[xWaitForADDomain]WaitForPrimary"
           }
        }
    }


$configData = @{
        AllNodes = @(
            @{
                NodeName                = "l01h-hgs-001"
                Role                    = @("hgs", "primary-hgs")
                OSImageReference = @{
                    publisher = "MicrosoftWindowsServer"
                    offer     = "WindowsServer"
                    sku       = "2019-Datacenter-Core"
                    version   = "latest"
                }
                #CMS-Encryption
                CertificateFile = "D:\Users\raphael.burri\Source\Repos\LAB01-AAD\l01h-rds-001_DSCEncryption.cer"
                PSDscAllowDomainUser = $true
            },
            @{
                NodeName                = "l01h-hgs-004"
                Role                    = @("hgs", "secondary-hgs")
                OSImageReference = @{
                    publisher = "MicrosoftWindowsServer"
                    offer     = "WindowsServer"
                    sku       = "2019-Datacenter-Core"
                    version   = "latest"
                }
                #CMS-Encryption
                CertificateFile = "D:\Users\raphael.burri\Source\Repos\LAB01-AAD\l01h-rds-001_DSCEncryption.cer"
                PSDscAllowDomainUser = $true
            }
        )
}
# Compile the configuration file to a MOF format
TestHGSInstall -ConfigurationData $configData

# Run the configuration on localhost
#Start-DscConfiguration -Path .\TestHGSInstall -Wait -Force -Verbose
