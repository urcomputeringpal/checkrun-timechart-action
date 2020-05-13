FROM ubuntu:18.04

RUN apt-get update; apt-get -y install \
    curl \
    jq

ADD *.sh /app/

ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]