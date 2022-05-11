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

RUN dpkg --add-architecture i386 && \
    wget -nc https://dl.winehq.org/wine-builds/winehq.key && \
    apt-key add winehq.key && \
    rm -f winehq.key && \
    echo 'deb https://dl.winehq.org/wine-builds/debian/ testing main' > /etc/apt/sources.list.d/winehq.list && \
    apt update && \
    apt install -y --install-recommends winehq-stable && \
    wget  https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -P /usr/local/bin && \
    chmod +x /usr/local/bin/winetricks && \
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
      powershell \
      bash-completion \
      vim \
      terminator \
      iputils* \
      man-db \
      less \
      freerdp2-x11 \
      acl \
      nishang \
      odat \
      fcrackzip \
      gcc-multilib \
      mingw-w64 \
      proxychains \
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
    echo 'setfacl -Rm u:$(id -u):rwx $HOME/results 2> /dev/null' >> /etc/skel/.bashrc && \
    echo 'setfacl -Rm g:$(id -g):rwx $HOME/results 2> /dev/null' >> /etc/skel/.bashrc && \
    echo 'setfacl -Rdm u:$(id -u):rwx $HOME/results 2> /dev/null' >> /etc/skel/.bashrc && \
    echo 'setfacl -Rdm g:$(id -g):rwx $HOME/results 2> /dev/null' >> /etc/skel/.bashrc && \
    mkdir /etc/skel/.BurpSuite && \
    touch /etc/skel/.BurpSuite/burpbrowser && \
    code --extensions-dir /etc/skel/.vscode/extensions --install-extension ms-python.python --user-data-dir /tmp/ && \
    code --extensions-dir /etc/skel/.vscode/extensions --install-extension ms-vscode.PowerShell --user-data-dir /tmp/ && \
    code --extensions-dir /etc/skel/.vscode/extensions --install-extension ms-vscode.cpptools-extension-pack --user-data-dir /tmp/ && \
    code --extensions-dir /etc/skel/.vscode/extensions --install-extension golang.go --user-data-dir /tmp/ && \
    code --extensions-dir /etc/skel/.vscode/extensions --install-extension iliazeus.vscode-ansi  --user-data-dir /tmp/ && \
    code --extensions-dir /etc/skel/.vscode/extensions --install-extension tomoki1207.pdf --user-data-dir /tmp/ && \
    code --extensions-dir /etc/skel/.vscode/extensions --install-extension robertz.code-snapshot --user-data-dir /tmp/ && \
    mkdir -p /etc/skel/.config/i3 && \
    mkdir -p /etc/skel/.config/terminator && \
    cp /etc/i3/config /etc/skel/.config/i3/config && \
    sed -i "s/bindsym Mod1+Return exec i3-sensible-terminal/bindsym Mod1+Return exec --no-startup-id i3-sensible-terminal/g" /etc/skel/.config/i3/config && \
    sed -i '$d' /etc/skel/.config/i3/config && \
    echo 'for_window [class=".*"] border pixel 0' >>  /etc/skel/.config/i3/config && \
    echo 'gaps inner 10' >>  /etc/skel/.config/i3/config && \
    echo 'gaps outer 10' >>  /etc/skel/.config/i3/config && \
    echo 'exec --no-startup-id feh --bg-fill /etc/alternatives/desktop-background' >>  /etc/skel/.config/i3/config && \
    echo 'exec_always --no-startup-id xrandr' >>  /etc/skel/.config/i3/config && \
    echo 'exec_always --no-startup-id xrdb -merge ~/.Xresources' >>  /etc/skel/.config/i3/config && \
    mkdir /etc/skel/results && \
    chmod g+rwx /etc/skel/results && \
    chmod g+s /etc/skel/results && \
    sed -i '$d' /etc/proxychains.conf && \
    sed -i '$d' /etc/proxychains.conf && \
    echo 'socks5 127.0.0.1 1080' >> /etc/proxychains.conf && \
    git clone https://github.com/itm4n/PrivescCheck.git /opt/PrivescCheck && \
    git clone https://github.com/carlospolop/PEASS-ng.git /opt/PEASS-ng && \
    git clone https://github.com/61106960/adPEAS.git /opt/PEASS-ng/adPEAS && \
    git clone https://github.com/jondonas/linux-exploit-suggester-2.git /opt/linux-exploit-suggester-2 && \
    git clone https://github.com/3ndG4me/AutoBlue-MS17-010.git /opt/AutoBlue-MS17-010 && \
    git -C /opt/AutoBlue-MS17-010/ checkout 160df2c && \
    wget https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh -P /opt/PEASS-ng/linPEAS/ && \
    wget https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASany.exe -P /opt/PEASS-ng/winPEAS/ && \
    mkdir /opt/chisel && \
    curl -s https://api.github.com/repos/jpillora/chisel/releases/latest | grep -E '*browser' | grep -E '*_windows_386.gz' | cut -d : -f 2,3 | tr -d \" | wget -i - -O /opt/chisel/chisel_windows_386.exe.gz && \
    curl -s https://api.github.com/repos/jpillora/chisel/releases/latest | grep -E '*browser' | grep -E '*_windows_amd64.gz' | cut -d : -f 2,3 | tr -d \" | wget -i - -O /opt/chisel/chisel_windows_amd64.exe.gz && \
    curl -s https://api.github.com/repos/jpillora/chisel/releases/latest | grep -E '*browser' | grep -E '*_linux_386.gz' | cut -d : -f 2,3 | tr -d \" | wget -i - -O /opt/chisel/chisel_linux_386.elf.gz && \
    curl -s https://api.github.com/repos/jpillora/chisel/releases/latest | grep -E '*browser' | grep -E '*_linux_amd64.gz' | cut -d : -f 2,3 | tr -d \" | wget -i - -O /opt/chisel/chisel_linux_amd64.elf.gz && \
    gunzip /opt/chisel/* && \
    chmod +x /opt/chisel/* && \
    wget https://live.sysinternals.com/PsExec.exe -P /usr/share/windows-resources/binaries/ && \
    wget https://web.archive.org/web/20080530012252/http://live.sysinternals.com/accesschk.exe -P /usr/share/windows-resources/binaries/ && \
    wget https://github.com/Re4son/Churrasco/raw/master/churrasco.exe -P /usr/share/windows-resources/binaries/ && \
    wget https://github.com/itm4n/PrintSpoofer/releases/latest/download/PrintSpoofer32.exe -P /usr/share/windows-resources/binaries/ && \
    wget https://github.com/itm4n/PrintSpoofer/releases/latest/download/PrintSpoofer64.exe -P /usr/share/windows-resources/binaries/ && \
    wget https://github.com/ivanitlearning/Juicy-Potato-x86/releases/latest/download/Juicy.Potato.x86.exe -O /usr/share/windows-resources/binaries/JuicyPotato32.exe && \
    wget https://github.com/ohpe/juicy-potato/releases/latest/download/JuicyPotato.exe -O /usr/share/windows-resources/binaries/JuicyPotato64.exe && \
    wget https://github.com/antonioCoco/RoguePotato/releases/latest/download/RoguePotato.zip -P /usr/share/windows-resources/binaries/ && \
    unzip /usr/share/windows-resources/binaries/RoguePotato.zip -d /usr/share/windows-resources/binaries/ && \
    rm -f /usr/share/windows-resources/binaries/RogueOxidResolver.exe && \
    rm -f /usr/share/windows-resources/binaries/RoguePotato.zip && \
    rm -f /usr/share/windows-resources/binaries/plink.exe && \
    wget https://the.earth.li/~sgtatham/putty/latest/w32/plink.exe -P  /usr/share/windows-resources/binaries/ && \
    rm -rf /usr/share/windows-resources/mimikatz/* && \
    wget https://github.com/gentilkiwi/mimikatz/files/4167347/mimikatz_trunk.zip && \
    unzip mimikatz_trunk.zip -d /usr/share/windows-resources/mimikatz/ && \
    rm -f mimikatz_trunk.zip && \
    chmod +x /usr/share/windows-resources/binaries/* && \
    gunzip /usr/share/wordlists/rockyou.txt.gz && \
    systemctl enable postgresql && \
    service postgresql start && \
    msfdb init && \
    wpscan --update --verbose && \
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
    python2 -m pip install pyftpdlib impacket && \
    python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git git+https://github.com/bitsadmin/wesng.git && \
    gem install evil-winrm && \
    updatedb

COPY terminatorconfig /etc/skel/.config/terminator/config

COPY Xresources /etc/skel/.Xresources

COPY i3status.conf /etc/i3status.conf

RUN useradd -u 9001 -G wireshark -m -s /bin/bash kali && \
    echo 'kali ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/kali

RUN echo '#! /bin/bash\n\
i3\n\
echo password | passwd --stdin kali \n\
'>/usr/local/bin/start && chmod +x /usr/local/bin/start

USER kali

CMD ["/usr/local/bin/start"]
