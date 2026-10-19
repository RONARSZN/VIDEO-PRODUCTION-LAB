param([Parameter(Mandatory)][string]$Package,[Parameter(Mandatory)][string]$Destination)
$ErrorActionPreference='Stop'
$Package=[IO.Path]::GetFullPath($Package); $Destination=[IO.Path]::GetFullPath($Destination)
if(-not(Test-Path -LiteralPath $Package)){throw 'Package not found'}
if(Test-Path -LiteralPath $Destination){throw 'Destination exists. Restore to a new empty path; do not overwrite.'}
$archive=[IO.Compression.ZipFile]::OpenRead($Package)
try {
  foreach($entry in $archive.Entries){
    $name=$entry.FullName.Replace('\','/')
    if($name.StartsWith('/') -or $name -match '(^|/)\.\.(/|$)' -or $name -match '^[A-Za-z]:'){throw "Unsafe archive path: $name"}
    if($name -match '(?i)(^|/)(\.git|\.env|browser-profiles|source|work|renders|private)(/|$)|\.(mp4|mov|mxf|wav|pem|p12|pfx|key)$'){throw "Unexpected private data in package: $name"}
  }
  New-Item -ItemType Directory -Path $Destination | Out-Null
  [IO.Compression.ZipFile]::ExtractToDirectory($Package,$Destination)
} finally {$archive.Dispose()}
if(-not(Test-Path -LiteralPath (Join-Path $Destination 'shared/WORKSPACE_CORE.md'))){throw 'Package lacks core instructions'}
& (Join-Path $Destination 'scripts/bootstrap.ps1') -Root $Destination
Write-Output 'Restore complete. Run doctor and reconnect each agent/account as required.'
