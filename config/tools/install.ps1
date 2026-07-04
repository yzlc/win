param(
    [switch]$ApplyStartPinsPolicyOnly,
    [string]$PinsFile
)

$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
$startMenuRoot = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$startMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\win"
$scoopAppsDir = Join-Path $startMenuRoot "Scoop Apps"

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
            return [pscustomobject]@{
                Success = $false
                Reason = "Shell folder was not available."
            }
        }

        $item = $folder.ParseName($leafName)
        if ($null -eq $item) {
            return [pscustomobject]@{
                Success = $false
                Reason = "Shell item was not available."
            }
        }

        $failureReason = $null
        try {
            $item.InvokeVerb("startpin")
            return [pscustomobject]@{
                Success = $true
                Reason = $null
            }
        } catch {
            $failureReason = $_.Exception.Message
        }

        foreach ($verb in @($item.Verbs())) {
            $name = $verb.Name.Replace("&", "").Trim()
            if ($name -match "Pin to Start|固定.*开始") {
                try {
                    $verb.DoIt()
                    return [pscustomobject]@{
                        Success = $true
                        Reason = $null
                    }
                } catch {
                    $failureReason = $_.Exception.Message
                }
            }
        }

        if (!$failureReason) {
            $failureReason = "Windows did not expose Pin to Start."
        }

        return [pscustomobject]@{
            Success = $false
            Reason = $failureReason
        }
    } catch {
        return [pscustomobject]@{
            Success = $false
            Reason = $_.Exception.Message
        }
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
        return [pscustomobject]@{
            Success = $true
            AccessDenied = $false
            Reason = $null
        }
    } catch {
        $accessDenied = $_.Exception -is [System.UnauthorizedAccessException] -or $_.Exception.Message -match "Access.*denied|拒绝访问|权限"
        Write-Output "Could not apply Windows Start pins policy: $($_.Exception.Message)"
        Write-Output "Shortcuts were created in the Start menu; pin them manually if needed."
        return [pscustomobject]@{
            Success = $false
            AccessDenied = $accessDenied
            Reason = $_.Exception.Message
        }
    }
}

function Invoke-ElevatedStartPinsPolicy {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$DesktopAppLinks
    )

    $pinsFile = Join-Path $env:TEMP "win-start-pins-$([Guid]::NewGuid().ToString('N')).json"
    try {
        $DesktopAppLinks | ConvertTo-Json -Compress | Set-Content -LiteralPath $pinsFile -Encoding UTF8
        Write-Output "Start pins policy needs elevation; requesting administrator approval..."

        $arguments = @(
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            "`"$PSCommandPath`"",
            "-ApplyStartPinsPolicyOnly",
            "-PinsFile",
            "`"$pinsFile`""
        )
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs -WindowStyle Hidden -Wait -PassThru
        if ($process.ExitCode -eq 0) {
            Write-Output "Applied Windows Start pins policy with elevation."
            return $true
        }

        Write-Output "Elevated Start pins policy helper failed with exit code $($process.ExitCode)."
        return $false
    } catch {
        Write-Output "Could not request elevation for Start pins policy: $($_.Exception.Message)"
        return $false
    } finally {
        Remove-Item -LiteralPath $pinsFile -Force -ErrorAction SilentlyContinue
    }
}

if ($ApplyStartPinsPolicyOnly) {
    if (!$PinsFile) {
        throw "Missing pins file."
    }

    $desktopAppLinks = @(Get-Content -Raw -LiteralPath $PinsFile | ConvertFrom-Json)
    $result = Set-StartPinsPolicy -DesktopAppLinks $desktopAppLinks
    if ($result.Success) {
        exit 0
    }

    exit 1
}

if (Test-Path -LiteralPath $scoopAppsDir) {
    foreach ($shortcutName in @($legacyShortcutNames + ($tools | ForEach-Object { "$($_.Name).lnk" }))) {
        Remove-Item -LiteralPath (Join-Path $scoopAppsDir $shortcutName) -Force -ErrorAction SilentlyContinue
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
    $shortcut.TargetPath = $scriptPath
    $shortcut.Arguments = ""
    $shortcut.WorkingDirectory = Split-Path -Parent $scriptPath
    $shortcut.Save()

    $desktopAppLinks += "%APPDATA%\Microsoft\Windows\Start Menu\Programs\win\$($tool.Name).lnk"

    $pinResult = Invoke-PinToStart -ShortcutPath $shortcutPath
    if ($pinResult.Success) {
        Write-Output "Requested Start pin: $shortcutPath"
    } else {
        Write-Output "Created shortcut, but could not request Start pin: $shortcutPath"
        Write-Output "Pin reason: $($pinResult.Reason)"
        $pinFailures += $shortcutPath
    }
}

if ([Environment]::OSVersion.Version.Build -ge 22000) {
    $policyResult = Set-StartPinsPolicy -DesktopAppLinks $desktopAppLinks
    if (!$policyResult.Success -and $policyResult.AccessDenied) {
        [void](Invoke-ElevatedStartPinsPolicy -DesktopAppLinks $desktopAppLinks)
    }
}
