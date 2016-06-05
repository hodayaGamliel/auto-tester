#!/bin/bash

for i in `seq 1 100`;
do
	echo $i
	$@ -jar loop-exec.jar
done
