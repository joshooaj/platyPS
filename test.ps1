Import-Module pester -requiredversion 4.10.1
$pesterTestResultsFile = ".\TestsResults.xml"
$res = Invoke-Pester -OutputFormat NUnitXml -OutputFile $pesterTestResultsFile -PassThru