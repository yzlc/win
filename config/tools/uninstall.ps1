$ErrorActionPreference = "Stop"

$startMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\win"
$shortcutNames = @(
    "Win - POE App.lnk",
    "Win - POE CN.lnk",
    "Win - Update v2rayN.lnk",
    "Win - Shutdown 23.lnk",
    "Win - zju-connect.lnk"
)

foreach ($name in $shortcutNames) {
    $path = Join-Path $startMenuDir $name
    Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
}

if (Test-Path -LiteralPath $startMenuDir) {
    $remaining = Get-ChildItem -LiteralPath $startMenuDir -Force -ErrorAction SilentlyContinue
    if (!$remaining) {
        Remove-Item -LiteralPath $startMenuDir -Force -ErrorAction SilentlyContinue
    }
}

$policyPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
$policyName = "ConfigureStartPins"
$policyValue = Get-ItemProperty -Path $policyPath -Name $policyName -ErrorAction SilentlyContinue

if ($policyValue -and $policyValue.$policyName) {
    try {
        $policy = $policyValue.$policyName | ConvertFrom-Json
        $ownPrefix = "%APPDATA%\Microsoft\Windows\Start Menu\Programs\win\"
        $remainingPins = @(
            foreach ($pin in @($policy.pinnedList)) {
                if (!$pin.desktopAppLink -or !$pin.desktopAppLink.StartsWith($ownPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                    $pin
                }
            }
        )

        if ($remainingPins.Count -eq 0) {
            Remove-ItemProperty -Path $policyPath -Name $policyName -ErrorAction SilentlyContinue
        } else {
            $policy.pinnedList = $remainingPins
            $json = $policy | ConvertTo-Json -Depth 8 -Compress
            Set-ItemProperty -Path $policyPath -Name $policyName -Type String -Value $json
        }
    } catch {
        Write-Output "Could not update Start pins policy: $($_.Exception.Message)"
    }
}

Stop-Process -Name StartMenuExperienceHost -Force -ErrorAction SilentlyContinue
