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

COPY install-chrome.sh /install-chrome.sh

RUN chmod +x ./install-chrome.sh
    ./install-chrome.sh
    rm -f ./install-chrome.sh

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      policykit-1-gnome gsettings-desktop-schemas && \
    apt-get install -y --no-install-recommends \
      dbus-x11 \
      kali-desktop-lxde \
      lxlauncher \
      lxmenu-data \
      lxtask \
      procps \
      psmisc \
# this stuff is to add the 3rd party repos
      software-properties-common apt-transport-https wget gpg gpg-agent \
# this is for gpu support (experimental)
      mesa-utils mesa-utils-extra libxv1 \
# this is for image mangement/troublshooting
      xauth gosu

# get the large base stuff out of the way
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      kali-linux-default

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

COPY wireshark-expect /wireshark-expect

#final configs
RUN echo 'export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\''\\n'\''}history -a; history -c; history -r"' >> /etc/skel/.bashrc && \
    echo 'export GOPATH=$HOME/go' >> /etc/skel/.bashrc && \
    echo 'export PATH=$PATH:$GOPATH/bin' >> /etc/skel/.bashrc && \
    mkdir /etc/skel/.BurpSuite && \
    touch /etc/skel/.BurpSuite/burpbrowser && \
    echo 'export PATH=$PATH:$GOPATH/bin' >> /etc/skel/.bashrc && \
    git clone https://github.com/carlospolop/PEASS-ng.git /opt/PEASS-ng && \
    wget https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh -P /opt/PEASS-ng/linPEAS/ && \
    gunzip /usr/share/wordlists/rockyou.txt.gz && \
    systemctl enable postgresql && \
    service postgresql start && \
    msfdb init && \
# I know this script is messy but it's on debian for making such a crappy package configuration tool    
    chmod +x ./wireshark-expect && \
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

RUN useradd -u 9001 -m -G wireshark -s /bin/bash kali

RUN echo "#! /bin/bash\n\
echo 'x11docker/lxde: If the panel does not show an approbate menu\n\
  and you encounter high CPU usage (seen with kata-runtime),\n\
  please run with option --init=systemd.\n\
' >&2 \n\
startlxde\n\
" >/usr/local/bin/start && chmod +x /usr/local/bin/start

CMD ["/usr/local/bin/start"]
