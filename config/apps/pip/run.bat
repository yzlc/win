@echo off
cd /d "%~dp0"
copy /Y ".condarc" "%USERPROFILE%\" >nul
if errorlevel 1 exit /b %ERRORLEVEL%
if not exist "%USERPROFILE%\pip" mkdir "%USERPROFILE%\pip"
if errorlevel 1 exit /b %ERRORLEVEL%
copy /Y "pip.ini" "%USERPROFILE%\pip\" >nul
exit /b %ERRORLEVEL%
