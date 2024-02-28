function FilterMdFileToExcludeModulePage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$Path
    )

    $MarkdownFiles = @()

    if ($Path) {
        $Path | ForEach-Object {
            if (Test-Path $_.FullName) {
                $md = Get-Content -Raw -Path $_.FullName
                $yml = [Markdown.MAML.Parser.MarkdownParser]::GetYamlMetadata($md)
                $isModulePage = $null -ne $yml.'Module Guid'

                if (-not $isModulePage) {
                    $MarkdownFiles += $_
                }
            }
            else {
                Write-Error -Message ($LocalizedData.PathNotFound -f $_.FullName)
            }
        }
    }

    return $MarkdownFiles
}