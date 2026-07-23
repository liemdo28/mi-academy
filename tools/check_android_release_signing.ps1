param(
  [string]$KeystorePath = "apps/mobile/android/upload-keystore.jks",
  [string]$KeyPropertiesPath = "apps/mobile/android/key.properties"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $KeyPropertiesPath)) {
  throw "Missing $KeyPropertiesPath. Release builds will fall back to debug signing."
}

if (-not (Test-Path $KeystorePath)) {
  throw "Missing $KeystorePath."
}

$props = @{}
Get-Content -LiteralPath $KeyPropertiesPath | ForEach-Object {
  if ($_ -match "^\s*([^#][^=]+)=(.*)$") {
    $props[$Matches[1].Trim()] = $Matches[2].Trim()
  }
}

foreach ($name in @("storePassword", "keyPassword", "keyAlias", "storeFile")) {
  if (-not $props.ContainsKey($name) -or [string]::IsNullOrWhiteSpace($props[$name])) {
    throw "Missing $name in $KeyPropertiesPath."
  }
}

Write-Host "Android release signing config exists."
Write-Host "Keystore: $KeystorePath"
Write-Host "Alias: $($props["keyAlias"])"
Write-Host "Reminder: keep the keystore and passwords backed up outside the repo."
