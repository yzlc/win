@cd/d"%~dp0"&(cacls "%SystemDrive%\System Volume Information" >nul 2>nul)||(start "" mshta vbscript:CreateObject^("Shell.Application"^).ShellExecute^("%~nx0"," %*","","runas",1^)^(window.close^)&exit /b)
:: 客户体验改善计划
sc config whesvc start= demand
sc config DiagTrack start= demand
:: 文件共享
sc config LanmanServer start= demand
:: 打印
sc config Spooler start= demand
:: 局域网UPnP设备
sc config SSDPSRV start= demand
:: 文件链接跟踪
sc config TrkWks start= demand
:: 安全更新提醒
sc config WpnService start= demand
exit /b %ERRORLEVEL%
