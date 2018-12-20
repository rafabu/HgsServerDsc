#Requires -Version 5.1
#Requires -Modules HgsDiagnostics, HgsServer

$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Certificate Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'HgsServerDsc.Common' `
            -ChildPath 'HgsServerDsc.Common.psm1'))

<#
    .SYNOPSIS
    Returns the current online state of a remote HGS cluster.

    .PARAMETER ClusterName
    The FQDN of the HGS Cluster on the local area network.
#>

function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [String]$ClusterName,

        [UInt64]$RetryIntervalSec = 60,

        [UInt32]$RetryCount = 10,

        [UInt32]$RebootRetryCount = 0

    )

    $hgsCluster = Test-HgsClusterHost -HgsHostFQDN $ClusterName

    Write-Verbose -Message ( @(
            'Test-HgsClusterHost -HgsHostFQDN {0}: ' -f $ClusterName
            '     is online: {0}' -f $hgsCluster
        ) -join '' )

    $returnValue = @{
        ClusterName = $ClusterName
        RetryIntervalSec = $RetryIntervalSec
        RetryCount = $RetryCount
        RebootRetryCount = $RebootRetryCount
    }

    $returnValue
}


function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [String]$ClusterName,

        [UInt64]$RetryIntervalSec = 60,

        [UInt32]$RetryCount = 10,

        [UInt32]$RebootRetryCount = 0

    )

    $rebootLogFile = "$env:temp\MSFT_HgsWaitForHgsCluster_Reboot.tmp"

    for($count = 0; $count -lt $RetryCount; $count++)
    {
        $hgsCluster = Test-HgsClusterHost -HgsHostFQDN ClusterName

        Write-Verbose -Message ( @(
            'Test-HgsClusterHost -HgsHostFQDN {0}: ' -f $ClusterName
            '     is online: {0}' -f $hgsCluster
        ) -join '' )

        if($hgsCluster)
        {
            if($RebootRetryCount -gt 0)
            {
                Remove-Item $rebootLogFile -ErrorAction SilentlyContinue
            }

            break;
        }
        else
        {
            Write-Verbose -Message "HGS Cluster $ClusterName not found. Will retry again after $RetryIntervalSec sec"
            Start-Sleep -Seconds $RetryIntervalSec
            Clear-DnsClientCache
        }
    }

    if(-not $hgsCluster)
    {
        if($RebootRetryCount -gt 0)
        {
            [UInt32]$rebootCount = Get-Content $RebootLogFile -ErrorAction SilentlyContinue

            if($rebootCount -lt $RebootRetryCount)
            {
                $rebootCount = $rebootCount + 1
                Write-Verbose -Message  "HGS Cluster $ClusterName not found after $count attempts with $RetryIntervalSec sec interval. Rebooting.  Reboot attempt number $rebootCount of $RebootRetryCount."
                Set-Content -Path $RebootLogFile -Value $rebootCount
                $global:DSCMachineStatus = 1
            }
            else
            {
                throw "HGS Cluster '$($ClusterName)' NOT found after $RebootRetryCount Reboot attempts."
            }


        }
        else
        {
            throw "HGS Cluster '$($ClusterName)' NOT found after $RetryCount attempts."
        }
    }
}

function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [String]$ClusterName,

        [UInt64]$RetryIntervalSec = 60,

        [UInt32]$RetryCount = 10,

        [UInt32]$RebootRetryCount = 0

    )

    $rebootLogFile = "$env:temp\xWaitForADDomain_Reboot.tmp"

    $hgsCluster = Test-HgsClusterHost -HgsHostFQDN ClusterName

    Write-Verbose -Message ( @(
        'Test-HgsClusterHost -HgsHostFQDN {0}: ' -f $ClusterName
        '     is online: {0}' -f $hgsCluster
    ) -join '' )

    if($hgsCluster)
    {
        if($RebootRetryCount -gt 0)
        {
            Remove-Item $rebootLogFile -ErrorAction SilentlyContinue
        }

        $true
    }
    else
    {
        $false
    }
}
