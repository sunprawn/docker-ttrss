FROM php:7-fpm-alpine

WORKDIR /var/www

RUN apk add --update --no-cache git nginx curl supervisor tar \
    libpng libpng-dev icu-dev \
    && docker-php-ext-install gd pdo_mysql intl mysqli pcntl \
    && docker-php-ext-enable opcache \
    && rm -rf /var/cache/apk/* \
    && rm -rf /var/www/*

RUN git clone https://git.tt-rss.org/fox/tt-rss --depth=1 /var/www \
    && cp config.php-dist config.php

# Download plugins
WORKDIR /var/www/plugins.local

## Fever
RUN mkdir /var/www/plugins/fever && \
  curl -sL https://github.com/HenryQW/tinytinyrss-fever-plugin/archive/master.tar.gz | \
  tar xzvpf - --strip-components=1 -C /var/www/plugins/fever tinytinyrss-fever-plugin-master

# Download themes
WORKDIR /var/www/themes.local
## RSSHub
RUN curl -sL https://github.com/DIYgod/ttrss-theme-rsshub/archive/master.tar.gz | \
  tar xzvpf - --strip-components=2 -C . ttrss-theme-rsshub-master/dist/rsshub.css

RUN chown www-data:www-data -R /var/www \
    && ln -s /usr/local/bin/php /usr/bin/php

# add ttrss as the only nginx site
COPY ttrss.nginx.conf /etc/nginx/nginx.conf

# expose only nginx HTTP port
EXPOSE 80

# complete path to ttrss
ENV SELF_URL_PATH http://localhost

# expose default database credentials via ENV in order to ease overwriting
ENV DB_NAME ttrss
ENV DB_USER ttrss
ENV DB_PASS ttrss

WORKDIR /var/www

# always re-configure database with current ENV when RUNning container, then monitor all services
ADD configure-db.php /configure-db.php
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD php /configure-db.php && supervisord -c /etc/supervisor/conf.d/supervisord.conf
