@echo off

for /l %%i in (1,1,100) do (
	echo %%i
	%* -jar loop-exec.jar
)
