FROM ubuntu

# Install dependencies
# lib32gcc1 is required to run steamcmd, as it is only available in 32-bit
RUN apt-get update && apt-get install -y \
    curl \
    lib32gcc1 \
    unzip \
  && rm -rf /var/lib/apt/lists/*

# Install L4D2 via steamcmd
# TODO: don't silence all curls to aid debugging
RUN mkdir -p /opt/steamcmd \
  && cd /opt/steamcmd \
  && curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar xzv \
  && ./steamcmd.sh \
    +login anonymous \
    +force_install_dir /opt/l4d2 \
    +app_update 222860 validate \
    +quit \
  # Create user with reduced permissions
  && echo 222860 > /opt/l4d2/steam_appid.txt \
  && useradd l4d2 \
  && mkdir -p /opt/l4d2 \
  && chown -R l4d2:l4d2 /opt/l4d2

USER l4d2
WORKDIR /opt/l4d2

# Install Metamod and SourceMod, mods and plugins
RUN cd /opt/l4d2/left4dead2 \
  # Metamod
  && curl -sL "http://www.gsptalk.com/mirror/sourcemod/mmsource-1.10.6-linux.tar.gz" | tar xzv \
  # SourceMod
  && curl -sL "https://sm.alliedmods.net/smdrop/1.8/sourcemod-1.8.0-git5974-linux.tar.gz" | tar xzv \
  # Extensions
  && cd /opt/l4d2/left4dead2/addons/sourcemod \
  # Left 4 Downtown 0.4.7.0
    && curl -OJL "https://forums.alliedmods.net/attachment.php?attachmentid=111241&d=1350927414" \
    && unzip left4downtown2-v0.5.4.2-playerslots.zip \
    && rm    left4downtown2-v0.5.4.2-playerslots.zip \
    # Rebuilt playerslots plugin for newer source SDK
    && curl -L "https://forums.alliedmods.net/attachment.php?attachmentid=122279&d=1373208124" > extensions/left4downtown.ext.2.l4d2.so \
  # Plugins
  && cd /opt/l4d2/left4dead2/addons/sourcemod/plugins \
  # Remove Lobby Reservation (When Full) 1.1.1
    && curl -OJL "https://forums.alliedmods.net/attachment.php?s=a70c44be158857514bce5011cd5eae30&attachmentid=56932&d=1262977327" \
  # Bebop (for managing greater than 4 players in co-op)
    && curl -OJL "https://forums.alliedmods.net/attachment.php?attachmentid=54217&d=1259334888" \
    && unzip bebop_0.2beta.zip \
    && rm    bebop_0.2beta.zip

# Copy extra configuration files
COPY cfg/* /opt/l4d2/left4dead2/cfg/
COPY sourcemod/* /opt/l4d2/left4dead2/addons/sourcemod/configs/

EXPOSE 27015/tcp 27015/udp
WORKDIR /opt/l4d2
CMD ["/opt/l4d2/srcds_run", "-game", "left4dead2", "-usercon", "-ip 0.0.0.0", "+maxplayers 18"]
