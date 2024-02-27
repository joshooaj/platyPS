<#
.SYNOPSIS
    Builds the MarkDown/MAML DLL and assembles the final package in out\platyPS.
#>
[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    $Configuration = "Debug",
    [switch]$SkipDocs,
    [string]$DotnetCli,
    [string]$BuildVersion = $env:APPVEYOR_REPO_TAG_NAME
)

if (-not $IsCoreCLR) {
    throw "This fork of platyPS is not compatible with .NET Framework."
}

$DotnetCli = if ([string]::IsNullOrEmpty($DotnetCli)) { (Get-Command -Name dotnet).Path } else { $DotnetCli }
if (-not $DotnetCli) {
    throw "dotnet cli is not found in PATH, install it from https://docs.microsoft.com/en-us/dotnet/core/tools"
}


$framework = 'net8.0'

& $DotnetCli publish ./src/Markdown.MAML -f $framework --output=$pwd/publish /p:Configuration=$Configuration

$assemblyPaths = (
    (Resolve-Path "publish/Markdown.MAML.dll").Path,
    (Resolve-Path "publish/YamlDotNet.dll").Path
)

# copy artifacts
$null = New-Item -Name out -Type Directory -ErrorAction SilentlyContinue
Copy-Item -Path src\platyPS -Destination out -Recurse -Force
foreach ($assemblyPath in $assemblyPaths) {
    $assemblyFileName = [System.IO.Path]::GetFileName($assemblyPath)
    $outputPath = "out\platyPS\$assemblyFileName"
    if ((-not (Test-Path $outputPath)) -or
		(Test-Path $outputPath -OlderThan (Get-ChildItem $assemblyPath).LastWriteTime)) {
        Copy-Item $assemblyPath out\platyPS
    } else {
        Write-Host -Foreground Yellow "Skip $assemblyFileName copying"
    }
}

# copy schema file and docs
Copy-Item .\platyPS.schema.md out\platyPS
New-Item -Type Directory out\platyPS\docs -ErrorAction SilentlyContinue > $null
Copy-Item .\docs\* out\platyPS\docs\

# copy template files
New-Item -Type Directory out\platyPS\templates -ErrorAction SilentlyContinue > $null
Copy-Item .\templates\* out\platyPS\templates\

# put the right module version
if ($ModuleVersion) {
    $manifest = Get-Content -Path out\platyPS\platyPS.psd1 -Raw
    $manifest = $manifest -replace "ModuleVersion = '0.0.1'", "ModuleVersion = '$ModuleVersion'"
    Set-Content -Value $manifest -Path $PSScriptRoot\out\platyPS\platyPS.psd1 -Encoding Ascii
}

if (-not $SkipDocs) {
    # dogfooding: generate help for the module
    $jobParams = @{
        Name         = "Build platyPS Docs - $(Get-Date -Format yyyy-MM-dd_HH-mm-ss)"
        ArgumentList = "$PSScriptRoot\out\platyPS", "$PSScriptRoot\docs", "$PSScriptRoot\out\platyPS\en-US"
        ScriptBlock  = {
            param([string]$modulePath, [string]$docsSource, [string]$docsOutput)
            $ErrorActionPreference = 'Stop'
            Import-Module $modulePath
            New-ExternalHelp -Path $docsSource -OutputPath $docsOutput
        }
    }
    Start-Job @jobParams | Receive-Job -Wait -AutoRemoveJob -ErrorAction Stop
}
