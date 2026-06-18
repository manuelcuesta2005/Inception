FROM debian:bullseye

RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install -y python3 && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/static

COPY tools/site /var/www/static/

EXPOSE 8081

WORKDIR /var/www/static

CMD ["python3", "-m", "http.server", "8081"]