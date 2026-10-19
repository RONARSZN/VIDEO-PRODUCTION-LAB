param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$localCandidates = @((Join-Path $root '.local-tools/yt-dlp/yt-dlp'),(Join-Path $root '.local-tools/yt-dlp/yt-dlp.exe'))
$exe = $localCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $exe) {
  $command = Get-Command -Name @('yt-dlp','yt-dlp.exe') -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($command) { $exe = $command.Source }
}
if (-not $exe) { throw 'yt-dlp not found. Install it separately only when a workflow needs it.' }
& $exe @Arguments
exit $LASTEXITCODE