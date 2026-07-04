@echo off
set "source_dir=%USERPROFILE%\Downloads\Bundles2"
set "destination_dir=C:\Program Files\Epic Games\PathOfExile\Bundles2"

:: 创建备份文件夹
if not exist "%destination_dir%\Backup" (
    mkdir "%destination_dir%\Backup"
)

:: 备份目标文件夹中的文件
for %%F in ("%destination_dir%\*") do (
    if exist "%source_dir%\%%~nxF" (
        move /Y "%%F" "%destination_dir%\Backup\%%~nxF"
    )
)

:: 将源文件夹中的文件复制到目标文件夹
xcopy /Y "%source_dir%\*" "%destination_dir%"
echo 文件替换完成。