copy .gitignore %USERPROFILE%

git config --global user.name "lim"
git config --global user.email yzlc233@outlook.com

git config --global pull.rebase false

git config --global https.sslVerify false

git config --global core.excludesfile %USERPROFILE%/.gitignore
git config --global credential.helper store

git config --global http.https://github.com.proxy http://127.0.0.1:10808
git config --global https.https://github.com.proxy https://127.0.0.1:10808

exit