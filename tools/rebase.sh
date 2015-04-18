#!/bin/bash

LOCATION="$HOME/gitclone"

GENERIC='git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git'
UBUNTU1404='git://kernel.ubuntu.com/ubuntu/ubuntu-trusty.git'
UBUNTU1410='git://kernel.ubuntu.com/ubuntu/ubuntu-utopic.git'
UBUNTU1504='git://kernel.ubuntu.com/ubuntu/ubuntu-vivid.git'

starting_dir="$(pwd)"

die ()
{
    echo "[DIE]: $1" 2>&1
    exit 1
}

is_generic ()
{
    echo "$1" | grep "generic" >/dev/null 2>&1
}

is_ubuntu ()
{
    echo "$1" | grep "ubuntu" >/dev/null 2>&1
}

tag ()
{
    if $(is_generic $1); then
        if $(echo "$1" | grep "4\.0" >/dev/null 2>&1); then
            echo "$(git tag | grep "v4\.0" | sort -n | ~/extract.rb)"
            return
        elif $(echo "$1" | grep "3\.19\." >/dev/null 2>&1); then
            echo "$(git tag | grep "v3\.19" | sort -n | ~/extract.rb)"
            return
        elif $(echo "$1" | grep "3\.18\." >/dev/null 2>&1); then
            echo "$(git tag | grep "v3\.18" | sort -n | ~/extract.rb)"
            return
        elif $(echo "$1" | grep "3\.17\." >/dev/null 2>&1); then
            echo "$(git tag | grep "v3\.17" | sort -n | ~/extract.rb)"
            return
        fi
    elif $(is_ubuntu $1); then
        if $(echo "$1" | grep "14.04" >/dev/null 2>&1); then
            echo "$(git tag | grep Ubuntu-3.13 | sort -n | ~/extract.rb)"
            return
        elif $(echo "$1" | grep "14.10" >/dev/null 2>&1); then
            echo "$(git tag | grep Ubuntu-3.16 | sort -n | ~/extract.rb)"
            return
        elif $(echo "$1" | grep "15.04" >/dev/null 2>&1); then
            echo "$(git tag | grep Ubuntu-3.19 | sort -n | ~/extract.rb)"
            return
        fi
    fi
    die "unknown tag for \"$1\""
}

repo_dir ()
{
    echo $1 | sed -e 's/.*\///g' | sed -e 's/\.git//g'
}

[ -f "regd.c" ] || die "Need to start script from root of dir"

[ -n "$1" ] || die "Need branch to rebase specified"

[ -f "tools/extract.rb" ] && cp tools/extract.rb $HOME/

mkdir -p "$LOCATION"
cd $LOCATION

if [ "$1" = "ubuntu-14.04" ]; then
    remote="$UBUNTU1404"
elif [ "$1" = "ubuntu-14.10" ]; then
    remote="$UBUNTU1410"
elif [ "$1" = "ubuntu-15.04" ]; then
    remote="$UBUNTU1504"
elif [[ $1 =~ generic ]]; then
    remote="$GENERIC"
fi

[ -n "$remote" ] || die "Uunsupported branch \"$1\""

[ -d "$(repo_dir $remote)" ] || git clone "$remote"
[ -d "$(repo_dir $remote)" ] || die "could not clone $remote and the dir does not exist"

cd "$(repo_dir $remote)"
git checkout --force master
git pull --rebase || die "Problem running git pull"
echo "Tag in use is $(tag $1)"
git checkout --force "$(tag $1)" || die "Problem checking out $(tag $1)"
temp="$(pwd)"
cd "$starting_dir"
git checkout --force "$1"
cd "$temp"
cp -r drivers/net/wireless/rtlwifi/* "${starting_dir}/"

cd "$starting_dir"

git checkout Kconfig
find . -name "Makefile" | xargs git checkout -f
~/bin/fixParens.py *.[ch] **/*.[ch]
./tools/addNameToCommentHeader.py *.[ch] **/*.[ch]

echo "Ok, ready for manual merging"
