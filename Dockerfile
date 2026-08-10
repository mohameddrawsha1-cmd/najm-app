FROM php:8.2-apache
RUN apt-get update && apt-get install -y --no-install-recommends libonig-dev \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-install pdo_mysql mbstring \
    && a2enmod rewrite headers \
    && sed -ri 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/*.conf /etc/apache2/apache2.conf
WORKDIR /var/www/html
COPY . .
RUN mkdir -p storage/logs storage/uploads \
    && chown -R www-data:www-data storage
EXPOSE 80
