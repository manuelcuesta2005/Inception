FROM debian:bullseye

RUN apt-get update -y && apt-get upgrade -y &&\
    apt-get install -y mariadb-server \
    mariadb-client \
    procps \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
