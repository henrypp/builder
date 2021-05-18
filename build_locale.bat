@echo off

if [%1]==[] (
	echo Usage: build_locale.bat app_name_short
	pause
	exit
)

python ./build_locale.py --name-short=%1
