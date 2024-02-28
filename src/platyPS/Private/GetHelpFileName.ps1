function GetHelpFileName
{
    param(
        [System.Management.Automation.CommandInfo]$CommandInfo
    )

    if ($CommandInfo)
    {
        if ($CommandInfo.HelpFile)
        {
            if ([System.IO.Path]::IsPathRooted($CommandInfo.HelpFile))
            {
                return (Split-Path -Leaf $CommandInfo.HelpFile)
            }
            else
            {
                return $CommandInfo.HelpFile
            }
        }
        # only run module evaluations if the input command isn't a script
        if ($CommandInfo.CommandType -ne "ExternalScript")
        {
            # overwise, lets guess it
            $module = @($CommandInfo.Module) + ($CommandInfo.Module.NestedModules) |
                Where-Object {$_.ModuleType -ne 'Manifest'} |
                Where-Object {$_.ExportedCommands.Keys -contains $CommandInfo.Name}

            $nestedModules = @(
                ($CommandInfo.Module.NestedModules) |
                Where-Object { $_.ModuleType -ne 'Manifest' } |
                Where-Object { $_.ExportedCommands.Keys -contains $CommandInfo.Name } |
                Select-Object -ExpandProperty Path
            )

            if (-not $module)
            {
                Write-Warning -Message ($LocalizedData.ModuleNotFoundFromCommand -f '[GetHelpFileName]', $CommandInfo.Name)
                return
            }

            if ($module.Count -gt 1)
            {
                Write-Warning -Message ($LocalizedData.MultipleModulesFoundFromCommand -f '[GetHelpFileName]', $CommandInfo.Name)
                $module = $module | Select-Object -First 1
            }

            if (Test-Path $module.Path -Type Leaf)
            {
                # for regular modules, we can deduct the filename from the module path file
                $moduleItem = Get-Item -Path $module.Path

                $isModuleItemNestedModule =
                    $null -ne ($nestedModules | Where-Object { $_ -eq $module.Path }) -and
                    $CommandInfo.ModuleName -ne $module.Name

                if ($moduleItem.Extension -eq '.psm1' -and -not $isModuleItemNestedModule) {
                    $fileName = $moduleItem.BaseName
                } else {
                    $fileName = $moduleItem.Name
                }
            }
            else
            {
                # if it's something like Dynamic module,
                # we  guess the desired help file name based on the module name
                $fileName = $module.Name
            }
        }

        return "$fileName-help.xml"
    }
}