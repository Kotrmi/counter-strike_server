FROM debian:9

# labels
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/Kotrmi/counter-strike_server"

# default environment variables
ENV PORT=27015
ENV MAP=de_dust2
ENV MAXPLAYERS=16
ENV SV_LAN=0

# install dependencies
RUN printf '%s\n' \
    'deb http://archive.debian.org/debian stretch main contrib non-free' \
    'deb http://archive.debian.org/debian-security stretch/updates main contrib non-free' \
    > /etc/apt/sources.list && \
    dpkg --add-architecture i386 && \
    apt-get -o Acquire::Check-Valid-Until=false update && \
    apt-get -qqy install lib32gcc1 curl libstdc++6:i386 unzip

# create directories
WORKDIR /root
RUN mkdir -p Steam .steam

# download SteamCMD
WORKDIR /root/Steam
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# link SDK
WORKDIR /root/.steam
RUN ln -s ../Steam/linux32 sdk32

# add startup script
COPY start-server.sh /usr/local/bin/start-server.sh
RUN chmod +x /usr/local/bin/start-server.sh

WORKDIR /hlds
ENTRYPOINT ["/usr/local/bin/start-server.sh"]
