#!/bin/ash
set -e

cd /work

if [ ! -f .env ]; then
    cp .env.example .env
    php artisan key:generate
fi

sed -i -e "s/DB_HOST=.*/DB_HOST=${DB_HOST:-db}/" .env
sed -i -e "s/DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD:-password}/" .env

php artisan migrate

if [ "${1#-}" != "$1" ]; then
    set -- php-fpm "$@"
fi

exec "$@"