<#
    .SYNOPSIS
    Diagnose HGS target remotely to see if it is available.

    .PARAMETER HgsHostFQDN
    The FQDN of the HGS Host or Cluster to test for availability.
#>
function Test-HgsClusterHost {
    [cmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter()]
        [System.String]
        $HgsHostFQDN
    )

    Write-Verbose `
        -Message ('Start Get-HgsTrace -target {0}' -f $HgsHostFQDN) `
        -Verbose

    $remoteResultSet = $null
    try {
        $remoteResultSet = Get-HgsTrace -Target $HgsHostFQDN -RunDiagnostics -Diagnostic 'HostGuardianService' -ErrorAction 'Stop'
    } catch {
        Write-Verbose `
            -Message ('Error Thrown on: Get-HgsTrace -target {0}' -f $HgsHostFQDN) `
            -Verbose
        return $false
    }

    if ($remoteResultSet.GetType().Name -eq 'RemoteResultSet') {
        Write-Verbose `
            -Message ('HGS {0} result is {1}' -f $HgsHostFQDN, $remoteResultSet.Result.Status) `
            -Verbose
        return $remoteResultSet.Result.Success
    }

    else {
        Write-Verbose `
            -Message ('no valid RemoteResultSet recieved from Get-HgsTrace -target {0}' -f $HgsHostFQDN) `
            -Verbose

        return $false
    }
} # end function Test-HgsClusterHost

