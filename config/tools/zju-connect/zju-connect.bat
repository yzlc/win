@echo off
setlocal

cd /d "%~dp0"

set "SERVER=?"
set "USERNAME=?"
set "PASSWORD=?"

if "%SERVER%"=="?" goto need_config
if "%USERNAME%"=="?" goto need_config
if "%PASSWORD%"=="?" goto need_config

if exist "%~dp0zju-connect.exe" (
    set "EXE=%~dp0zju-connect.exe"
) else (
    where zju-connect.exe >nul 2>nul
    if errorlevel 1 (
        echo Missing zju-connect.exe. Put it next to this script or add it to PATH.
        pause
        exit /b 1
    )
    set "EXE=zju-connect.exe"
)

"%EXE%" --server "%SERVER%" -port 10443 --username "%USERNAME%" --password "%PASSWORD%"
set "RESULT=%ERRORLEVEL%"
pause
exit /b %RESULT%

:need_config
    echo Please edit %~nx0 and set SERVER, USERNAME, and PASSWORD.
    pause
    exit /b 1
