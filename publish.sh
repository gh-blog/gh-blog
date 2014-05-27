#!/bin/bash

username=${1}
dir=${2}
msg=${3}
old_dir=`pwd`

if [ -z "$username" ]; then
    echo 'Please specify a valid GitHub username in the config.coffee file.'
    exit 1;
fi

if [ -z "$dir" ]; then
    dir='dist/production';
fi

if [ -z "$msg" ]; then
    msg="New build at `date`";
fi

gulp --production

cd "$dir"

# # If not initialized
git init
git remote add origin "https://github.com/$username/$username.github.io"

git pull origin master

git add .
git commit -m "$msg"
git push origin master --force

cd "$old_dir"