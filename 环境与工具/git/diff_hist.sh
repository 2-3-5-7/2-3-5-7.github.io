#!/bin/bash 

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <revision-range> [file]"
    exit
fi

GREEN='\033[0;32m'
NC='\033[0m' # No Color

while read -r id msg
do 
    echo -e "${msg}\n" 
    if [ "$2" ]; then
        git difftool -y ${id}~1 ${id} $2 2>/dev/null
    else
        git difftool --dir-diff ${id}~1 ${id} 2>/dev/null
    fi
done < <(git log --pretty='%C(yellow)%h%Creset %C(green)%cd%Creset %an %C(blue)%d%Creset %s' --date=format:%m-%d $1 $2)
