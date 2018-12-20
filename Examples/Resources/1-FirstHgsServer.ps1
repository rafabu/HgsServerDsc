$HgsDomainCredential = New-Object System.Management.Automation.PSCredential ("hgs\MyNiceAdmin", (ConvertTo-SecureString "8erBahn!" -AsPlainText -Force))
$SafeModeAdministratorPassword = New-Object System.Management.Automation.PSCredential ("notUsed", (ConvertTo-SecureString "11erRaus!" -AsPlainText -Force))

$HgsDomainName = "hgs.lab01.rabuzu.cloud"
$HgsServerIPAddress = "l01h-hgs-001.hgs.lab01.rabuzu.cloud"


configuration TestHGSInstall
    {

    Import-DscResource -ModuleName HgsServerDsc
    Import-DscResource -ModuleName PSDscResources

        Node "localhost"
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

            HgsServerInstall SecondaryMember {
                HgsDomainName = $HgsDomainName
                HgsDomainCredential = $HgsDomainCredential
	            HgsServerIPAddress = $HgsServerIPAddress
	            SafeModeAdministratorPassword = $SafeModeAdministratorPassword
	            Reboot = $false
                DependsOn = "[WindowsFeature]HostGuardianServiceRole"
           }

        }
    }


$configData = @{
        AllNodes = @(
            @{
                NodeName = 'localhost'
                PSDscAllowPlainTextPassword = $true
            }
        )
}
# Compile the configuration file to a MOF format
TestHGSInstall -ConfigurationData $configData

# Run the configuration on localhost
#Start-DscConfiguration -Path .\TestHGSInstall -Wait -Force -Verbose
