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

New-Item -ItemType Directory -Path $startMenuDir -Force | Out-Null
$shortcutShell = New-Object -ComObject WScript.Shell

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

    if (Invoke-PinToStart -ShortcutPath $shortcutPath) {
        Write-Output "Pinned: $shortcutPath"
    } else {
        Write-Output "Created shortcut, but Windows did not expose Pin to Start: $shortcutPath"
    }
}
