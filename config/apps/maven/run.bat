@echo off
cd /d "%~dp0"
if not exist "%USERPROFILE%\.m2" mkdir "%USERPROFILE%\.m2"
copy /Y "settings.xml" "%USERPROFILE%\.m2\" >nul
exit /b %ERRORLEVEL%
