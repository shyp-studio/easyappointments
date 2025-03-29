FROM php:8.2-apache

ARG VERSION

ENV BASE_URL="http://localhost"
ENV LANGUAGE="english"
ENV DEBUG_MODE="FALSE"
ENV GOOGLE_SYNC_FEATURE=FALSE
ENV GOOGLE_PRODUCT_NAME=""
ENV GOOGLE_CLIENT_ID=""
ENV GOOGLE_CLIENT_SECRET=""
ENV GOOGLE_API_KEY=""
ENV SMTP_HOST="smtp.example.org"
ENV SMTP_PORT="587"
ENV SMTP_AUTH="1"
ENV SMTP_USERNAME=""
ENV SMTP_PASSWORD=""
ENV SMTP_FROM_ADDRESS="info@example.org"
ENV SMTP_FROM_NAME="Example"
ENV SMTP_REPLY_TO_ADDRESS="info@example.org"
ENV SMTP_PROTOCOL="tls"
ENV SMTP_TLS="YES"

EXPOSE 80

WORKDIR /var/www/html

COPY ./docker-assets/99-overrides.ini /usr/local/etc/php/conf.d

COPY ./docker-assets/docker-entrypoint.sh /usr/local/bin

COPY . .

RUN apt-get update \
    && apt-get install -y git libfreetype-dev libjpeg62-turbo-dev libpng-dev unzip wget nano ssmtp mailutils nodejs npm bash \
	&& curl -sSL https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o - | sh -s \
      curl gd intl ldap mbstring mysqli xdebug odbc pdo pdo_mysql xml zip exif gettext bcmath csv event imap inotify mcrypt redis \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer install \
    && npm install -g npm \
    && git config core.fileMode false \
    && chmod -R 777 storage \
    && [ -d vendor ] || composer install \
    && [ -d node_modules ] || npm install \
    && [ -d assets/vendor ] || npx gulp compile \
    && docker-php-ext-enable xdebug \
    && echo "sendmail_path=/usr/sbin/ssmtp -t" >> /usr/local/etc/php/conf.d/php-sendmail.ini \
    && echo "alias ll=\"ls -al\"" >> /root/.bashrc \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && chown -R www-data:www-data .

ENTRYPOINT ["docker-entrypoint.sh"]

