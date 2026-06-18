FROM debian:bullseye

RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install -y wget tar ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data

RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then PORTAINER_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then PORTAINER_ARCH="arm64"; \
    else PORTAINER_ARCH="amd64"; fi && \
    wget https://github.com/portainer/portainer/releases/download/2.21.5/portainer-2.21.5-linux-${PORTAINER_ARCH}.tar.gz && \
    tar -xvzf portainer-2.21.5-linux-${PORTAINER_ARCH}.tar.gz && \
    rm -rf portainer-2.21.5-linux-${PORTAINER_ARCH}.tar.gz

EXPOSE 9443

CMD ["./portainer/portainer", "--data", "/data"]