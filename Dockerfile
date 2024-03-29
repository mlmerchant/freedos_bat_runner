# # Provide volume mount to /app/dos/mnt with stdin + input.bat + out.txt
#
# # batch file to run
# chmod o+r /path/on/host/input.bat
# 
# # stdin to start script and optionally enter more stdin.
# cat << EOF > /path/on/host/stdin
# c:\mnt\input.bat > c:\mnt\output.txt
# exit
# EOF
# chmod o+r /path/on/host/stdin
#
# touch /path/on/host/out.txt
# chmod o+w /path/on/host/out.txt
# sudo chattr +a /path/on/host/out.txt


# First stage
FROM ubuntu:latest as ubuntu-base

USER root
WORKDIR /root

# Install things needed for container setup
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends wget unzip p7zip-full dosbox \
    && export SDL_VIDEODRIVER="dummy" \
    && timeout 5 dosbox; [ -d ~/.dosbox/ ] \
    && DOSBOX_CONFIG=$(ls ~/.dosbox/) \
    && cd .dosbox \
    && mv $DOSBOX_CONFIG /root/dosbox.conf \
    && DOSBOX_CONFIG=/root/dosbox.conf \
    # Here fix the dosbox configurations for headless.
    && sed -i 's/^windowresolution=.*$/windowresolution=none/; s/^output=.*$/output=none/; s/^autolock=.*$/autolock=false/; s/^nosound=.*$/nosound=true/' $DOSBOX_CONFIG \
    # Here insert the dosbox autoexec script.
    && echo "mount c /app/dos" >> $DOSBOX_CONFIG \
    && echo "c:" >> $DOSBOX_CONFIG \
    && echo "command < c:\mnt\stdin" >> $DOSBOX_CONFIG \
    && echo "exit" >> $DOSBOX_CONFIG \
    # Here download and extract command.com from freedos.
    && cd /root \
    && wget --no-check-certificate  https://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/distributions/1.3/official/FD13-LiteUSB.zip \
    && 7z x FD13* \
    && 7z x FD13LITE.img \
    && [ -f ./COMMAND.COM ]

# Second stage: Debian slim as the base image
FROM debian:stable-slim as debian-base

WORKDIR /app

# Need command & dosbox.conf
COPY --from=ubuntu-base /root/dosbox.conf /app/dosbox.conf
COPY --from=ubuntu-base /root/COMMAND.COM /app/dos/COMMAND.COM

ENV SDL_VIDEODRIVER="dummy"

# Install dosbox and other necessary packages
RUN apt update -y \
    && apt upgrade -y \
    && apt install dosbox -y \
    && apt install dos2unix -y \
    # Clean up the apt cache to reduce image size
    && rm -rf /var/lib/apt/lists/* \
    # Create a new user and set up its environment
    && useradd -ms /bin/bash newuser \
    && chown -R newuser:newuser /app

# Switch to the new user
USER newuser

ENTRYPOINT ["dosbox", "-conf", "/app/dosbox.conf"]
