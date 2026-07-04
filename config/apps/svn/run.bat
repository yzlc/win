@echo off
cd /d "%~dp0"
if not exist "%APPDATA%\Subversion" mkdir "%APPDATA%\Subversion"
if errorlevel 1 exit /b %ERRORLEVEL%
copy /Y "config" "%APPDATA%\Subversion\" >nul
exit /b %ERRORLEVEL%
