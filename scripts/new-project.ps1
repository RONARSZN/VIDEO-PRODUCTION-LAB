param([Parameter(Mandatory)][ValidatePattern('^[a-z0-9][a-z0-9-]*$')][string]$Name,[Parameter(Mandatory)][ValidatePattern('^[a-z0-9][a-z0-9-]*$')][string]$Client,[string]$Root=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
$target=Join-Path $Root "projects/$Name"
if(Test-Path -LiteralPath $target){throw "Project already exists: $target"}
New-Item -ItemType Directory -Path $target | Out-Null
foreach($file in @('BRIEF.md','STATE.md','HANDOFF.md','media-manifest.json')){Copy-Item -LiteralPath (Join-Path $Root "templates/project/$file") -Destination (Join-Path $target $file)}
$clientDir=Join-Path $Root "clients/$Client"
if(-not(Test-Path -LiteralPath $clientDir)){New-Item -ItemType Directory -Path $clientDir | Out-Null; Copy-Item -LiteralPath (Join-Path $Root 'templates/CLIENT.md') -Destination (Join-Path $clientDir 'CLIENT.md')}
Write-Output "Created $target for client $Client. Fill BRIEF.md and set Owner in STATE.md before editing."
