FROM ubuntu:22.04

RUN apt-get update; apt-get -y install \
    curl \
    jq && rm -rf /var/lib/apt/lists/*

ADD *.sh /app/

ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]