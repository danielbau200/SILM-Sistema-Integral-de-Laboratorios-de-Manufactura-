$ErrorActionPreference = 'Continue'

$sdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { "$env:LOCALAPPDATA\Android\Sdk" }
$adb = Join-Path $sdkRoot 'platform-tools\adb.exe'
$emulator = Join-Path $sdkRoot 'emulator\emulator.exe'
$avdName = 'Voxelcost_Tablet'
$deviceId = 'emulator-5554'

if (-not (Test-Path $adb)) { throw "No se encontro adb en $adb" }
if (-not (Test-Path $emulator)) { throw "No se encontro el emulador en $emulator" }

$state = (& $adb -s $deviceId get-state 2>$null | Out-String).Trim()
if ($state -ne 'device') {
    $targetProcess = Get-CimInstance Win32_Process -Filter "Name = 'emulator.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match "-avd\s+$avdName(\s|$)" }
    if (-not $targetProcess) {
        & $adb disconnect $deviceId 2>$null | Out-Null
        Start-Process -FilePath $emulator -ArgumentList @(
            '-avd', $avdName,
            '-no-boot-anim',
            '-no-snapshot-load',
            '-no-snapshot-save',
            '-gpu',
            'swiftshader_indirect'
        ) -WindowStyle Normal
    }
}

$deadline = (Get-Date).AddSeconds(120)
do {
    $state = (& $adb -s $deviceId get-state 2>$null | Out-String).Trim()
    if ($state -eq 'device') {
        $bootCompleted = (& $adb -s $deviceId shell getprop sys.boot_completed 2>$null | Out-String).Trim()
        if ($bootCompleted -match '1') { exit 0 }
    }
    [System.Threading.Thread]::Sleep(2000)
} while ((Get-Date) -lt $deadline)

throw "El emulador $avdName no termino de arrancar dentro del tiempo esperado."
