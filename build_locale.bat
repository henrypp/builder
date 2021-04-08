@echo off

if [%1]==[] (
	echo Usage: build_locale.bat app_name_short app_name
	pause
	exit
)

python ./build_locale.py --name-short=%1
