#!/bin/bash

### This secript requires Docker, wget, and dos2unix

### Download and build Dockerfile
wget --no-check-certificate  https://raw.githubusercontent.com/mlmerchant/freedos_bat_runner/main/Dockerfile
docker build . -t freedos-runner


### Create the share folder
mnt=~/mnt
mkdir $mnt


### Populate with the supporting files
# bat file to run in command.com
touch $mnt/input.bat
chmod o+r $mnt/input.bat

### Insert Script here
echo "echo hello from feedos" > $mnt/input.bat
unix2dos $mnt/input.bat

# stdin to start script and optionally enter more stdin.
cat << EOF > $mnt/stdin
c:\mnt\input.bat > c:\mnt\stdout
exit
EOF
chmod o+r $mnt/stdin
unix2dos $mnt/stdin


### Run the container
docker run -v $mnt:/app/dos/mnt freedos-runner

echo "Contents of STDOUT:"
cat $mnt/STDOUT
