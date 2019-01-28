@{
# Version number of this module.
moduleVersion = '0.0.8.0'

# ID used to uniquely identify this module
GUID = 'aec2d300-e6b5-43d1-a891-bc5c7b65c32b'

# Author of this module
Author = 'Raphael Burri'

# Company or vendor of this module
CompanyName = 'rabuzu cloud'

# Copyright statement for this module
Copyright = '(c) 2018 rabuzu cloud. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Enabvles DSC to deploy and configure Host Guardian Service (HGS).'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '4.0'

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('DSC', 'HGS', 'GuardedFabric', 'DSCResource')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/rafabu/HgsServerDsc/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/rafabu/HgsServerDsc'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '* initial experimental release

'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}
