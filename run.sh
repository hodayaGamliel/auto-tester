#!/bin/bash

# ======
# Usage:
# ======
# you should run this command in an administrator command prompt, using the following command: 
# 	./run.sh | tee tester.log
# this would save the output to tester.log and print it to the command prompt
#
# Os OSX:
# make sure that you have installed takipi on this machine before and that the jdk that is used with 
# takipi is patched (as the installation does)
#
# ====== Configuration Variables ======

declare -r CONSTANT_SECRET_KEY=$1

declare -r TAKIPI_USERNAME=moshe.baavur@takipi.com
declare -r TAKIPI_PASSWORD=123456
declare -r GIT_PATH=$SPARKTALE_SOURCE

if [[ $OSTYPE == darwin* ]]; then
	# OSX
	declare -r OS=osx
	declare -r AGENT_PARAM=-agentpath:/Volumes/GLOBAL/Git/takipi-dev/takipi/client-native/NativeAgent/build/Debug/libTakipiAgent.dylib
	declare -r TAKIPI_INSTALL_PACKAGE=~/Downloads/Takipi.dmg

	declare -r JVMS=(
		'/Library/Java/JavaVirtualMachines/jdk1.7.0_60.jdk/Contents/Home/bin/java'
		'/Library/Java/JavaVirtualMachines/jdk1.8.0_60.jdk/Contents/Home/bin/java'
	)

	declare -r JCompilers=(
		'/Library/Java/JavaVirtualMachines/jdk1.7.0_60.jdk/Contents/Home/bin/javac'
		'/Library/Java/JavaVirtualMachines/jdk1.8.0_60.jdk/Contents/Home/bin/javac'
	)

	declare -r Titles=(
		'Oracle-7u60'
		'Oracle-8u60'
	)

	declare -r MemoryParams=(
		'-XX:MaxPermSize=512K'
		'-XX:MaxMetaspaceSize=7M'
	)

	declare -r TAKIPI_PATH=/Library/Takipi
	declare -r STOP_SERVICE_COMMAND="launchctl unload /Library/LaunchDaemons/com.takipi.service.plist"

	function install_takipi()
	{
		declare -r SK=$1

		# all the needed configuration files
		echo -n $SK > "/tmp/takipi-skf"
		echo -n `cd "${JVMS[0]%????}../jre/lib/server/" ; pwd`/libjvm.dylib > "/tmp/takipi-jlf"
		echo -n `id -F` > "/tmp/takipi-un"
		echo -n "" > "/tmp/takipi-dtp"
		echo -n "" > "/tmp/takipi-prxh"
		echo -n "" > "/tmp/takipi-prxp"

		HDIUTIL_OUTPUT=`hdiutil attach $TAKIPI_INSTALL_PACKAGE | grep "Apple_HFS"`
		SPLITTED_OUTPUT=`echo ${HDIUTIL_OUTPUT//Apple_HFS/;} | tr ';' '\n'`

		MOUNT_POINT=""
		MOUNTED_PARTITION=""

		while read -r line; do
			if [[ -z "$MOUNTED_PARTITION" ]]; then
				MOUNTED_PARTITION=`echo "$line"`
			elif [[ -z "$MOUNT_POINT" ]]; then
				MOUNT_POINT=`echo "$line"`
			else
				echo "Failed to mount Takipi.dmg (too many parts)"
				echo "HDIUTIL_OUTPUT = $HDIUTIL_OUTPUT"
				echo "SPLITTED_OUTPUT = $SPLITTED_OUTPUT"
				echo "MOUNT_POINT = $MOUNT_POINT"
				echo "MOUNTED_PARTITION = $MOUNTED_PARTITION"
				exit 1
			fi
		done <<< "$SPLITTED_OUTPUT"

		if [[ -z "$MOUNTED_PARTITION" ]]; then
			echo "Failed to mount Takipi.dmg"
			echo "HDIUTIL_OUTPUT = $HDIUTIL_OUTPUT"
			echo "SPLITTED_OUTPUT = $SPLITTED_OUTPUT"
			echo "MOUNT_POINT = $MOUNT_POINT"
			echo "MOUNTED_PARTITION = $MOUNTED_PARTITION"
			exit 2
		elif [[ -z "$MOUNT_POINT" ]]; then
			echo "Failed to mount Takipi.dmg"
			echo "HDIUTIL_OUTPUT = $HDIUTIL_OUTPUT"
			echo "SPLITTED_OUTPUT = $SPLITTED_OUTPUT"
			echo "MOUNT_POINT = $MOUNT_POINT"
			echo "MOUNTED_PARTITION = $MOUNTED_PARTITION"
			exit 3
		fi

		sudo installer -store -pkg "$MOUNT_POINT/takipi.pkg" -target /
		hdiutil detach $MOUNTED_PARTITION
	}

	declare -r TIMEOUT_COMMAND="gtimeout"
elif [[ $OSTYPE == *linux* ]]; then
	#Linux
	declare -r OS=linux
	declare -r AGENT_PARAM=-agentpath:/media/GLOBAL/Git/takipi-dev/takipi/client-native/LinuxProjects/NativeAgent/Debug/libTakipiAgent.so

	declare -r JVMS=(
		# '/usr/lib/jvm/java-6-openjdk-amd64/bin/java'
		'/usr/lib/jvm/java-7-openjdk-amd64/bin/java'
		# '/usr/lib/jvm/java-8-openjdk-amd64/bin/java'
		# '/usr/lib/jvm/jre1.6.0_24/bin/java'
		# '/usr/lib/jvm/jre1.7.0_45/bin/java'
		# '/usr/lib/jvm/jre1.8.0_60/bin/java'
	)

	declare -r JCompilers=(
		# '/usr/lib/jvm/java-6-openjdk-amd64/bin/javac'
		'/usr/lib/jvm/java-7-openjdk-amd64/bin/javac'
		# '/usr/lib/jvm/java-8-openjdk-amd64/bin/javac'
		# '/usr/lib/jvm/java-6-openjdk-amd64/bin/javac'
		# '/usr/lib/jvm/java-7-openjdk-amd64/bin/javac'
		# '/usr/lib/jvm/java-8-openjdk-amd64/bin/javac'
	)

	declare -r Titles=(
		# 'OpenJDK6'
		'OpenJDK7'
		# 'OpenJDK8'
		# 'Oracle-6u24'
		# 'Oracle-7u45'
		# 'Oracle-8u60'
	)

	declare -r MemoryParams=(
		# '-XX:MaxPermSize=512K'
		'-XX:MaxPermSize=512K'
		# '-XX:MaxMetaspaceSize=7M'
		# '-XX:MaxPermSize=512K'
		# '-XX:MaxPermSize=512K'
		# '-XX:MaxMetaspaceSize=7M'
	)

	declare -r TAKIPI_PATH=/opt/takipi
	declare -r STOP_SERVICE_COMMAND="service takipi stop"

	function install_takipi()
	{
		declare -r SK=$1

		sudo wget -O - -o /dev/null http://get.takipi.com | sudo bash /dev/stdin -i --sk=$SK
	}

	declare -r TIMEOUT_COMMAND="timeout"
else
	echo "Unknown OS"
	exit 9
fi

declare -r TestsParams=(
	'-XX:+UseCompressedOops'
	# '-XX:-UseCompressedOops'
)

declare -r TestsParamsNames=(
	'CompressedOops'
	# 'NonCompressedOops'
)

# ====== Configuration Variables ======

declare -r LOGS_ROOT_DIR=./Logs-$OS

mkdir -p $LOGS_ROOT_DIR/

declare -r KEYS_FILE=$LOGS_ROOT_DIR/keys.log
declare -r PIDS_FILE=$LOGS_ROOT_DIR/pids.log

# Loop over the options
declare index=0

echo "=========" > $KEYS_FILE
echo "Test Keys" >> $KEYS_FILE
echo "=========" >> $KEYS_FILE

echo "=========" > $PIDS_FILE
echo "Test PIDs" >> $PIDS_FILE
echo "=========" >> $PIDS_FILE

function prepareTakipi()
{
	if [[ -n "$CONSTANT_SECRET_KEY" ]] && [[ $1 -eq 1 ]] ; then
		return 0
	elif [[ -z "$CONSTANT_SECRET_KEY" ]] && [[ $1 -eq 0 ]] ; then
		return 0
	fi

	if [ -f $TAKIPI_PATH/work/secret.key ]; then
		echo "	Uninstalling service..."
		sudo $TAKIPI_PATH/etc/uninstall.sh
	fi

	declare SECRET_KEY=""

	if [[ -n "$CONSTANT_SECRET_KEY" ]]; then
		SECRET_KEY=$CONSTANT_SECRET_KEY
		echo "	Using: $SECRET_KEY"
	else
		echo "	Generating new service key..."
		SECRET_KEY=$(java -jar ./tools/keygen-1.1.0-jar-with-dependencies.jar $TAKIPI_USERNAME $TAKIPI_PASSWORD)
		# exit if we failed to generate new secret key
		if [ $? -ne 0 ]; then
			echo "	Failed to retrieve new secret key!"
			exit 1
		fi

		echo "	Generated: $SECRET_KEY"
	fi

	echo ""
	echo "${Titles[index]} (${TestsParamsNames[paramsIndex]}) => $SECRET_KEY" >> $KEYS_FILE
	echo "	Saved to: $KEYS_FILE"
	echo ""

	echo "	Installing service..."
	install_takipi $SECRET_KEY
	echo ""
	sleep 20
}

function stopTakipi()
{
	if [[ -n "$CONSTANT_SECRET_KEY" ]]; then
		return 0
	fi

	echo "	Stopping service..."
	sudo $STOP_SERVICE_COMMAND
}

prepareTakipi 0

while [ "x${JVMS[index]}" != "x" ]
do
	declare paramsIndex=0

	while  [ "x${TestsParams[paramsIndex]}" != "x" ]
	do
		echo "================================================="
		echo "  Testing ${Titles[index]} (${TestsParamsNames[paramsIndex]})"
		echo "================================================="
		echo ""

		declare LOGS_DIR=$LOGS_ROOT_DIR/${Titles[index]}/${TestsParamsNames[paramsIndex]}
		mkdir -p $LOGS_DIR
		
		prepareTakipi 1

		echo "	Running tests..."
		declare pids=()

		# Run the jar tests first
		for jarFile in testers/*.jar; do
			baseJar=$(basename $jarFile)

			if [[ "$baseJar" == unload* ]]; then
				# unload runs differently from the other tests, so handle it properly
				$TIMEOUT_COMMAND -k 1m 5m ${JVMS[index]} $AGENT_PARAM ${TestsParams[paramsIndex]} -XX:+TraceClassUnloading ${MemoryParams[index]} -jar $jarFile ${JCompilers[index]} > $LOGS_DIR/agent-${baseJar%.*}.log 2>&1 &
			else
				$TIMEOUT_COMMAND -k 1m 5m ${JVMS[index]} $AGENT_PARAM ${TestsParams[paramsIndex]} -jar $jarFile > $LOGS_DIR/agent-${baseJar%.*}.log 2>&1 &
			fi
			declare childPid=$!
			echo "$childPid => $jarFile" >> $PIDS_FILE
			pids+=($childPid)
			sleep 3
		done

		# Run the bash tests
		for bashFile in testers/*.sh; do
			baseBash=$(basename $bashFile)
			$TIMEOUT_COMMAND -k 1m 5m $bashFile ${JVMS[index]} $AGENT_PARAM ${TestsParams[paramsIndex]} > $LOGS_DIR/agent-${baseBash%.*}.log 2>&1 &
			declare childPid=$!
			echo "$childPid => $bashFile" >> $PIDS_FILE
			pids+=($childPid)
			sleep 3
		done

		# Run the Xmen tests
		for bashFile in $GIT_PATH/tests/david/xmen/bin/*.sh; do
			baseBash=$(basename $bashFile)
			$TIMEOUT_COMMAND -k 1m 5m $bashFile ${JVMS[index]} $AGENT_PARAM ${TestsParams[paramsIndex]} > $LOGS_DIR/agent-xmen-${baseBash%.*}.log 2>&1 &
			declare childPid=$!
			echo "$childPid => $bashFile" >> $PIDS_FILE
			pids+=($childPid)
			sleep 3
		done

		wait "${pids[@]}"

		echo "	Waiting for the service to finish processing..."
		sleep 90

		stopTakipi

		mkdir -p $LOGS_DIR/Takipi
		cp -rf $TAKIPI_PATH/log/* $LOGS_DIR/Takipi

		paramsIndex=$(( $paramsIndex + 1 ))
	done

	index=$(( $index + 1 ))
done
