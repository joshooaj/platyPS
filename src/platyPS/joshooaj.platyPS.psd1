@{
    RootModule         = 'joshooaj.platyPS.psm1'
    # Do not edit the version. The version is updated by the build script.
    ModuleVersion      = '0.0.1'
    GUID               = 'd6a38931-edd0-4552-9ec0-9c4ec1641fa9'
    Author             = 'Josh Hendricks'
    CompanyName        = 'Community'
    Copyright          = '(c) 2024 Joshua Hendricks. All rights reserved.'
    Description        = 'Generate PowerShell External Help files from Markdown'
    RequiredAssemblies = @('Markdown.MAML.dll', 'YamlDotNet.dll')
    NestedModules      = @()
    FunctionsToExport  = @(
        'New-MarkdownHelp',
        'Get-MarkdownMetadata',
        'New-ExternalHelp',
        'New-YamlHelp',
        'Get-HelpPreview',
        'New-ExternalHelpCab',
        'Update-MarkdownHelp',
        'Update-MarkdownHelpModule',
        'New-MarkdownAboutHelp',
        'Merge-MarkdownHelp'
    )
    CmdletsToExport    = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    PrivateData        = @{
        PSData = @{
            Tags       = @('help', 'markdown', 'MAML', 'PSEdition_Core', 'PSEdition_Desktop')
            LicenseUri = 'https://github.com/joshooaj/platyPS/blob/master/LICENSE'
            ProjectUri = 'https://github.com/joshooaj/platyPS'
            # IconUri = ''
            # ReleaseNotes = ''
        }
    }
    HelpInfoURI        = 'https://aka.ms/ps-modules-help'
}
