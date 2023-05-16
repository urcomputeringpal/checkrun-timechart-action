FROM ubuntu:22.04

RUN apt-get update; apt-get -y install \
    curl \
    jq && rm -rf /var/lib/apt/lists/* \
	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

ADD *.sh /app/

ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]