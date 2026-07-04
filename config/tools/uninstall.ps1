$ErrorActionPreference = "Stop"

$startMenuRoot = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$startMenuDir = Join-Path $startMenuRoot "win"
$currentShortcutNames = @(
    "POE App.lnk",
    "POE CN.lnk",
    "Update v2rayN.lnk",
    "Shutdown 23.lnk",
    "zju-connect.lnk"
)
$legacyShortcutNames = @(
    "Win - POE App.lnk",
    "Win - POE CN.lnk",
    "Win - Update v2rayN.lnk",
    "Win - Shutdown 23.lnk",
    "Win - zju-connect.lnk"
)
$shortcutNames = @($currentShortcutNames + $legacyShortcutNames)

function Invoke-UnpinFromStart {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ShortcutPath,

        [Parameter(Mandatory = $true)]
        [object]$Shell
    )

    if (!(Test-Path -LiteralPath $ShortcutPath)) {
        return
    }

    try {
        $folder = $Shell.Namespace((Split-Path -Parent $ShortcutPath))
        if ($null -eq $folder) {
            return
        }

        $item = $folder.ParseName((Split-Path -Leaf $ShortcutPath))
        if ($null -eq $item) {
            return
        }

        try {
            $item.InvokeVerb("startunpin")
        } catch {
        }

        foreach ($verb in @($item.Verbs())) {
            $name = $verb.Name.Replace("&", "").Trim()
            if ($name -match "Unpin from Start|从.*开始.*取消固定|取消.*开始.*固定") {
                try {
                    $verb.DoIt()
                } catch {
                }
                break
            }
        }
    } catch {
    }
}

$shortcutShell = New-Object -ComObject Shell.Application

foreach ($name in $shortcutNames) {
    $paths = @(
        (Join-Path $startMenuRoot $name),
        (Join-Path $startMenuDir $name)
    )

    foreach ($path in $paths) {
        Invoke-UnpinFromStart -ShortcutPath $path -Shell $shortcutShell
        Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    }
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
        $ownDesktopAppLinks = @{}
        foreach ($name in $shortcutNames) {
            $ownDesktopAppLinks["%APPDATA%\Microsoft\Windows\Start Menu\Programs\$name".ToLowerInvariant()] = $true
            $ownDesktopAppLinks["%APPDATA%\Microsoft\Windows\Start Menu\Programs\win\$name".ToLowerInvariant()] = $true
        }
        $remainingPins = @(
            foreach ($pin in @($policy.pinnedList)) {
                if (!$pin.desktopAppLink -or !$ownDesktopAppLinks.ContainsKey($pin.desktopAppLink.ToLowerInvariant())) {
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
