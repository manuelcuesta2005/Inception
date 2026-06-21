FROM debian:bookworm

RUN apt-get update -y &&  \
    apt-get install -y vsftpd && \
    rm -rf /var/lib/apt/lists/*

COPY tools/ftp.sh /usr/local/bin/ftp.sh
RUN chmod +x /usr/local/bin/ftp.sh

EXPOSE 20 21 40000-40005

ENTRYPOINT [ "/usr/local/bin/ftp.sh" ]