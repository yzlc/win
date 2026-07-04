@echo off
cd /d "%~dp0"
if not exist "%APPDATA%\Subversion" mkdir "%APPDATA%\Subversion"
copy /Y "config" "%APPDATA%\Subversion\" >nul
exit /b %ERRORLEVEL%
