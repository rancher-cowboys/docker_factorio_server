FROM frolvlad/alpine-glibc:alpine-3.3_glibc-2.23

MAINTAINER elboletaire <elboletaire@underave.net>

WORKDIR /opt

COPY ./new_smart_launch.sh /opt/
COPY ./factorio.crt /opt/

VOLUME /opt/factorio/saves /opt/factorio/mods

EXPOSE 34197/udp
EXPOSE 27015/tcp

ENV FACTORIO_AUTOSAVE_INTERVAL=2 \
    FACTORIO_AUTOSAVE_SLOTS=3 \
    FACTORIO_AUTOSAVE_ONLY_ON_SERVER=true \
    FACTORIO_ALLOW_COMMANDS=false \
    FACTORIO_AUTO_PAUSE=true \
    VERSION=0.14.21 \
    FACTORIO_WAITING=false \
    FACTORIO_MODE=heavy \
    FACTORIO_SERVER_NAME= \
    FACTORIO_SERVER_DESCRIPTION= \
    FACTORIO_SERVER_MAX_PLAYERS= \
    FACTORIO_SERVER_VISIBILITY_LAN=true \
    FACTORIO_SERVER_VISIBILITY_PUBLIC=false \
    FACTORIO_USER_USERNAME= \
    FACTORIO_USER_PASSWORD= \
    FACTORIO_SERVER_GAME_PASSWORD= \
    FACTORIO_ONLY_ADMINS_CAN_PAUSE=true \
    FACTORIO_SERVER_VERIFY_IDENTITY= \
    FACTORIO_SERVER_ADMINS= \
    FACTORIO_SERVER_ALLOW_COMMANDS=admins-only

RUN apk --update add bash curl && \
    curl -sSL --cacert /opt/factorio.crt https://www.factorio.com/get-download/$VERSION/headless/linux64 -o /tmp/factorio_headless_x64_$VERSION.tar.gz && \
    tar xzf /tmp/factorio_headless_x64_$VERSION.tar.gz && \
    rm /tmp/factorio_headless_x64_$VERSION.tar.gz && \
    apk del curl

ENTRYPOINT ["./new_smart_launch.sh"]
