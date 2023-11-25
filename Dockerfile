FROM debian:bookworm-slim

# Environment Variables
ENV SERVERDIR "/garrysmod-server"
ENV CONTENTDIR "/garrysmod-content"
ENV MAP="cs_militia"
ENV GAMEMODE="sandbox"
ENV PORT="27015"
ENV MAXPLAYERS="32"

RUN \
  DEBIAN_FRONTEND=noninteractive sh -c '{ \
    set -e; \
    apt-get -q update; \
    apt-get -qy dist-upgrade; \
    apt-get -qy install lib32stdc++6 curl python3 git; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists; \
  }'

RUN \
  groupadd -r gameserver && useradd -r -g gameserver gameserver \
  && mkdir -p /steamcmd \
  && chown -R gameserver:gameserver /steamcmd \
  && mkdir -p ${SERVERDIR} \
  && chown -R gameserver:gameserver ${SERVERDIR} \
  && mkdir -p ${CONTENTDIR} \
  && chown -R gameserver:gameserver ${CONTENTDIR}

# Switch to the gmod user
USER gameserver

RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C /steamcmd \
  && /steamcmd/steamcmd.sh +login anonymous +force_install_dir "${SERVERDIR}" +app_update 4020 validate +quit \
  && /steamcmd/steamcmd.sh +login anonymous +force_install_dir "${CONTENTDIR}" +app_update 232330 validate +quit

COPY ./dev/server/entrypoint.py /entrypoint.py

COPY ./dev/server/users.txt ${SERVERDIR}/garrysmod/settings/users.txt
COPY ./dev/server/mount.cfg ${SERVERDIR}/garrysmod/cfg/mount.cfg

RUN mkdir -p "${SERVERDIR}/garrysmod/addons/" \
    && git clone https://github.com/TeamUlysses/ulx "${SERVERDIR}/garrysmod/addons/ulx/" \
    && git clone https://github.com/TeamUlysses/ulib "${SERVERDIR}/garrysmod/addons/ulib/"
# RUN git clone https://github.com/h3xcat/gmod-mappatcher.git --recurse-submodules "${SERVERDIR}/garrysmod/addons/gmod-mappatcher/" 
COPY . ${SERVERDIR}/garrysmod/addons/gmod-mappatcher/

COPY .gslt_token /.gslt_token

# Expose ports
EXPOSE 27015/tcp \
       27036/tcp \
       27015/udp \
       27020/udp \
       27031-27036/udp

ENTRYPOINT ["/usr/bin/python3", "/entrypoint.py"]