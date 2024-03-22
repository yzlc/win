cd %~dp0
Xcopy poe C:\soft\poe\ /E/H/C/I
mklink "app.lnk" "cmd /c app.bat"