cd %~dp0
for /f "delims=" %%i in ('dir run.bat /b /s^|findstr /v /i "config.bat"') do start "" "%%i"