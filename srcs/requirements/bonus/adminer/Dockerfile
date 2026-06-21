FROM debian:bookworm

RUN apt-get update -y &&  \
    apt-get install -y php8.2-fpm php8.2-mysql curl && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/adminer

RUN curl -L -o /var/www/adminer/index.php https://github.com/vrana/adminer/releases/download/v4.17.1/adminer-4.17.1.php

EXPOSE 8080

CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/adminer"]