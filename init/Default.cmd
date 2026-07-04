@echo off
echo WARNING: Default.preset changes system privacy, security, services, Windows apps, and UI settings.
echo Review Default.preset before continuing.
choice /C YN /M "Continue"
if errorlevel 2 exit /b 1

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Win10.ps1" -include "%~dp0Win10.psm1" -preset "%~dpn0.preset"
exit /b %ERRORLEVEL%
