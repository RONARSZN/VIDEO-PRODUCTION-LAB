[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$InputFile,
  [Parameter(Mandatory = $true)][string]$OutputDirectory,
  [ValidateSet('tiny','base','small','medium','large','turbo')][string]$Model = 'base',
  [ValidateSet('txt','vtt','srt','tsv','json','all')][string]$OutputFormat = 'vtt',
  [string]$Language,
  [string]$WhisperExecutable,
  [string]$ModelDirectory
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$resolvedInput = (Resolve-Path -LiteralPath $InputFile).Path
if ((Get-Item -LiteralPath $resolvedInput).PSIsContainer) {
  throw "InputFile must be a media file: $resolvedInput"
}

if ($WhisperExecutable) {
  $whisperExe = $WhisperExecutable
} elseif ($env:VPL_WHISPER_EXE) {
  $whisperExe = $env:VPL_WHISPER_EXE
} else {
  $whisperCommand = Get-Command -Name @('whisper','whisper.exe') -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($whisperCommand) {
    $whisperExe = $whisperCommand.Source
    }
}
if (-not $whisperExe -or -not (Test-Path -LiteralPath $whisperExe)) {
  throw 'Whisper CLI not found. Set VPL_WHISPER_EXE or pass -WhisperExecutable.'
}

if ($ModelDirectory) {
  $modelDir = $ModelDirectory
} elseif ($env:VPL_WHISPER_MODEL_DIR) {
  $modelDir = $env:VPL_WHISPER_MODEL_DIR
} else {
  $modelDir = Join-Path $root '.local-tools/whisper/models'
}

$modelDir = [IO.Path]::GetFullPath($modelDir)
$outputDir = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force -Path $modelDir, $outputDir | Out-Null

$arguments = @(
  $resolvedInput,
  '--model', $Model,
  '--model_dir', $modelDir,
  '--device', 'cpu',
  '--output_dir', $outputDir,
  '--output_format', $OutputFormat,
  '--task', 'transcribe',
  '--fp16', 'False'
)
if ($Language) {
  $arguments += @('--language', $Language)
}

Write-Output "Transcribing with Whisper model '$Model' on CPU. Output: $outputDir"
$previousPythonUtf8 = $env:PYTHONUTF8
$env:PYTHONUTF8 = '1'
try {
  & $whisperExe @arguments
  $exitCode = $LASTEXITCODE
} finally {
  if ($null -eq $previousPythonUtf8) {
    Remove-Item Env:PYTHONUTF8 -ErrorAction SilentlyContinue
  } else {
    $env:PYTHONUTF8 = $previousPythonUtf8
  }
}
exit $exitCode
