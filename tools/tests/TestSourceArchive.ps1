$ErrorActionPreference = 'Stop'
$taskSourceRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$taskScratch = Join-Path ([IO.Path]::GetTempPath()) ('fnf-source-metadata-' + [Guid]::NewGuid().ToString('N'))
$taskMacroPath = Join-Path $taskScratch 'funkin/util/macro'
New-Item -ItemType Directory -Path $taskMacroPath -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $taskSourceRoot 'source/funkin/util/macro/GitCommit.hx') -Destination $taskMacroPath
Copy-Item -LiteralPath (Join-Path $taskSourceRoot 'source/funkin/util/AnsiUtil.hx') -Destination (Join-Path $taskScratch 'funkin/util')
Push-Location -LiteralPath $taskScratch
try {
    & haxe -cp $taskScratch -cp $PSScriptRoot --run SourceArchiveMetadata
    if ($LASTEXITCODE -ne 0) { throw 'Source archive metadata regression failed.' }
} finally {
    Pop-Location
}
