@echo off

if [%1]==[] (
	echo Usage: build.bat app_name app_name_short app_version
	pause
	exit
)

set "APP_NAME=%1"
set "APP_NAME_SHORT=%2"
set "APP_VERSION=%3"

set "BIN_DIRECTORY=%~dp0..\%APP_NAME_SHORT%\bin"
set "OUT_DIRECTORY=%UserProfile%\Desktop"
set "TMP_DIRECTORY=%~dp0tmp"

rem Create temporary folder with binaries and documentation...

del /s /f /q "%TMP_DIRECTORY%\*"

mkdir "%TMP_DIRECTORY%\32"
mkdir "%TMP_DIRECTORY%\64"

rem Prepare for git commits

copy /y "%BIN_DIRECTORY%\History.txt" "%BIN_DIRECTORY%\..\CHANGELOG.md"

rem Copy documentation

copy /y "%BIN_DIRECTORY%\Readme.txt" "%TMP_DIRECTORY%\Readme.txt"
copy /y "%BIN_DIRECTORY%\History.txt" "%TMP_DIRECTORY%\History.txt"
copy /y "%BIN_DIRECTORY%\License.txt" "%TMP_DIRECTORY%\License.txt"

rem Copy configuration

if exist "%BIN_DIRECTORY%\%APP_NAME_SHORT%.ini" (
	copy /y "%BIN_DIRECTORY%\%APP_NAME_SHORT%.ini" "%TMP_DIRECTORY%\32\%APP_NAME_SHORT%.ini"
	copy /y "%BIN_DIRECTORY%\%APP_NAME_SHORT%.ini" "%TMP_DIRECTORY%\64\%APP_NAME_SHORT%.ini"
) else (
	echo. 2>"%TMP_DIRECTORY%\32\%APP_NAME_SHORT%.ini"
	echo. 2>"%TMP_DIRECTORY%\64\%APP_NAME_SHORT%.ini"
)

copy /y "%BIN_DIRECTORY%\*.bat" "%TMP_DIRECTORY%\32\*.bat"
copy /y "%BIN_DIRECTORY%\*.reg" "%TMP_DIRECTORY%\32\*.reg"
copy /y "%BIN_DIRECTORY%\*.xml" "%TMP_DIRECTORY%\32\*.xml"

copy /y "%BIN_DIRECTORY%\*.bat" "%TMP_DIRECTORY%\64\*.bat"
copy /y "%BIN_DIRECTORY%\*.reg" "%TMP_DIRECTORY%\64\*.reg"
copy /y "%BIN_DIRECTORY%\*.xml" "%TMP_DIRECTORY%\64\*.xml"

rem Copy localization

if exist "%BIN_DIRECTORY%\i18n" (
	mkdir "%TMP_DIRECTORY%\32\i18n"
	mkdir "%TMP_DIRECTORY%\64\i18n"

	copy /y "%BIN_DIRECTORY%\i18n" "%TMP_DIRECTORY%\32\i18n"
	copy /y "%BIN_DIRECTORY%\i18n" "%TMP_DIRECTORY%\64\i18n"
)

rem Copy plugins

if exist "%BIN_DIRECTORY%\32\plugins" (
	mkdir "%TMP_DIRECTORY%\32\plugins"
	mkdir "%TMP_DIRECTORY%\64\plugins"

	copy /y "%BIN_DIRECTORY%\32\plugins" "%TMP_DIRECTORY%\32\plugins"
	copy /y "%BIN_DIRECTORY%\64\plugins" "%TMP_DIRECTORY%\64\plugins"
)

rem Copy binaries

copy /y "%BIN_DIRECTORY%\32\*.exe" "%TMP_DIRECTORY%\32\*.exe"
copy /y "%BIN_DIRECTORY%\32\*.scr" "%TMP_DIRECTORY%\32\*.scr"
copy /y "%BIN_DIRECTORY%\32\*.dll" "%TMP_DIRECTORY%\32\*.dll"
copy /y "%BIN_DIRECTORY%\64\*.exe" "%TMP_DIRECTORY%\64\*.exe"
copy /y "%BIN_DIRECTORY%\64\*.scr" "%TMP_DIRECTORY%\64\*.scr"
copy /y "%BIN_DIRECTORY%\64\*.dll" "%TMP_DIRECTORY%\64\*.dll"

rem Create portable version

7z.exe a -mm=LZMA -mx=9 -md=64m -mmf=hc4 -mfb=273 "%OUT_DIRECTORY%\%APP_NAME_SHORT%-%APP_VERSION%-bin.zip" "%TMP_DIRECTORY%\*"

rem Create setup version

rmdir /s /q "%TMP_DIRECTORY%\32\i18n"
rmdir /s /q "%TMP_DIRECTORY%\64\i18n"

if exist "%BIN_DIRECTORY%\i18n" (
	mkdir "%TMP_DIRECTORY%\i18n"
	copy /y "%BIN_DIRECTORY%\i18n" "%TMP_DIRECTORY%\i18n"
)

copy /y "%BIN_DIRECTORY%\..\src\res\100.ico" "logo.ico"

makensis.exe /DAPP_FILES_DIR=%TMP_DIRECTORY% /DAPP_NAME=%APP_NAME% /DAPP_NAME_SHORT=%APP_NAME_SHORT% /DAPP_VERSION=%APP_VERSION% /X"OutFile %OUT_DIRECTORY%\%APP_NAME_SHORT%-%APP_VERSION%-setup.exe" installer.nsi

rem Cleanup

rmdir /s /q "%TMP_DIRECTORY%\32"
rmdir /s /q "%TMP_DIRECTORY%\64"
rmdir /s /q "%TMP_DIRECTORY%\i18n"

del /s /f /q "%TMP_DIRECTORY%\*"

del /s /f /q "logo.ico"