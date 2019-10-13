FROM ubuntu:16.04

RUN \
    DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y \
        build-essential \
        apt-utils \
        ssl-cert \
        apache2 \
        apache2-utils \
        libapache2-mod-perl2 \
        libcgi-pm-perl \
        liblocal-lib-perl \
        cpanminus \
        libexpat1-dev \
        libutf8-all-perl \
        libjson-perl \
        zip && \
    a2enmod cgid && \
    a2enmod rewrite && \
    a2dissite 000-default && \
    apt-get update -y && \
    apt-get upgrade -y && \
    apt-get -y clean

COPY localhost.conf /etc/apache2/sites-enabled/localhost.conf

VOLUME ["/usr/local/sbin"]
VOLUME ["/var/www/html"]

EXPOSE 80
