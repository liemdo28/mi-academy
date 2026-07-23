param(
  [switch]$RequireSignedAndroid,
  [switch]$SkipTests,
  [switch]$SkipWeb,
  [switch]$SkipWindows
)

$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$app = Join-Path $repo "apps/mobile"
$androidKeyProperties = Join-Path $app "android/key.properties"

function Invoke-Step {
  param(
    [string]$Name,
    [scriptblock]$Script
  )
  Write-Host ""
  Write-Host "== $Name =="
  & $Script
}

function Invoke-Native {
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Command
  )
  & $Command[0] @($Command | Select-Object -Skip 1)
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: $($Command -join ' ')"
  }
}

Push-Location $app
try {
  if ($RequireSignedAndroid -and -not (Test-Path $androidKeyProperties)) {
    throw "Signed Android build requested, but apps/mobile/android/key.properties is missing."
  }

  Invoke-Step "Resolve dependencies" { Invoke-Native flutter pub get }

  if (-not $SkipTests) {
    Invoke-Step "Analyze mobile app" { Invoke-Native flutter analyze }
    Invoke-Step "Run mobile tests" { Invoke-Native flutter test }
  }

  # Workaround for Flutter tool regression that can leak integration_test into
  # the release registrant after pub get. See flutter/flutter#169336.
  Invoke-Step "Prepare Android release config" {
    Invoke-Native flutter build apk --config-only
  }

  Invoke-Step "Build Android debug APK" {
    Invoke-Native flutter build apk --debug --no-pub
  }
  Invoke-Step "Build Android profile APK" {
    Invoke-Native flutter build apk --profile --no-pub
  }
  Invoke-Step "Build Android release APK" {
    Invoke-Native flutter build apk --release --no-pub
  }
  Invoke-Step "Build Android release AAB" {
    Invoke-Native flutter build appbundle --release --no-pub
  }

  if (-not $SkipWeb) {
    Invoke-Step "Build Web release" {
      Invoke-Native flutter build web --release --no-pub
    }
  }

  if (-not $SkipWindows) {
    Invoke-Step "Build Windows release" {
      Invoke-Native flutter build windows --release --no-pub
    }
  }

  Write-Host ""
  Write-Host "Release artifacts:"
  Get-Item `
    "build/app/outputs/flutter-apk/app-debug.apk", `
    "build/app/outputs/flutter-apk/app-profile.apk", `
    "build/app/outputs/flutter-apk/app-release.apk", `
    "build/app/outputs/bundle/release/app-release.aab", `
    "build/web/index.html", `
    "build/windows/x64/runner/Release/mi_academy.exe" `
    -ErrorAction SilentlyContinue |
    Select-Object FullName, Length |
    Format-Table -AutoSize
} finally {
  Pop-Location
}
