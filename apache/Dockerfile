FROM httpd:2.4.41-alpine

MAINTAINER Sherin Bloemendaal <info@spbsoftwareontwikkeling.nl>

ADD conf.d/ /usr/local/apache2/conf/conf.d/
ADD mods.d/ /usr/local/apache2/conf/mods.d/
ADD sites.d/ /usr/local/apache2/conf/sites.d/

ADD ports.conf /usr/local/apache2/conf/ports.conf
ADD httpd.conf /usr/local/apache2/conf/httpd.conf
ADD magic /usr/local/apache2/conf/magic
ADD mime.types /usr/local/apache2/conf/mime.types
ADD original /usr/local/apache2/conf/original

ADD www/ /usr/local/apache2/htdocs

EXPOSE 80 443

VOLUME /usr/local/apache2/htdocs
VOLUME /usr/local/apache2/conf/sites.d/

WORKDIR /usr/local/apache2
