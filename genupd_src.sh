#!/bin/bash

cvs status . 2>&1 | grep Status: | grep -v Up- | while read line
do
    file=`echo $line | awk '{print $2}'`
    path=`find . -name $file | head -n 1 | cut -d'.' -f2-`
    fullpath=`pwd`$path 
    truncpath=`echo $fullpath | cut -d'/' -f5-`
    echo "$truncpath"
done
