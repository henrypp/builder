@echo off

set "APP_NAME=TimeVertor"
set "APP_NAME_SHORT=timevertor"
set "APP_VERSION=1.1"

set "BIN_DIRECTORY=%~dp0..\%APP_NAME_SHORT%\bin"
set "OUT_DIRECTORY=%~dp0bin"
set "TMP_DIRECTORY=%~dp0tmp"
set "NSIS_BIN=%~dp0\nsis\makensis.exe"

rem Cleanup

del /s /f /q "%OUT_DIRECTORY%\*"
del /s /f /q "%TMP_DIRECTORY%\*"

rem Create temporary folder with binaries and documentation...

mkdir "%TMP_DIRECTORY%\32"
mkdir "%TMP_DIRECTORY%\64"

copy /y "%BIN_DIRECTORY%\*.bat" "%TMP_DIRECTORY%\32\*.bat"
copy /y "%BIN_DIRECTORY%\*.reg" "%TMP_DIRECTORY%\32\*.reg"

copy /y "%BIN_DIRECTORY%\*.bat" "%TMP_DIRECTORY%\64\*.bat"
copy /y "%BIN_DIRECTORY%\*.reg" "%TMP_DIRECTORY%\64\*.reg"

if exist "%BIN_DIRECTORY%\i18n" (
	mkdir "%TMP_DIRECTORY%\32\i18n"
	mkdir "%TMP_DIRECTORY%\64\i18n"
	
	copy /y "%BIN_DIRECTORY%\i18n" "%TMP_DIRECTORY%\32\i18n"
	copy /y "%BIN_DIRECTORY%\i18n" "%TMP_DIRECTORY%\64\i18n"
)

if exist "%BIN_DIRECTORY%\32\plugins" (
	mkdir "%TMP_DIRECTORY%\32\plugins"
	mkdir "%TMP_DIRECTORY%\64\plugins"
	
	copy /y "%BIN_DIRECTORY%\32\plugins" "%TMP_DIRECTORY%\32\plugins"
	copy /y "%BIN_DIRECTORY%\64\plugins" "%TMP_DIRECTORY%\64\plugins"
)

copy /y "%BIN_DIRECTORY%\32\%APP_NAME_SHORT%.exe" "%TMP_DIRECTORY%\32\%APP_NAME_SHORT%.exe"
copy /y "%BIN_DIRECTORY%\32\%APP_NAME_SHORT%.scr" "%TMP_DIRECTORY%\32\%APP_NAME_SHORT%.scr"
copy /y "%BIN_DIRECTORY%\64\%APP_NAME_SHORT%.exe" "%TMP_DIRECTORY%\64\%APP_NAME_SHORT%.exe"
copy /y "%BIN_DIRECTORY%\64\%APP_NAME_SHORT%.scr" "%TMP_DIRECTORY%\64\%APP_NAME_SHORT%.scr"

if exist "%BIN_DIRECTORY%\%APP_NAME_SHORT%.ini" (
	copy /y "%BIN_DIRECTORY%\%APP_NAME_SHORT%.ini" "%TMP_DIRECTORY%\32\%APP_NAME_SHORT%.ini"
	copy /y "%BIN_DIRECTORY%\%APP_NAME_SHORT%.ini" "%TMP_DIRECTORY%\64\%APP_NAME_SHORT%.ini"
) else (
	echo. 2>"%TMP_DIRECTORY%\32\%APP_NAME_SHORT%.ini"
	echo. 2>"%TMP_DIRECTORY%\64\%APP_NAME_SHORT%.ini"
)

copy /y "%BIN_DIRECTORY%\Readme.txt" "%TMP_DIRECTORY%\Readme.txt"
copy /y "%BIN_DIRECTORY%\History.txt" "%TMP_DIRECTORY%\History.txt"
copy /y "%BIN_DIRECTORY%\License.txt" "%TMP_DIRECTORY%\License.txt"

rem Pack portable version

7z.exe a -mm=Deflate -mfb=258 -mpass=15 "%OUT_DIRECTORY%\%APP_NAME_SHORT%-%APP_VERSION%-bin.zip" "%TMP_DIRECTORY%\*"

rem Pack installer

if exist "%NSIS_BIN%" (
	rmdir /s /q "%TMP_DIRECTORY%\32\i18n"
	rmdir /s /q "%TMP_DIRECTORY%\64\i18n"
	
	if exist "%BIN_DIRECTORY%\i18n" (
		mkdir "%TMP_DIRECTORY%\i18n"
		copy /y "%BIN_DIRECTORY%\i18n" "%TMP_DIRECTORY%\i18n"
	)
	
	"%NSIS_BIN%" /DAPP_FILES_DIR="%TMP_DIRECTORY%" /DAPP_NAME="%APP_NAME%" /DAPP_NAME_SHORT="%APP_NAME_SHORT%" /DAPP_VERSION="%APP_VERSION%" /X"OutFile %OUT_DIRECTORY%\%APP_NAME_SHORT%-%APP_VERSION%-setup.exe" installer.nsi
)

rem Cleanup

rmdir /s /q "%TMP_DIRECTORY%\32"
rmdir /s /q "%TMP_DIRECTORY%\64"
rmdir /s /q "%TMP_DIRECTORY%\i18n"

del /s /f /q "%TMP_DIRECTORY%\*"

pause