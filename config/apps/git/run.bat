@echo off
cd /d "%~dp0"
copy /Y ".gitignore" "%USERPROFILE%\" >nul

git config --global user.name "lim"
git config --global user.email yzlc233@outlook.com

git config --global pull.rebase false

git config --global --unset-all https.sslVerify 2>nul
git config --global http.sslVerify true

git config --global core.excludesfile %USERPROFILE%/.gitignore
git config --global --unset-all credential.helper 2>nul
git config --global credential.helper manager

git config --global http.https://github.com.proxy http://127.0.0.1:10808
git config --global https.https://github.com.proxy https://127.0.0.1:10808

exit /b %ERRORLEVEL%
