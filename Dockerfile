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
    apt-get install -y --no-install-recommends \
      policykit-1-gnome && \
    apt-get install -y --no-install-recommends \
      dbus-x11 \
      kali-desktop-lxde \
      lxlauncher \
      lxmenu-data \
      lxtask \
      procps \
      psmisc \
      software-properties-common apt-transport-https wget gpg \
      mesa-utils mesa-utils-extra libxv1 

RUN pkill -9 gpg-agent && \
    source <(gpg-agent --daemon) && \
    wget -q https://packages.microsoft.com/keys/microsoft.asc && \
    apt-key add microsoft.asc && \
    add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    # this first line is for autorecon
      seclists curl enum4linux feroxbuster impacket-scripts nbtscan nikto nmap onesixtyone oscanner redis-tools smbclient smbmap snmp sslscan sipvicious tnscmd10g whatweb wkhtmltopdf \
      python3-venv python3-pip \
    # this one is for pyenv (see https://www.kali.org/docs/general-use/using-eol-python-versions/)
      build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-openssl git \
      code \
      bash-completion \
      vim \
      terminator \
      iputils* \
      kali-tweaks \
      kali-linux-headless \
      kali-tools-top10 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    git clone https://github.com/carlospolop/PEASS-ng.git /opt/PEASS-ng && \
    gunzip /usr/share/wordlists/rockyou.txt.gz

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
