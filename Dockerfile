FROM php:7.3.5-fpm-alpine
LABEL maintainer "sear-azazel<sear.azazel@gmail.com>"

# environment
ENV APP_VERSION v0.0.1
ENV APP_DIR /work

# tinker(psysh)
ARG PSYSH_DIR=/usr/local/share/psysh
ARG PHP_MANUAL_URL=http://psysh.org/manual/ja/php_manual.sqlite

# timezone
ARG TZ=Asia/Tokyo

RUN set -eux && \
  apk update && \
  apk add --update --no-cache --virtual=.build-dependencies \
    autoconf \
    gcc \
    g++ \
    make \
    tzdata && \
  apk add --update --no-cache \
    icu-dev \
    libzip-dev && \
  cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
  echo ${TZ} > /etc/timezone && \
  pecl install xdebug && \
  apk del .build-dependencies && \
  docker-php-ext-install intl pdo_mysql mbstring zip bcmath && \
  docker-php-ext-enable xdebug && \
  mkdir $PSYSH_DIR && wget $PHP_MANUAL_URL -P $PSYSH_DIR

# Config
COPY php/php.ini /usr/local/etc/php
COPY php/crontab/laravel /var/spool/cron/crontabs/root

# Application
WORKDIR /work
RUN curl -SL https://github.com/sear-azazel/firewall/archive/${APP_VERSION}.tar.gz | \
  tar -xz -C ${APP_DIR} --strip=2 --wildcards '*/src/*' && \
  chmod 777 -R ./storage ./bootstrap/cache

# Composer
RUN set -eux && \
  apk update && \
  apk add --update --no-cache unzip && \
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
  composer config -g repos.packagist composer https://packagist.jp && \
  composer global require hirak/prestissimo && \
  composer install

# Entrypoint
COPY docker-entrypoint.sh /
RUN chmod 755 /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["php-fpm"]