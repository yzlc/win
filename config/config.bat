@echo off
setlocal

cd /d "%~dp0"
set "FAILED=0"

for /r "%~dp0" %%i in (run.bat) do (
    echo Running %%i
    cmd /c ""%%i""
    if errorlevel 1 (
        echo Failed: %%i
        set "FAILED=1"
    )
)

if "%FAILED%"=="1" (
    echo One or more config scripts failed.
    exit /b 1
)

echo All config scripts finished.
exit /b 0
