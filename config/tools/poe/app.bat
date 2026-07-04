@echo off
chcp 65001 >nul
cd /d "%~dp0"

call :start_if_exists "Path of Exile.url"
call :start_if_exists "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Scoop Apps\Awakened-PoE-Trade.lnk"
call :start_if_exists "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Scoop Apps\PoeCharm.lnk"
call :start_if_exists "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\雷神加速器\雷神加速器.lnk"
call :start_if_exists "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\薄荷加速器\薄荷加速器.lnk"

exit /b 0

:start_if_exists
if exist "%~1" (
    start "" "%~1"
) else (
    echo Missing shortcut: %~1
)
exit /b 0
