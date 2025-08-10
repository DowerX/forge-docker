ARG TEMURIN_TAG=21-jre-alpine-3.22
FROM eclipse-temurin:${TEMURIN_TAG} AS build

ARG FORGE_VERSION=1.21.8-58.0.5
ADD --chmod=555 https://maven.minecraftforge.net/net/minecraftforge/forge/${FORGE_VERSION}/forge-${FORGE_VERSION}-installer.jar /forge-installer.jar

RUN java -jar /forge-installer.jar --installServer /minecraft

FROM eclipse-temurin:${TEMURIN_TAG}

ARG UID=1001
ARG GID=1001
ARG USERNAME=minecraft

RUN \
  addgroup \
    -g "${GID}" \
    "${USERNAME}" && \
  adduser \
    -D -H \
    -u "${UID}" \
    -G "${USERNAME}" \
    "${USERNAME}" && \
  mkdir /data && \
  chown \
    ${USERNAME}:${USERNAME} \
    /data

WORKDIR /data

COPY \
  --chmod=555 \
  entry /entry

COPY \
  --from=build \
  --chown=${USERNAME}:${USERNAME} \
  /minecraft /minecraft

HEALTHCHECK \
  --interval=30s \
  --timeout=30s \
  --start-period=60s \
  --retries=3 \ 
  CMD [ "nc", "-z", "127.0.0.1:25565" ]

USER ${USERNAME}

EXPOSE 25565
EXPOSE 25575

VOLUME [ "/data" ]

ENV JAVA_FLAGS="-Xms4096M -Xmx4096M -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true"

ENTRYPOINT [ "/entry" ]