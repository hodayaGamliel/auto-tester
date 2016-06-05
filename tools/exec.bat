@echo off

setlocal EnableDelayedExpansion

set OUT_FILE=%~1
for /f "tokens=1,* delims= " %%a in ("%*") do set ALL_BUT_FIRST=%%b
set ALL_BUT_FIRST=!ALL_BUT_FIRST:%~2=!
set ALL_BUT_FIRST=!ALL_BUT_FIRST:""=!
echo Running: "%~2" !ALL_BUT_FIRST!
echo Saving into: %OUT_FILE%
"%~2"!ALL_BUT_FIRST! > %OUT_FILE% 2>&1
