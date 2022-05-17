@echo off

if [%1]==[] (
	echo Usage: build_simplewall_rules.bat file_path
	pause
	exit
)

python ./src/build_simplewall_rules.py --mode=update --i=%1 --o=%1
