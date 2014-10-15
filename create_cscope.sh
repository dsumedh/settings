#!/bin/bash

find `cat ./files` -type f -regex ".*\.\(h\|c\|cpp\|C\)" > cscope.files
sed -i 's/^/\"/g' cscope.files
sed -i 's/$/\"/g' cscope.files
cscope -bq &
