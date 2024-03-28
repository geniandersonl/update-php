FROM ubuntu:22.04

LABEL maintainer="geniandersonl@gmail.com"
LABEL description="Esta é uma imagem Docker é para teste de atualização do php"
LABEL version="1.0"

ENV TZ="Europe/Lisbon"

RUN apt update && apt upgrade -y \
    && apt -y install software-properties-common \
      tzdata \
    && add-apt-repository ppa:ondrej/php \
    && apt update \
    && apt -y install apache2 \
      php8.1 \
    && ln -sf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /scripts

EXPOSE 80

CMD ["tail", "-f", "/dev/null"]