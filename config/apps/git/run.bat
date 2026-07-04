@echo off
cd /d "%~dp0"
copy /Y ".gitignore" "%USERPROFILE%\" >nul
if errorlevel 1 exit /b %ERRORLEVEL%

git config --global user.name "lim"
if errorlevel 1 exit /b %ERRORLEVEL%
git config --global user.email yzlc233@outlook.com
if errorlevel 1 exit /b %ERRORLEVEL%

git config --global pull.rebase false
if errorlevel 1 exit /b %ERRORLEVEL%

git config --global --unset-all https.sslVerify 2>nul
git config --global http.sslVerify true
if errorlevel 1 exit /b %ERRORLEVEL%

git config --global core.excludesfile %USERPROFILE%/.gitignore
if errorlevel 1 exit /b %ERRORLEVEL%
git config --global --unset-all credential.helper 2>nul
git config --global credential.helper manager
if errorlevel 1 exit /b %ERRORLEVEL%

git config --global http.https://github.com.proxy http://127.0.0.1:10808
if errorlevel 1 exit /b %ERRORLEVEL%
git config --global https.https://github.com.proxy https://127.0.0.1:10808

exit /b %ERRORLEVEL%
