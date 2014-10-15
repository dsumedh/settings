#!/bin/bash


BIN=$1
TAGS=$2

IFILE=/tmp/missing.err
GFILE=/tmp/missing.search
SFILE=/tmp/missing.dirs
MFILE=/tmp/missing.syms

if [ -z "$BIN" -o -z "$TAGS" ]; then
    echo "Usage: $0 <bin_name> <tagfile>         ... run this script from the bin dir"
    exit
fi

rm -rf $IFILE $GFILE $SFILE $MFILE

ldd -r ./$BIN 1>/dev/null 2>$IFILE
while read mline
do
    msym=`echo $mline | cut -d':' -f2 | awk '{print $1}'`
    fsym=`c++filt $msym`
    found=0
    csym=`echo $fsym | cut -d'(' -f1`
    csymbase=`echo $csym | awk -F":" '{print $NF}'`
    grep "$csym(" $TAGS > $GFILE
    while read tline
    do
        f1=`echo $tline | awk '{print $1}'`
        f2=`echo $tline | awk '{print $2}'`
        if [ "$f1" ==  "$csymbase" ]; then
            fdir=`dirname $f2`
            fbase=`basename $f2`
            fdirdisp=`echo $fdir | cut -d'/' -f5-`
            echo "Missing: $fsym        FILE: $fbase@$fdirdisp"
            echo "$fbase@$fdir" >> $SFILE
            found=1
        fi
    done < $GFILE
    if [ $found -eq 0 ]; then
#        echo "Missing $fsym     FILE: ?????"
        echo "$fsym" >>  $MFILE
    fi
done < $IFILE
rm -rf $IFILE

cat $MFILE | sort -u > /tmp/tmpfile
mv /tmp/tmpfile $MFILE
echo -e "\nSymbols NOT found in any sources.... :"
cat $MFILE


cat $SFILE | sort -u > /tmp/tmpfile
mv /tmp/tmpfile $SFILE
echo -e "\n\nAll other missing symbols found in... Fix these errors first :"
cat $SFILE


while read line
do
    file=`echo $line | cut -d'@' -f1`
    dir=`echo $line | cut -d'@' -f2`
    
    if [ -f $dir/Makefile.prj ]; then
        while read mline
        do
            echo $mline | grep --quiet "^#"
            if [ $? -eq 0 ]; then
                continue
            fi
            echo $mline | grep --quiet "#SRCS"
            if [ $? -eq 0 ]; then
                continue
            fi
#            echo $mline | grep --quiet "BIN\["
#            if [ $? -eq 0 ]; then
#                curbin=`echo $mline | cut -d'=' -f2`
#            fi
            echo $mline | grep --quiet "SRCS\["
            if [ $? -eq 0 ]; then
                cursrcnum=`echo $mline | cut -d'[' -f2 | cut -d']' -f1`
            fi
            if [ -n "$cursrcnum" ]; then
                echo $mline | grep --quiet $file
                if [ $? -eq 0 ]; then
#                echo "CMD==> cat $dir/Makefile.prj | grep \"BIN\[$cursrcnum\]\" | cut -d'=' -f2"
                    binname=`cat $dir/Makefile.prj | grep "BIN\[$cursrcnum\]" | cut -d'=' -f2`
                    echo "Link against ::: $binname      for [$dir][$file]"
                    break
                fi            
            fi
        done < $dir/Makefile.prj
    else
        echo "$dir does not have Makefile.prj --> manually check what library is built using $file and link against it"
    fi
done < $SFILE
