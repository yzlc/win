@echo off
setlocal

where scoop >nul 2>nul
if errorlevel 1 (
    echo Scoop is not available on PATH.
    exit /b 1
)

scoop download v2rayn-desktop
if errorlevel 1 exit /b %ERRORLEVEL%

powershell -NoProfile -ExecutionPolicy Bypass -Command "Stop-Process -Name v2rayN,xray -Force -ErrorAction SilentlyContinue"

scoop update v2rayn-desktop
if errorlevel 1 exit /b %ERRORLEVEL%

powershell -NoProfile -ExecutionPolicy Bypass -Command "$exe = Join-Path $env:USERPROFILE 'scoop\apps\v2rayn-desktop\current\v2rayN.exe'; if (!(Test-Path -LiteralPath $exe)) { throw ('Missing ' + $exe) }; Start-Process -FilePath $exe"
exit /b %ERRORLEVEL%
