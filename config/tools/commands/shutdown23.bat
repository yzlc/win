@echo off
schtasks /create /f /sc once /tn "Shutdown23" /tr "shutdown /s /f /t 0" /st 23:59
exit /b %ERRORLEVEL%
