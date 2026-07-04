@echo off
cd /d "%~dp0"
if not exist "%USERPROFILE%\.m2" mkdir "%USERPROFILE%\.m2"
if errorlevel 1 exit /b %ERRORLEVEL%
copy /Y "settings.xml" "%USERPROFILE%\.m2\" >nul
exit /b %ERRORLEVEL%
