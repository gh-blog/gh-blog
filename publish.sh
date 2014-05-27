#!/bin/bash

username=${1}
master=${2}
msg=${3}
src=`pwd`

if [ -z "$username" ]; then
    echo 'Please specify a valid GitHub username in the config.coffee file.'
    exit 1;
fi

if [ -z "$master" ]; then
    master='dist/production';
fi

if [ -z "$msg" ]; then
    msg="New build at `date`";
fi

gulp --production

cd "$master"

init() {
    echo "Initializing Git repository in '$master'..."
    git init

    echo "Adding remote GitHub repository for user '$username'..."
    git remote add origin "https://github.com/$username/$username.github.io"
}

# If not initialized
init;

echo 'Pulling from remote...'
git pull origin master

echo 'Commiting local changes...'
git add .
git commit -m "$msg"

echo 'Pushing commit to remote...'
git push origin master --force

cd "$src"