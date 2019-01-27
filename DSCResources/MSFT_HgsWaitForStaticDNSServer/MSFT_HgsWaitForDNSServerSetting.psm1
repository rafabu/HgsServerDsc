<#
    .SYNOPSIS
    Checks if the current DNSServer settings match what is reqired. It does not actually set the DNSServer. Use it to provide some sort of DependsOn to non-DSC cofiguration.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the DNS server address is checked.

    .PARAMETER AddressFamily
    IP address family (IPV4 or IPv6).

    .PARAMETER Address
    The desired DNS Server address(es). Exclude to check for enabled DHCP.
#>

function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [String]
        $AddressFamily,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Address

    )


    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        "DNS Server Addresses: "
        ) -join '')

    # Remove the parameters we don't want to splat
    $null = $PSBoundParameters.Remove('Address')

    # Get the current DNS Server Addresses based on the parameters given.
    [String[]] $currentAddress = Get-DnsClientServerStaticAddress `
        @PSBoundParameters `
        -ErrorAction Stop

    $returnValue = @{
        Address        = $currentAddress
        AddressFamily  = $AddressFamily
        InterfaceAlias = $InterfaceAlias
    }

    return $returnValue
}

<#
    .SYNOPSIS
    Checks if the current DNSServer settings match what is reqired. It does not actually set the DNSServer. Use it to provide some sort of DependsOn to non-DSC cofiguration.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the DNS server address is checked.

    .PARAMETER AddressFamily
    IP address family (IPV4 or IPv6).

    .PARAMETER Address
    The desired DNS Server address(es). Exclude to check for enabled DHCP.
#>

function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [String]
        $AddressFamily,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Address

    )

    #dummy; won't set anything
    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            "DNS Server addresses aren't set in this resource."
            ) -join '' )
}

<#
    .SYNOPSIS
    Checks if the current DNSServer settings match what is reqired. It does not actually set the DNSServer. Use it to provide some sort of DependsOn to non-DSC cofiguration.

    .PARAMETER InterfaceAlias
    Alias of the network interface for which the DNS server address is checked.

    .PARAMETER AddressFamily
    IP address family (IPV4 or IPv6).

    .PARAMETER Address
    The desired DNS Server address(es). Exclude to check for enabled DHCP.
#>
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [String]
        $AddressFamily,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Address

    )

    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        "Checking DSN Server settings."
        ) -join '' )

    # Validate the Address passed or set to empty array if not passed
    if ($PSBoundParameters.ContainsKey('Address'))
    {
        foreach ($ServerAddress in $Address)
        {
            Assert-ResourceProperty `
                -Address $ServerAddress `
                -AddressFamily $AddressFamily `
                -InterfaceAlias $InterfaceAlias
        } # foreach
    }
    else
    {
        [String[]] $Address = @()
    } # if

    # Remove the parameters we don't want to splat
    $null = $PSBoundParameters.Remove('Address')

    # Get the current DNS Server Addresses based on the parameters given.
    [String[]] $currentAddress = @(Get-DnsClientServerStaticAddress `
        @PSBoundParameters `
        -ErrorAction Stop)

    # Check if the Server addresses are the same as the desired addresses.
    [Boolean] $addressDifferent = (@(Compare-Object `
            -ReferenceObject $currentAddress `
            -DifferenceObject $Address `
            -SyncWindow 0).Length -gt 0)

    if ($addressDifferent)
    {
        $desiredConfigurationMatch = $false

        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            "DNS Server Addresses do not match " `
                -f ($Address -join ','),($currentAddress -join ',')
            ) -join '' )
    }
    else
    {
        # Test will return true in this case
        Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            "DNS Server addesses are set correctly"
            ) -join '' )
    }
    return $desiredConfigurationMatch
}

function Assert-ResourceProperty
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [String]
        $AddressFamily,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Address
    )

    if ( -not (Get-NetAdapter | Where-Object -Property Name -EQ $InterfaceAlias ))
    {
        New-InvalidArgumentException `
            -Message ($LocalizedData.InterfaceNotAvailableError -f $InterfaceAlias) `
            -ArgumentName 'InterfaceAlias'
    }

    if ( -not ([System.Net.IPAddress]::TryParse($Address, [ref]0)))
    {
        New-InvalidArgumentException `
            -Message ($LocalizedData.AddressFormatError -f $Address) `
            -ArgumentName 'Address'
    }

    $detectedAddressFamily = ([System.Net.IPAddress]$Address).AddressFamily.ToString()
    if (($detectedAddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork.ToString()) `
        -and ($AddressFamily -ne 'IPv4'))
    {
        New-InvalidArgumentException `
            -Message ($LocalizedData.AddressIPv4MismatchError -f $Address,$AddressFamily) `
            -ArgumentName 'Address'
    }

    if (($detectedAddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6.ToString()) `
        -and ($AddressFamily -ne 'IPv6'))
    {
        New-InvalidArgumentException `
            -Message ($LocalizedData.AddressIPv6MismatchError -f $Address,$AddressFamily) `
            -ArgumentName 'Address'
    }
} # Assert-ResourceProperty

Export-ModuleMember -function *-TargetResource
