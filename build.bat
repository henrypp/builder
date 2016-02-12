@echo off

set "APP_NAME=Mem Reduct"
set "APP_NAME_SHORT=memreduct"
set "APP_VERSION=3.1.1452"

set "BIN_DIRECTORY=%~dp0..\%APP_NAME_SHORT%\bin"
set "OUT_DIRECTORY=%~dp0bin"
set "TMP_DIRECTORY=%~dp0tmp"
set "NSIS_BIN="%~dp0\nsis\makensis.exe""

rem Cleanup

del /s /f /q "%OUT_DIRECTORY%\*"
del /s /f /q "%TMP_DIRECTORY%\*"

rem Create temporary folder with binaries and documentation...

mkdir "%TMP_DIRECTORY%\32\i18n"
mkdir "%TMP_DIRECTORY%\64\i18n"

copy /y "%BIN_DIRECTORY%\i18n" "%TMP_DIRECTORY%\32\i18n"
copy /y "%BIN_DIRECTORY%\i18n" "%TMP_DIRECTORY%\64\i18n"

copy /y "%BIN_DIRECTORY%\32\%APP_NAME_SHORT%.exe" "%TMP_DIRECTORY%\32\%APP_NAME_SHORT%.exe"
copy /y "%BIN_DIRECTORY%\64\%APP_NAME_SHORT%.exe" "%TMP_DIRECTORY%\64\%APP_NAME_SHORT%.exe"

echo. 2>"%TMP_DIRECTORY%\32\%APP_NAME_SHORT%.ini"
echo. 2>"%TMP_DIRECTORY%\64\%APP_NAME_SHORT%.ini"

copy /y "%BIN_DIRECTORY%\Readme.txt" "%TMP_DIRECTORY%\Readme.txt"
copy /y "%BIN_DIRECTORY%\History.txt" "%TMP_DIRECTORY%\History.txt"
copy /y "%BIN_DIRECTORY%\License.txt" "%TMP_DIRECTORY%\License.txt"

rem Pack portable version

7z.exe a -mx9 "%OUT_DIRECTORY%\%APP_NAME_SHORT%-%APP_VERSION%-bin.7z" "%TMP_DIRECTORY%\*"

rem Pack installer

rmdir /s /q "%TMP_DIRECTORY%\32\i18n"
rmdir /s /q "%TMP_DIRECTORY%\64\i18n"

mkdir "%TMP_DIRECTORY%\i18n"
copy /y "%BIN_DIRECTORY%\i18n" "%TMP_DIRECTORY%\i18n"

%NSIS_BIN% /DAPP_FILES_DIR="%TMP_DIRECTORY%" /DAPP_NAME="%APP_NAME%" /DAPP_NAME_SHORT="%APP_NAME_SHORT%" /DAPP_VERSION="%APP_VERSION%" /X"OutFile %OUT_DIRECTORY%\%APP_NAME_SHORT%-%APP_VERSION%-setup.exe" installer.nsi

rem Cleanup

rmdir /s /q "%TMP_DIRECTORY%\32"
rmdir /s /q "%TMP_DIRECTORY%\64"
rmdir /s /q "%TMP_DIRECTORY%\i18n"

del /s /f /q "%TMP_DIRECTORY%\*"

pause