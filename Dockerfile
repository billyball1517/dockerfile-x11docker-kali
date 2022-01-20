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
    apt-get install -y --no-install-recommends apt-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN apt-get update && \
    apt-get install -y locales locales-all && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# get the large base stuff out of the way
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      systemd \
      kali-linux-default && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
# this stuff is to add the 3rd party repos
      software-properties-common apt-transport-https wget gpg gpg-agent \
# this is for gpu support (experimental)
      mesa-utils mesa-utils-extra libxv1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY install-chrome.sh /install-chrome.sh


RUN chmod +x ./install-chrome.sh && \
    ./install-chrome.sh && \
    rm -f ./install-chrome.sh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#install the i3 tiling wm
RUN apt-get update && \
    apt-get install -y \
      feh \
      kali-desktop-i3-gaps && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

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
      freerdp2-x11 \
      kali-tweaks && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND=readline

COPY wireshark-expect /wireshark-expect

#final configs
RUN sed -i "s/PROMPT_ALTERNATIVE=twoline/PROMPT_ALTERNATIVE=oneline/g" /etc/skel/.bashrc && \
    sed -i "s/NEWLINE_BEFORE_PROMPT=yes/NEWLINE_BEFORE_PROMPT=no/g" /etc/skel/.bashrc && \
    echo 'export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\''\\n'\''}history -a; history -c; history -r"' >> /etc/skel/.bashrc && \
    echo 'export GOPATH=$HOME/go' >> /etc/skel/.bashrc && \
    echo 'export PATH=$PATH:$GOPATH/bin' >> /etc/skel/.bashrc && \
    mkdir /etc/skel/.BurpSuite && \
    touch /etc/skel/.BurpSuite/burpbrowser && \
    code --extensions-dir /etc/skel/.vscode/extensions --install-extension iliazeus.vscode-ansi  --user-data-dir /tmp/ && \
    echo 'export PATH=$PATH:$GOPATH/bin' >> /etc/skel/.bashrc && \
    mkdir -p /etc/skel/.config/i3 && \
    mkdir -p /etc/skel/.config/terminator && \
    cp /etc/i3/config /etc/skel/.config/i3/config && \
    sed -i '$d' /etc/skel/.config/i3/config && \
    echo 'for_window [class=".*"] border pixel 0' >>  /etc/skel/.config/i3/config && \
    echo 'gaps inner 10' >>  /etc/skel/.config/i3/config && \
    echo 'gaps outer 10' >>  /etc/skel/.config/i3/config && \
    echo 'exec --no-startup-id feh --bg-scale /etc/alternatives/desktop-background' >>  /etc/skel/.config/i3/config && \
    echo 'exec_always --no-startup-id xrandr' >>  /etc/skel/.config/i3/config && \
    mkdir /etc/skel/results && \
    chmod g+rwx /etc/skel/results && \
    chmod g+s /etc/skel/results && \
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

COPY terminatorconfig /etc/skel/.config/terminator/config

COPY i3status.conf /etc/i3status.conf

RUN useradd -u 9001 -m -G wireshark -s /bin/bash kali

RUN echo "#! /bin/bash\n\
i3\n\
" >/usr/local/bin/start && chmod +x /usr/local/bin/start

CMD ["/usr/local/bin/start"]
