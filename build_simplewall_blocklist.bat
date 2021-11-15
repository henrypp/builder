@echo off

if [%1]==[] (
	echo Usage: build_simplewall_blocklist.bat app_name_short
	pause
	exit
)

python ./build_simplewall_blocklist.py --name-short=%1
