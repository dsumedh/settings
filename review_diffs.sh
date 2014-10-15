#!/bin/bash

PWD=`pwd`
node="`echo $PWD | cut -d'/' -f1-4`/"
for file in `~/genupd_src.sh`;
do
    echo "Viewing Diff for [$node$file]..."
    read
    /usr/bin/vim -c VCSVimDiff -c :1 "$node$file"
done
