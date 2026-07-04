@echo off
cd /d "%~dp0"
copy /Y ".condarc" "%USERPROFILE%\" >nul
if not exist "%USERPROFILE%\pip" mkdir "%USERPROFILE%\pip"
copy /Y "pip.ini" "%USERPROFILE%\pip\" >nul
exit /b %ERRORLEVEL%
