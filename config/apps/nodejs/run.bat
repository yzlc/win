@echo off
cd /d "%~dp0"
copy /Y ".npmrc" "%USERPROFILE%\" >nul
exit /b %ERRORLEVEL%
