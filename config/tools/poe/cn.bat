@echo off
setlocal

set "source_dir=%USERPROFILE%\Downloads\Bundles2"
set "destination_dir=C:\Program Files\Epic Games\PathOfExile\Bundles2"

if not exist "%source_dir%\" (
    echo Missing source directory: %source_dir%
    exit /b 1
)

if not exist "%destination_dir%\" (
    echo Missing destination directory: %destination_dir%
    exit /b 1
)

if not exist "%destination_dir%\Backup" (
    mkdir "%destination_dir%\Backup"
    if errorlevel 1 exit /b %ERRORLEVEL%
)

for %%F in ("%destination_dir%\*") do (
    if exist "%source_dir%\%%~nxF" (
        move /Y "%%F" "%destination_dir%\Backup\%%~nxF"
        if errorlevel 1 exit /b %ERRORLEVEL%
    )
)

xcopy /Y /I "%source_dir%\*" "%destination_dir%\"
set "RESULT=%ERRORLEVEL%"
if "%RESULT%"=="0" echo 文件替换完成。
exit /b %RESULT%
