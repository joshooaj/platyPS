<#
.SYNOPSIS
    Builds the MarkDown/MAML DLL and assembles the final package in out\joshooaj.platyPS.
#>
[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    $Configuration = "Debug",
    [switch]$SkipDocs,
    [string]$DotnetCli,
    [switch]$Test
)

function Find-DotnetCli() {
    [string] $DotnetCli = ''
    $dotnetCmd = Get-Command dotnet
    return $dotnetCmd.Path
}

if ($null -eq (Get-Module Microsoft.PowerShell.PSResourceGet -ListAvailable)) {
    Install-Module Microsoft.PowerShell.PSResourceGet -Force -MinimumVersion 1.0.4.1
}
Install-PSResource -RequiredResourceFile $PSScriptRoot/requirements.json -Scope CurrentUser -TrustRepository -AcceptLicense -Quiet -WarningAction SilentlyContinue
Import-Module Pester -RequiredVersion 4.10.1

if (-not $DotnetCli) {
    $DotnetCli = Find-DotnetCli
}

if (-not $DotnetCli) {
    throw "dotnet cli is not found in PATH, install it from https://docs.microsoft.com/en-us/dotnet/core/tools"
} else {
    Write-Host "Using dotnet from $DotnetCli"
}

& dotnet tool restore
$framework = 'netstandard2.0'
& $DotnetCli publish ./src/Markdown.MAML -f $framework --output=$pwd/publish /p:Configuration=$Configuration

$assemblyPaths = (
    (Resolve-Path "$PSScriptRoot/publish/Markdown.MAML.dll").Path,
    (Resolve-Path "$PSScriptRoot/publish/YamlDotNet.dll").Path
)

# copy artifacts
New-Item -Type Directory out\joshooaj.platyPS -ErrorAction SilentlyContinue > $null
Copy-Item -Rec -Force src\platyPS\* out\joshooaj.platyPS
foreach ($assemblyPath in $assemblyPaths) {
    $assemblyFileName = [System.IO.Path]::GetFileName($assemblyPath)
    $outputPath = "out\joshooaj.platyPS\$assemblyFileName"
    if ((-not (Test-Path $outputPath)) -or
		(Test-Path $outputPath -OlderThan (Get-ChildItem $assemblyPath).LastWriteTime)) {
        Copy-Item $assemblyPath out\joshooaj.platyPS
    } else {
        Write-Host -Foreground Yellow "Skip $assemblyFileName copying"
    }
}

# copy schema file and docs
Copy-Item .\platyPS.schema.md out\joshooaj.platyPS
New-Item -Type Directory out\joshooaj.platyPS\docs -ErrorAction SilentlyContinue > $null
Copy-Item .\docs\* out\joshooaj.platyPS\docs\

# copy template files
New-Item -Type Directory out\joshooaj.platyPS\templates -ErrorAction SilentlyContinue > $null
Copy-Item .\templates\* out\joshooaj.platyPS\templates\

# put the right module version
$moduleVersion = (dotnet nbgv get-version -f json | ConvertFrom-Json).SimpleVersion
$manifest = cat -raw out\joshooaj.platyPS\joshooaj.platyPS.psd1
$manifest = $manifest -replace "(?<=ModuleVersion\s*=\s*)'0.0.1'", "'$moduleVersion'"
Set-Content -Value $manifest -Path out\joshooaj.platyPS\joshooaj.platyPS.psd1 -Encoding Ascii

# dogfooding: generate help for the module
if (-not $SkipDocs) {
    Remove-Module joshooaj.platyPS -ErrorAction SilentlyContinue
    Import-Module $pwd\out\joshooaj.platyPS
    
    New-ExternalHelp docs -OutputPath out\joshooaj.platyPS\en-US -Force
    
    # reload module, to apply generated help
    Import-Module $pwd\out\joshooaj.platyPS -Force
}

if ($Test) {
    dotnet test .\test\Markdown.MAML.Test
    if ($LASTEXITCODE) {
        throw "dotnet test exited with $LASTEXITCODE"
    }

    $pesterTestResultsFile = [io.path]::Combine($PSScriptRoot, 'out', 'TestsResults.xml')
    $res = Invoke-Pester -OutputFormat NUnitXml -OutputFile $pesterTestResultsFile -PassThru
    # Trying to fail the build, if there are problems
    $errorString = ''
    # All tests should pass
    if ($res.FailedCount -gt 0) {
        $errorString += "$($res.FailedCount) tests failed.`n"
    }
    # Documentation itself should be up-to-date
    Update-MarkdownHelp -Path ./docs
    $diff = git diff
    if ($diff) {
        $errorString += "Help is not up-to-date, run Update-MarkdownHelp: $diff`n"
    }
    if ($errorString) {
        throw $errorString
    }
}
