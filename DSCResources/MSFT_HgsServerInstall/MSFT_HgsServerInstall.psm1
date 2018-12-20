#Requires -Version 5.1
#Requires -Modules HgsDiagnostics, HgsServer

$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Certificate Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'HgsServerDsc.Common' `
            -ChildPath 'HgsServerDsc.Common.psm1'))

<#
    .SYNOPSIS
    Installs HGS on a local node.

    .PARAMETER HgsDomainName
    The FQDN of the HGS Domain to create or join.

    .PARAMETER HgsDomainCredential
    HGS Domain Admin Credentials used to join the domain.

    .PARAMETER SafeModeAdministratorPassword
    DSRM password of the this node.

    .PARAMETER Reboot
    Boolean to force reboot.
#>

#[Microsoft.Windows.HostGuardianService.PowerShell.InstallationState]
#   Initialized
#   NotInitialized
#   RoleInstalledButMissingDependencies
#   RoleNotInstalled
#
#[Microsoft.Windows.HostGuardianService.Powershell.DomainRole]
#   DomainController
#   NotDomainJoined
#   DomainMember

function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [String]$HgsDomainName,

        [System.Management.Automation.PSCredential]$HgsDomainCredential,

        [String]$HgsServerIPAddress = "",

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$SafeModeAdministratorPassword,

        [bool]$Reboot = $false

    )

    $returnValue = @{
        HgsDomainName = $HgsDomainName
        HgsServerIPAddress = $HgsServerIPAddress
        Reboot = $Reboot}

    $returnValue
}

function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [String]$HgsDomainName,

        [System.Management.Automation.PSCredential]$HgsDomainCredential,

        [String]$HgsServerIPAddress = "",

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$SafeModeAdministratorPassword,

        [bool]$Reboot = $false

    )

    $TestReport = $null
    try {
        if ($null -eq $HgsDomainCredential) {
            $TestReport = Test-HgsServer -HgsDomainName $HgsDomainName -SafeModeAdministratorPassword $SafeModeAdministratorPassword.Password
        }
        elseif ($HgsServerIPAddress.Length -gt 0) {
            $TestReport = Test-HgsServer -HgsDomainName $HgsDomainName -HgsServerIPAddress $HgsServerIPAddress -HgsDomainCredential $HgsDomainCredential -SafeModeAdministratorPassword $SafeModeAdministratorPassword.Password
        }
        else {
            Write-Verbose `
                -Message ('in order to join the existing HGS domain {0}, specify both HgsDomainCredential and HgsServerIPAddress' -f $HgsDomainName) `
                -Verbose
                throw "unable to join HGS domain $HgsDomainName because either HgsDomainCredential and/or HgsServerIPAddress were not provided "
        }
    }
    catch {
    Write-Verbose `
        -Message ('Error Thrown on: Test-HgsServer -HgsDomainName {0}' -f $HgsDomainName) `
        -Verbose
        throw "unable to successfully run Test-HgsServer -HgsDomainName $HgsDomainName"
    }

    if ($TestReport.GetType().Name -eq 'TestReport') {
        Write-Verbose `
            -Message ('Test-Server result for domain {0} is HgsServerState: {1} / DomainRole {2}' -f $HgsDomainName, $TestReport.HgsServerState, $TestReport.DomainRole) `
            -Verbose
        if ("Initialized" -ne $TestReport.HgsServerState -and "DomainController" -ne $TestReport.DomainRole -and $TestReport.ADTest.Result -eq "Passed") {
            if ($null -eq $HgsDomainCredential) {
                if ($true -eq $reboot) {
                    Install-HgsServer -HgsDomainName $HgsDomainName -SafeModeAdministratorPassword $SafeModeAdministratorPassword.Password -Restart
                    Write-Verbose -Message  "HGS Server was installed with a freshly created domain $HgsDomainName - rebooting automatically"
                }
                else {
                    Install-HgsServer -HgsDomainName $HgsDomainName -SafeModeAdministratorPassword $SafeModeAdministratorPassword.Password
                    Write-Verbose -Message  "HGS Server was installed with a freshly created domain $HgsDomainName - now requesting a reboot."
                    $global:DSCMachineStatus = 1
                }
            }
            else {
                if ($true -eq $reboot) {
                    Install-HgsServer -HgsDomainName $HgsDomainName -HgsDomainCredential $HgsDomainCredential -SafeModeAdministratorPassword $SafeModeAdministratorPassword.Password -Restart
                    Write-Verbose -Message  "HGS Server was installed and joined to domain $HgsDomainName - rebooting automatically."
                }
                else {
                    Install-HgsServer -HgsDomainName $HgsDomainName -HgsDomainCredential $HgsDomainCredential -SafeModeAdministratorPassword $SafeModeAdministratorPassword.Password
                    Write-Verbose -Message  "HGS Server was installed and joined to domain $HgsDomainName - now requesting a reboot."
                    $global:DSCMachineStatus = 1
                }
            }
        }
        else {
            Write-Verbose -Message  "HGS Server is already installed - no action reqquired"
        }
    }
    else {
        Write-Verbose `
            -Message ('No TestReport returned from: Test-HgsServer -HgsDomainName {0}' -f $HgsDomainName) `
            -Verbose
            throw "no TestReport was returned by Test-HgsServer -HgsDomainName $HgsDomainName"
    }
}

function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [String]$HgsDomainName,

        [System.Management.Automation.PSCredential]$HgsDomainCredential,

        [String]$HgsServerIPAddress = "",

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$SafeModeAdministratorPassword,

        [bool]$Reboot = $false

    )

    try{
        $hgsServer = Get-HgsServer | Out-Null
    }
    catch {
        $hgsServer = $null
    }
    if ($null -eq $hgsServer) {
        try {
            $TestReport = Test-HgsServer -HgsDomainName $HgsDomainName -SafeModeAdministratorPassword $SafeModeAdministratorPassword.Password
        }
        catch {
            Write-Verbose `
                -Message ('Error Thrown on: Test-HgsServer -HgsDomainName {0}' -f $HgsDomainName) `
                -Verbose
                throw "unable to successfully run Test-HgsServer -HgsDomainName $HgsDomainName"
        }
        if ($TestReport.GetType().Name -eq 'TestReport') {
            Write-Verbose `
                -Message ('Test-Server result for domain {0} is HgsServerState: {1} / DomainRole {2}' -f $HgsDomainName, $TestReport.HgsServerState, $TestReport.DomainRole) `
                -Verbose
            if ($TestReport.HgsServerState -imatch ".*Initialized" -and $TestReport.DomainRole -eq "DomainController") {
                $true
            }
            else {
                $false
            }
        }
        else {
            Write-Verbose `
                -Message ('No TestReport returned from: Test-HgsServer -HgsDomainName {0}' -f $HgsDomainName) `
                -Verbose
                throw "no TestReport was returned by Test-HgsServer -HgsDomainName $HgsDomainName"
        }
    }
    else {
        $true
    }
}
