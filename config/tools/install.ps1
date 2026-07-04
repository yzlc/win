$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
$startMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\win"

$tools = @(
    @{
        Name = "Win - POE App"
        Script = Join-Path $root "poe\app.bat"
    },
    @{
        Name = "Win - POE CN"
        Script = Join-Path $root "poe\cn.bat"
    },
    @{
        Name = "Win - Update v2rayN"
        Script = Join-Path $root "commands\v2rayn-update.bat"
    },
    @{
        Name = "Win - Shutdown 23"
        Script = Join-Path $root "commands\shutdown23.bat"
    },
    @{
        Name = "Win - zju-connect"
        Script = Join-Path $root "zju-connect\zju-connect.bat"
    }
)

function Invoke-PinToStart {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ShortcutPath
    )

    try {
        $shell = New-Object -ComObject Shell.Application
        $folderPath = Split-Path -Parent $ShortcutPath
        $leafName = Split-Path -Leaf $ShortcutPath
        $folder = $shell.Namespace($folderPath)
        if ($null -eq $folder) {
            return $false
        }

        $item = $folder.ParseName($leafName)
        if ($null -eq $item) {
            return $false
        }

        foreach ($verb in @($item.Verbs())) {
            $name = $verb.Name.Replace("&", "").Trim()
            if ($name -match "Pin to Start|固定.*开始") {
                $verb.DoIt()
                return $true
            }
        }

        try {
            $item.InvokeVerb("startpin")
            return $true
        } catch {
            return $false
        }
    } catch {
        return $false
    }
}

function Set-StartPinsPolicy {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$DesktopAppLinks
    )

    $policyPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
    $policyName = "ConfigureStartPins"

    try {
        $pins = New-Object System.Collections.ArrayList

        $existing = Get-ItemProperty -Path $policyPath -Name $policyName -ErrorAction SilentlyContinue
        if ($existing -and $existing.$policyName) {
            try {
                $policy = $existing.$policyName | ConvertFrom-Json
                foreach ($pin in @($policy.pinnedList)) {
                    [void]$pins.Add($pin)
                }
            } catch {
                Write-Output "Existing Start pins policy is not valid JSON; replacing it."
            }
        }

        $knownLinks = @{}
        foreach ($pin in $pins) {
            if ($pin.desktopAppLink) {
                $knownLinks[$pin.desktopAppLink.ToLowerInvariant()] = $true
            }
        }

        foreach ($link in $DesktopAppLinks) {
            $key = $link.ToLowerInvariant()
            if (!$knownLinks.ContainsKey($key)) {
                [void]$pins.Add([ordered]@{desktopAppLink = $link})
                $knownLinks[$key] = $true
            }
        }

        New-Item -Path $policyPath -Force -ErrorAction Stop | Out-Null
        $json = [ordered]@{pinnedList = @($pins)} | ConvertTo-Json -Depth 8 -Compress
        Set-ItemProperty -Path $policyPath -Name $policyName -Type String -Value $json -ErrorAction Stop
        Write-Output "Applied Windows Start pins policy for current user."
        Write-Output "If pins do not appear immediately, sign out and sign in again."

        Stop-Process -Name StartMenuExperienceHost -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Output "Could not apply Windows Start pins policy: $($_.Exception.Message)"
        Write-Output "Shortcuts were created in the Start menu; pin them manually if needed."
    }
}

New-Item -ItemType Directory -Path $startMenuDir -Force | Out-Null
$shortcutShell = New-Object -ComObject WScript.Shell
$pinFailures = @()
$desktopAppLinks = @()

foreach ($tool in $tools) {
    if (!(Test-Path -LiteralPath $tool.Script)) {
        throw "Missing tool script: $($tool.Script)"
    }

    $scriptPath = (Resolve-Path -LiteralPath $tool.Script).Path
    $shortcutPath = Join-Path $startMenuDir "$($tool.Name).lnk"
    $shortcut = $shortcutShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $env:ComSpec
    $shortcut.Arguments = "/c `"$scriptPath`""
    $shortcut.WorkingDirectory = Split-Path -Parent $scriptPath
    $shortcut.Save()

    $desktopAppLinks += "%APPDATA%\Microsoft\Windows\Start Menu\Programs\win\$($tool.Name).lnk"

    if (Invoke-PinToStart -ShortcutPath $shortcutPath) {
        Write-Output "Pinned: $shortcutPath"
    } else {
        Write-Output "Created shortcut, but Windows did not expose Pin to Start: $shortcutPath"
        $pinFailures += $shortcutPath
    }
}

if ($pinFailures.Count -gt 0 -and [Environment]::OSVersion.Version.Build -ge 22000) {
    Set-StartPinsPolicy -DesktopAppLinks $desktopAppLinks
}
