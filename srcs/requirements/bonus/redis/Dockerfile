FROM debian:bullseye

RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install -y redis-server php-redis && \
    rm -rf /var/lib/apt/lists/*

COPY tools/redis.sh /usr/local/bin/redis.sh

RUN chmod +x /usr/local/bin/redis.sh

EXPOSE 6379

ENTRYPOINT [ "/usr/local/bin/redis.sh" ]