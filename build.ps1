<#
.SYNOPSIS
    Builds the MarkDown/MAML DLL and assembles the final package in out\platyPS.
#>
[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    $Configuration = "Debug",
    [switch]$SkipDocs,
    [switch]$SkipPester,
    [string]$DotnetCli,
    [string]$BuildVersion = $env:APPVEYOR_REPO_TAG_NAME,
    [switch]$CompressModule
)

function CompressPsm1 {
    [CmdletBinding()]
    param(
        # Specifies the path to the source PSM1 file.
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Path,

        # Specifies the path to save the compressed PSM1 file.
        [Parameter(Mandatory, Position = 1)]
        [string]
        $Destination,

        [Parameter()]
        [string[]]
        $DotSources = @('Private', 'Public')
    )

    process {
        enum FileReadState {
            BeforeRegion
            InRegion
            AfterRegion
        }

        if (Test-Path -Path $Path -PathType Container) {
            $Path = Join-Path -Path $Path -ChildPath 'platyPS.psm1'
        }
        $Path = (Resolve-Path -Path $Path).Path

        if (Test-Path -Path $Destination -PathType Container) {
            $Destination = Join-Path -Path $Destination -ChildPath 'platyPS.psm1'
        }
        $Destination = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)

        $DotSources = $DotSources | ForEach-Object {
            $src = Join-Path -Path ([io.fileinfo]$Path).DirectoryName -ChildPath $_
            $dst = Join-Path -Path ([io.fileinfo]$Destination).DirectoryName -ChildPath $_
            if (Test-Path -Path $dst) {
                Write-Verbose "Cleaning up $_ directory from previous uncompressed build"
                Remove-Item -Path $dst -Recurse -Force
            }
            (Resolve-Path -Path $src).Path
        }

        $readState = [FileReadState]::BeforeRegion
        $sb = [text.stringbuilder]::new()
        foreach ($line in [io.file]::ReadAllLines($Path)) {
            if ($readState -eq 'BeforeRegion' -and $line -match '^#region dot-source') {
                $readState = [FileReadState]::InRegion
                foreach ($ps1File in Get-ChildItem $DotSources -Filter '*.ps1') {
                    $null = $sb.AppendLine([io.file]::ReadAllText($ps1File.FullName))
                }
                continue
            }
            if ($readState -eq 'InRegion') {
                if ($line -match '^#endregion') {
                    $readState = [FileReadState]::AfterRegion
                }
                continue
            }
            $null = $sb.AppendLine($line)
        }
        [io.file]::WriteAllText($Destination, $sb.ToString())
    }
}

try {
    if (-not [string]::IsNullOrEmpty($PSScriptRoot)) {
        Push-Location $PSScriptRoot
    }
    if (-not $IsCoreCLR) {
        throw "This fork of platyPS is not compatible with .NET Framework."
    }
    
    $DotnetCli = if ([string]::IsNullOrEmpty($DotnetCli)) { (Get-Command -Name dotnet).Path } else { $DotnetCli }
    if (-not $DotnetCli) {
        throw "dotnet cli is not found in PATH, install it from https://docs.microsoft.com/en-us/dotnet/core/tools"
    }
    
    
    $framework = 'net7.0'
    
    & $DotnetCli publish ./src/Markdown.MAML -f $framework --output=./publish /p:Configuration=$Configuration
    
    # copy artifacts
    $null = New-Item -Name ".\out\platyPS" -ItemType Directory -ErrorAction SilentlyContinue
    $assemblies = Get-ChildItem './publish/Markdown.MAML.dll', './publish/YamlDotNet.dll'
    $assemblies | Copy-Item -Destination ".\out\platyPS\"
    Get-ChildItem -Path ".\src\platyPS\" -File | Copy-Item -Destination ".\out\platyPS\" -Force
    if ($CompressModule) {
        CompressPsm1 -Path ".\src\platyPS\platyPS.psm1" -Destination ".\out\platyPS\platyPS.psm1" -DotSources Private, Public
    } else {
        Get-ChildItem -Path ".\src\platyPS\" | Copy-Item -Destination ".\out\platyPS\" -Recurse -Force
    }
    
    # copy schema file and docs
    Copy-Item .\platyPS.schema.md .\out\platyPS
    New-Item -Type Directory .\out\platyPS\docs -ErrorAction SilentlyContinue > $null
    Copy-Item .\docs\* .\out\platyPS\docs\
    
    # copy template files
    New-Item -Type Directory .\out\platyPS\templates -ErrorAction SilentlyContinue > $null
    Copy-Item .\templates\* .\out\platyPS\templates\
    
    # put the right module version
    if ($ModuleVersion) {
        $manifest = Get-Content -Path .\out\platyPS\platyPS.psd1 -Raw
        $manifest = $manifest -replace "ModuleVersion = '0.0.1'", "ModuleVersion = '$ModuleVersion'"
        Set-Content -Value $manifest -Path .\out\platyPS\platyPS.psd1 -Encoding Ascii
    }
    
    if (-not $SkipDocs) {
        # dogfooding: generate help for the module
        $jobParams = @{
            Name             = "Build platyPS Docs - $(Get-Date -Format yyyy-MM-dd_HH-mm-ss)"
            ArgumentList     = ".\out\platyPS", ".\docs", ".\out\platyPS\en-US"
            WorkingDirectory = $PWD
            ScriptBlock      = {
                param([string]$modulePath, [string]$docsSource, [string]$docsOutput)
                $ErrorActionPreference = 'Stop'
                Import-Module $modulePath
                $null = New-ExternalHelp -Path $docsSource -OutputPath $docsOutput
            }
        }
        Start-Job @jobParams | Receive-Job -Wait -AutoRemoveJob -ErrorAction Stop
    }

    if (-not $SkipPester) {
        Start-Job -WorkingDirectory $PWD -ScriptBlock {
            Import-Module Pester -RequiredVersion '4.0.2'
            Invoke-Pester -Path .\test\Pester
        } | Receive-Job -Wait -AutoRemoveJob -ErrorAction Stop
    }
} finally {
    Pop-Location
}
