# x11docker/lxde
# 
# Run LXDE desktop in docker. 
# Use x11docker to run image. 
# Get x11docker from github: 
#   https://github.com/mviereck/x11docker 
#
# Examples: 
#  - Run desktop:
#      x11docker --desktop x11docker/lxde
#  - Run single application:
#      x11docker x11docker/lxde pcmanfm
#
# Options:
# Persistent home folder stored on host with   --home
# Shared host folder with                      --sharedir DIR
# Hardware acceleration with option            --gpu
# Clipboard sharing with option                --clipboard
# Sound support with option                    --alsa
# With pulseaudio in image, sound support with --pulseaudio
# Printer support over CUPS with               --printer
# Webcam support with                          --webcam
#
# See x11docker --help for further options.

FROM kalilinux/kali-last-release:latest

ENV DEBIAN_FRONTEND=noninteractive

# Even the "stable" kali repos often have breakages so we add debian stable as a backstop

RUN echo "deb http://deb.debian.org/debian stable main non-free contrib" >> /etc/apt/sources.list

COPY preferences /etc/apt/preferences

RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-utils

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN apt-get update && \
    apt-get install -y locales locales-all

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      policykit-1-gnome gsettings-desktop-schemas && \
    apt-get install -y --no-install-recommends \
      dbus-x11 \
      lxde \
      lxlauncher \
      lxmenu-data \
      lxtask \
      procps \
      psmisc \
# this stuff is to add the ms repo
      software-properties-common apt-transport-https wget gpg gpg-agent \
# this is just the commented out stuff below because who cares this image is massive lol
      mesa-utils mesa-utils-extra libxv1 \
# this is for image mangement/troublshooting
      xauth gosu

# get the large base stuff out of the way
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      kali-linux-headless \
      kali-tools-top10 \
      kali-desktop-lxde

#neo4j packaged by kali cannot be enabled as a service, this may be redundant in the future
COPY neo4j /etc/apt/preferences.d/neo4j

# misc crap
RUN wget -q https://packages.microsoft.com/keys/microsoft.asc && \
    apt-key add microsoft.asc && \
    add-apt-repository "deb https://packages.microsoft.com/repos/vscode stable main" && \
    rm -f microsoft.asc && \
    wget -q https://debian.neo4j.com/neotechnology.gpg.key && \
    apt-key add neotechnology.gpg.key && \
    add-apt-repository "deb https://debian.neo4j.com stable latest" && \
    rm -f neotechnology.gpg.key && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
# these next 2 lines are for autorecon
      seclists curl enum4linux feroxbuster gobuster impacket-scripts nbtscan nikto nmap onesixtyone oscanner redis-tools smbclient smbmap snmp sslscan sipvicious tnscmd10g whatweb wkhtmltopdf \
      python3-pip \
      code \
      bloodhound \
      golang \
      python2 \
      bash-completion \
      vim \
      terminator \
      iputils* \
      man-db \
      less \
      kali-tweaks && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND=readline

#final configs
RUN echo "HISTFILE=/tmp/.bash_history" >> /etc/skel/.bashrc && \
    echo 'export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\''\\n'\''}history -a; history -c; history -r"' >> /etc/skel/.bashrc && \
    git clone https://github.com/carlospolop/PEASS-ng.git /opt/PEASS-ng && \
    wget https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh -P /opt/PEASS-ng/linPEAS/ && \
    gunzip /usr/share/wordlists/rockyou.txt.gz && \
    systemctl enable postgresql && \
    service postgresql start && \
    msfdb init && \
# I know this script is messy but it's on debian for making such a crappy package configuration tool    
    wget https://raw.githubusercontent.com/billyball1517/dockerfile-x11docker-lxde/master/wireshark-expect && \
    chmod +x wireshark-expect && \
    ./wireshark-expect && \
    rm -f ./wireshark-expect && \
    systemctl enable neo4j && \
    service neo4j start && \
    neo4j-admin set-initial-password neo4j && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python2 2 && \
    wget https://bootstrap.pypa.io/pip/2.7/get-pip.py  && \
    python2 get-pip.py && \
    rm -f get-pip.py && \
    python2 -m pip install pyftpdlib && \
    python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git

# OpenGL / MESA
# adds 68 MB to image, disabled
# RUN apt-get install -y mesa-utils mesa-utils-extra libxv1 


# GTK 2 and 3 settings for icons and style, wallpaper
RUN echo '\n\
gtk-theme-name="Raleigh"\n\
gtk-icon-theme-name="nuoveXT2"\n\
' > /etc/skel/.gtkrc-2.0 && \
\
mkdir -p /etc/skel/.config/gtk-3.0 && \
echo '\n\
[Settings]\n\
gtk-theme-name="Raleigh"\n\
gtk-icon-theme-name="nuoveXT2"\n\
' > /etc/skel/.config/gtk-3.0/settings.ini && \
\
mkdir -p /etc/skel/.config/pcmanfm/LXDE && \
echo '\n\
[*]\n\
wallpaper_mode=stretch\n\
wallpaper_common=1\n\
wallpaper=/usr/share/lxde/wallpapers/lxde_blue.jpg\n\
' > /etc/skel/.config/pcmanfm/LXDE/desktop-items-0.conf && \
\
mkdir -p /etc/skel/.config/libfm && \
echo '\n\
[config]\n\
quick_exec=1\n\
terminal=lxterminal\n\
' > /etc/skel/.config/libfm/libfm.conf && \
\
mkdir -p /etc/skel/.config/openbox/ && \
echo '<?xml version="1.0" encoding="UTF-8"?>\n\
<theme>\n\
  <name>Clearlooks</name>\n\
</theme>\n\
' > /etc/skel/.config/openbox/lxde-rc.xml && \
\
mkdir -p /etc/skel/.config/ && \
echo '[Added Associations]\n\
text/plain=mousepad.desktop;\n\
' > /etc/skel/.config/mimeapps.list

RUN echo "#! /bin/bash\n\
echo 'x11docker/lxde: If the panel does not show an approbate menu\n\
  and you encounter high CPU usage (seen with kata-runtime),\n\
  please run with option --init=systemd.\n\
' >&2 \n\
startlxde\n\
" >/usr/local/bin/start && chmod +x /usr/local/bin/start

CMD ["/usr/local/bin/start"]
