$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
$startMenuRoot = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$scoopAppsDir = Join-Path $startMenuRoot "Scoop Apps"
$legacyStartMenuDir = Join-Path $startMenuRoot "win"

$tools = @(
    @{
        Name = "POE App"
        Script = Join-Path $root "poe\app.bat"
    },
    @{
        Name = "POE CN"
        Script = Join-Path $root "poe\cn.bat"
    },
    @{
        Name = "Update v2rayN"
        Script = Join-Path $root "commands\v2rayn-update.bat"
    },
    @{
        Name = "Shutdown 23"
        Script = Join-Path $root "commands\shutdown23.bat"
    },
    @{
        Name = "zju-connect"
        Script = Join-Path $root "zju-connect\zju-connect.bat"
    }
)

$legacyShortcutNames = @(
    "Win - POE App.lnk",
    "Win - POE CN.lnk",
    "Win - Update v2rayN.lnk",
    "Win - Shutdown 23.lnk",
    "Win - zju-connect.lnk"
)

$currentShortcutNames = @($tools | ForEach-Object { "$($_.Name).lnk" })

function Get-OwnedDesktopAppLinks {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ShortcutNames
    )

    $links = New-Object System.Collections.ArrayList
    foreach ($name in $ShortcutNames) {
        [void]$links.Add("%APPDATA%\Microsoft\Windows\Start Menu\Programs\$name")
        [void]$links.Add("%APPDATA%\Microsoft\Windows\Start Menu\Programs\win\$name")
        [void]$links.Add("%APPDATA%\Microsoft\Windows\Start Menu\Programs\Scoop Apps\$name")
    }

    return @($links)
}

function Remove-StaleShortcuts {
    foreach ($shortcutName in $legacyShortcutNames) {
        Remove-Item -LiteralPath (Join-Path $scoopAppsDir $shortcutName) -Force -ErrorAction SilentlyContinue
    }

    if (Test-Path -LiteralPath $legacyStartMenuDir) {
        foreach ($shortcutName in @($legacyShortcutNames + $currentShortcutNames)) {
            Remove-Item -LiteralPath (Join-Path $legacyStartMenuDir $shortcutName) -Force -ErrorAction SilentlyContinue
        }

        $remaining = Get-ChildItem -LiteralPath $legacyStartMenuDir -Force -ErrorAction SilentlyContinue
        if (!$remaining) {
            Remove-Item -LiteralPath $legacyStartMenuDir -Force -ErrorAction SilentlyContinue
        }
    }
}

function Remove-StaleStartPinsPolicyEntries {
    $policyPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
    $policyName = "ConfigureStartPins"

    $existing = Get-ItemProperty -Path $policyPath -Name $policyName -ErrorAction SilentlyContinue
    if (!$existing -or !$existing.$policyName) {
        return
    }

    try {
        $ownedLinks = @{}
        foreach ($link in (Get-OwnedDesktopAppLinks -ShortcutNames @($legacyShortcutNames + $currentShortcutNames))) {
            $ownedLinks[$link.ToLowerInvariant()] = $true
        }

        $policy = $existing.$policyName | ConvertFrom-Json
        $remainingPins = New-Object System.Collections.ArrayList
        $removedCount = 0

        foreach ($pin in @($policy.pinnedList)) {
            $keepPin = $true
            if ($pin.desktopAppLink) {
                $pinLink = [string]$pin.desktopAppLink
                $pinKey = $pinLink.ToLowerInvariant()
                $isOwnedPin = $ownedLinks.ContainsKey($pinKey)
                $isMalformedOwnedPin = $pinLink -match "\.lnk\s+%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\(win|Scoop Apps)\\"
                if ($isOwnedPin -or $isMalformedOwnedPin) {
                    $keepPin = $false
                }
            }

            if ($keepPin) {
                [void]$remainingPins.Add($pin)
            } else {
                $removedCount++
            }
        }

        if ($removedCount -eq 0) {
            return
        }

        if ($remainingPins.Count -eq 0) {
            Remove-ItemProperty -Path $policyPath -Name $policyName -ErrorAction Stop
        } else {
            $policy.pinnedList = @($remainingPins)
            $json = $policy | ConvertTo-Json -Depth 8 -Compress
            Set-ItemProperty -Path $policyPath -Name $policyName -Type String -Value $json -ErrorAction Stop
        }

        Write-Output "Removed stale Start pins policy entries from previous installer versions."
    } catch {
        Write-Output "Could not clean stale Start pins policy entries: $($_.Exception.Message)"
    }
}

function New-ToolShortcut {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Tool,

        [Parameter(Mandatory = $true)]
        [object]$ShortcutShell
    )

    if (!(Test-Path -LiteralPath $Tool.Script)) {
        throw "Missing tool script: $($Tool.Script)"
    }

    $scriptPath = (Resolve-Path -LiteralPath $Tool.Script).Path
    $shortcutPath = Join-Path $scoopAppsDir "$($Tool.Name).lnk"
    $shortcut = $ShortcutShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $env:ComSpec
    $shortcut.Arguments = "/d /c `"$scriptPath`""
    $shortcut.WorkingDirectory = Split-Path -Parent $scriptPath
    $shortcut.Description = "Launch $($Tool.Name)"
    $shortcut.Save()

    return $shortcutPath
}

function Test-PinToStartVerbName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VerbName
    )

    return $VerbName -match "Pin to Start|固定到.*开始"
}

function Test-UnpinFromStartVerbName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VerbName
    )

    return $VerbName -match "Unpin from Start|从.*开始.*取消固定|取消.*开始.*固定"
}

function Get-ShortcutStartPinState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ShortcutPath,

        [Parameter(Mandatory = $true)]
        [object]$Shell
    )

    $folderPath = Split-Path -Parent $ShortcutPath
    $leafName = Split-Path -Leaf $ShortcutPath
    $folder = $Shell.Namespace($folderPath)
    if ($null -eq $folder) {
        return [pscustomobject]@{
            Success = $false
            IsPinned = $false
            PinVerb = $null
            Reason = "Shell folder was not available."
        }
    }

    $item = $folder.ParseName($leafName)
    if ($null -eq $item) {
        return [pscustomobject]@{
            Success = $false
            IsPinned = $false
            PinVerb = $null
            Reason = "Shell item was not available."
        }
    }

    $pinVerb = $null
    $isPinned = $false
    foreach ($verb in @($item.Verbs())) {
        $name = $verb.Name.Replace("&", "").Trim()
        if (!$name) {
            continue
        }

        if (Test-UnpinFromStartVerbName -VerbName $name) {
            $isPinned = $true
        } elseif (Test-PinToStartVerbName -VerbName $name) {
            $pinVerb = $verb
        }
    }

    return [pscustomobject]@{
        Success = $true
        IsPinned = $isPinned
        PinVerb = $pinVerb
        Reason = $null
    }
}

function Invoke-PinToStart {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ShortcutPath
    )

    $shell = New-Object -ComObject Shell.Application
    $lastReason = $null

    foreach ($attempt in 1..4) {
        $state = Get-ShortcutStartPinState -ShortcutPath $ShortcutPath -Shell $shell
        if (!$state.Success) {
            $lastReason = $state.Reason
            Start-Sleep -Milliseconds 300
            continue
        }

        if ($state.IsPinned) {
            return [pscustomobject]@{
                Success = $true
                Action = "AlreadyPinned"
                Reason = $null
            }
        }

        if ($null -eq $state.PinVerb) {
            $lastReason = "Windows did not expose a Pin to Start verb."
            Start-Sleep -Milliseconds 300
            continue
        }

        try {
            $state.PinVerb.DoIt()
        } catch {
            return [pscustomobject]@{
                Success = $false
                Action = "Denied"
                Reason = $_.Exception.Message
            }
        }

        Start-Sleep -Milliseconds 900
        $verified = Get-ShortcutStartPinState -ShortcutPath $ShortcutPath -Shell $shell
        if ($verified.Success -and $verified.IsPinned) {
            return [pscustomobject]@{
                Success = $true
                Action = "Pinned"
                Reason = $null
            }
        }

        $lastReason = "Pin command completed, but Start did not report the shortcut as pinned."
    }

    return [pscustomobject]@{
        Success = $false
        Action = "Unavailable"
        Reason = $lastReason
    }
}

Remove-StaleShortcuts
Remove-StaleStartPinsPolicyEntries

New-Item -ItemType Directory -Path $scoopAppsDir -Force | Out-Null

$shortcutShell = New-Object -ComObject WScript.Shell
$pinFailures = @()

foreach ($tool in $tools) {
    $shortcutPath = New-ToolShortcut -Tool $tool -ShortcutShell $shortcutShell
    Write-Output "Created Start menu shortcut: $shortcutPath"

    $pinResult = Invoke-PinToStart -ShortcutPath $shortcutPath
    if ($pinResult.Success) {
        if ($pinResult.Action -eq "AlreadyPinned") {
            Write-Output "Start pin already exists: $shortcutPath"
        } else {
            Write-Output "Pinned to Start: $shortcutPath"
        }
    } else {
        Write-Output "Could not pin to Start automatically: $shortcutPath"
        Write-Output "Pin reason: $($pinResult.Reason)"
        $pinFailures += $shortcutPath
    }
}

if ($pinFailures.Count -gt 0) {
    Write-Output "Windows may block apps from pinning Start items programmatically."
    Write-Output "The shortcuts are available under Start > All apps > Scoop Apps for manual pinning."
}
