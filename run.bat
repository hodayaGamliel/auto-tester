@echo off

REM ======
REM Usage:
REM ======
REM you should run this command in an administrator command prompt, using the following command: 
REM 	run.bat > tester.log | type tester.log
REM this would save the output to tester.log and print it to the command prompt

SetLocal EnableDelayedExpansion

set BASH_DIR=%~dp0
REM to specify a secret key, encapsulate the key with " to prevent the command prompt
REM from concatenating the key due to it containing = signs
set CONSTANT_SECRET_KEY=%~1

REM ====== Configuration Variables ======

set AGENT_PARAM=-agentpath:D:\Git\takipi-dev\takipi\client-native\NativeAgent\DebugWin\TakipiAgent.dll
set TAKIPI_USERNAME=moshe.baavur@takipi.com
set TAKIPI_PASSWORD=123456

REM extract the msi manually - run Takipi.exe, and while the wizard is open,
REM copy %temp%\Takipi.msi to the tools folder
set TAKIPI_MSI=tools\Takipi.msi

REM ====== Configuration Variables ======

set JVMS[0]=c:\Program Files\java\jdk1.6.0_45\bin\java.exe
set JVMS[1]=c:\Program Files\java\jdk1.7.0_60\bin\java.exe
set JVMS[2]=c:\Program Files\java\jdk1.8.0_60\bin\java.exe

set JCompilers[0]=c:\Program Files\java\jdk1.6.0_45\bin\javac.exe
set JCompilers[1]=c:\Program Files\java\jdk1.7.0_60\bin\javac.exe
set JCompilers[2]=c:\Program Files\java\jdk1.8.0_60\bin\javac.exe

set Titles[0]=Oracle-6u45
set Titles[1]=Oracle-7u60
set Titles[2]=Oracle-8u60

set MemoryParams[0]=-XX:MaxPermSize=512K
set MemoryParams[1]=-XX:MaxPermSize=512K
set MemoryParams[2]=-XX:MaxMetaspaceSize=7M

set TestsParams[0]=-XX:+UseCompressedOops
set TestsParams[1]=-XX:-UseCompressedOops

set TestsParamsNames[0]=CompressedOops
set TestsParamsNames[1]=NonCompressedOops

set LOGS_ROOT_DIR=Logs-win

net session >nul 2>&1

if not %errorLevel% == 0 (
	echo Administrator privileges are required to run this program.
	ECHO Please run it in an elevated command prompt.
	exit /b 1
)

if NOT EXIST %LOGS_ROOT_DIR% md %LOGS_ROOT_DIR%

set KEYS_FILE=%LOGS_ROOT_DIR%\keys.log
set PIDS_FILE=%LOGS_ROOT_DIR%\pids.log

echo ========= > %KEYS_FILE%
echo Test Keys >> %KEYS_FILE%
echo ========= >> %KEYS_FILE%

echo ========= > %PIDS_FILE%
echo Test PIDs >> %PIDS_FILE%
echo ========= >> %PIDS_FILE%

call :prepareTakipi 0

for /l %%i in (0,1,2) do (
	for /l %%j in (0,1,1) do (
		echo =================================================
		echo   Testing !Titles[%%i]! (!TestsParamsNames[%%j]!^)
		echo =================================================
		echo.

		set LOGS_DIR=%LOGS_ROOT_DIR%\!Titles[%%i]!\!TestsParamsNames[%%j]!
		if NOT EXIST !LOGS_DIR! md !LOGS_DIR!

		call :prepareTakipi 1

		echo 	Running tests...
		set "pids="

		for %%f in (testers\*.jar) do (
			if %%~nf==unload (
				set EXTRA_PARAMS=-XX:+TraceClassUnloading !MemoryParams[%%i]!
				set PROG_ARGS=!JCompilers[%%i]!
			) else (
				set "EXTRA_PARAMS="
				set "PROG_ARGS="
			)

			for /f "tokens=2 delims=;= " %%a in ('wmic process call create ^'cmd /c ^"cd /d %BASH_DIR% ^& tools\exec.bat !LOGS_DIR!\agent-%%~nf.log ^"!JVMS[%%i]!^" %AGENT_PARAM% !TestsParams[%%j]! !EXTRA_PARAMS! -jar %%f ^"!PROG_ARGS!^" ^" ^' ^| findstr ProcessId') do (
				set pids=!pids! /PID %%a
				echo %%a =^> %%f >> %PIDS_FILE%
			)

			timeout /t 3 /nobreak > NUL
		)

		for %%f in (testers\*.bat) do (
			for /f "tokens=2 delims=;= " %%a in ('wmic process call create ^'cmd /c ^"cd /d %BASH_DIR% ^& tools\exec.bat !LOGS_DIR!\agent-%%~nf.log %%f ^"!JVMS[%%i]!^" %AGENT_PARAM% !TestsParams[%%j]!^" ^' ^| findstr ProcessId') do (
				set pids=!pids! /PID %%a
				echo %%a =^> %%f >> %PIDS_FILE%
			)

			timeout /t 3 /nobreak > NUL
		)

		for %%f in (D:\Git\takipi-dev\tests\david\xmen\bin\*.bat) do (
			for /f "tokens=2 delims=;= " %%a in ('wmic process call create ^'cmd /c ^"cd /d %BASH_DIR% ^& tools\exec.bat !LOGS_DIR!\agent-%%~nf.log %%f ^"!JVMS[%%i]!^" %AGENT_PARAM% !TestsParams[%%j]!^" ^' ^| findstr ProcessId') do (
				set pids=!pids! /PID %%a
				echo %%a =^> %%f >> %PIDS_FILE%
			)

			timeout /t 3 /nobreak > NUL
		)

		REM wait for 5 1/2 minutes
		timeout /t 300 /nobreak > NUL
		taskkill !pids! /T > NUL 2>&1
		timeout /t 60 /nobreak > NUL
		taskkill !pids! /T /F > NUL 2>&1

		echo 	Waiting for the service to finish processing...
		timeout /t 90 /nobreak > NUL

		call :stopTakipi

		if NOT EXIST !LOGS_DIR!\Takipi md !LOGS_DIR!\Takipi
		xcopy /y /q /s C:\Takipi\log\* !LOGS_DIR!\Takipi > NUL 2>&1
	)
)

EndLocal
exit /b 0

:prepareTakipi
	if "%CONSTANT_SECRET_KEY%"=="" (
		if %1 EQU 0 (
			exit /b 0
		)
	) else (
		if %1 EQU 1 (
			exit /b 0
		)
	)

	if EXIST C:\Takipi\work\secret.key (
		echo 	Uninstalling service...
		wmic product where name="Takipi" call uninstall
	)

	if "%CONSTANT_SECRET_KEY%"=="" (
		echo 	Generating new service key...
		set SECRET_KEY_FAILED=0
		set "SECRET_KEY="

		for /f "delims=" %%a in ('java -jar .\tools\keygen-1.1.0-jar-with-dependencies.jar %TAKIPI_USERNAME% %TAKIPI_PASSWORD%') do (
			if "!SECRET_KEY!"=="" (
				set SECRET_KEY=%%a
			) else (
				set SECRET_KEY_FAILED=1
			)
		)
		REM exit if we failed to generate new secret key
		if !SECRET_KEY_FAILED! EQU 1 (
			echo 	Failed to retrieve new secret key!
			exit /b 1
		)

		echo 	Generated: !SECRET_KEY!
		echo.
	) else (
		set SECRET_KEY=%CONSTANT_SECRET_KEY%
		echo 	Using: !SECRET_KEY!
		echo.
	)
	

	echo !Titles[%%i]! (!TestsParamsNames[%%j]!^) =^> !SECRET_KEY! >> %KEYS_FILE%
	echo 	Saved to: %KEYS_FILE%
	echo.

	echo 	Installing service...
	echo.
	start /wait msiexec /i %TAKIPI_MSI% SK=!SECRET_KEY! /quiet
	timeout /t 20 /nobreak > NUL

	exit /b 0

:stopTakipi
	if NOT "%CONSTANT_SECRET_KEY%"=="" (
		exit /b 0
	)

	echo 	Stopping service...
	net stop Takipi

	exit /b 0
