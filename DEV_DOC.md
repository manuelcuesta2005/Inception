# 🛠️ Developer Documentation — Inception Stack

This document is intended for **developers** who want to set up, build, modify, or extend the Inception stack. It assumes familiarity with Docker, Linux, and the command line.

---

## 📋 Prerequisites

Make sure the following tools are installed and up to date on your system before proceeding.

| Tool | Minimum version | Check |
|---|---|---|
| Docker Engine | 24.x | `docker --version` |
| Docker Compose (plugin) | 2.x | `docker compose version` |
| GNU Make | 4.x | `make --version` |
| OpenSSL | 3.x | `openssl version` |
| Git | Any recent | `git --version` |

Your user must belong to the `docker` group to run commands without `sudo`:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Port `443` must be free on the host machine. Verify with:

```bash
ss -tlnp | grep 443
```

---

## ⚙️ Setting Up the Environment from Scratch

### 1. Clone the repository

```bash
git clone https://github.com/mcuesta-/inception.git
cd inception
```

### 2. Repository structure

```text
inception/
├── Makefile
├── .env                    # Environment variables (not committed)
├── .env.example            # Template — copy this to create .env
├── srcs/
│   ├── docker-compose.yml
│   └── requirements/
│       ├── nginx/
│       │   ├── Dockerfile
│       │   └── conf/
│       ├── wordpress/
│       │   ├── Dockerfile
│       │   └── tools/      # Entrypoint script (WP-CLI provisioning)
│       ├── mariadb/
│       │   ├── Dockerfile
│       │   └── tools/      # Entrypoint script (DB init)
│       └── bonus/
│           ├── redis/
│           ├── ftp/
│           ├── adminer/
│           └── portainer/
└── USER_DOC.md
└── DEV_DOC.md
└── README.md
```

### 3. Create the environment file

```bash
cp .env.example .env
```

Edit `.env` and fill in all required values:

```env
# Domain
DOMAIN_NAME=mcuesta-.42.fr

# MariaDB
DB_NAME=wordpress
DB_USER=wpuser
DB_PASSWORD=changeme
DB_ROOT_PASSWORD=changeme_root

# WordPress admin account
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=changeme
WP_ADMIN_EMAIL=admin@mcuesta-.42.fr

# WordPress secondary user
WP_USER=editor
WP_USER_PASSWORD=changeme
WP_USER_EMAIL=editor@mcuesta-.42.fr

# FTP
FTP_USER=ftpuser
FTP_PASSWORD=changeme
```

> All variables defined here are injected into the containers at runtime via the `env_file` directive in `docker-compose.yml`. No credentials are hardcoded in any Dockerfile.

### 4. Add the domain to `/etc/hosts`

The project uses a custom domain that must resolve to localhost:

```bash
echo "127.0.0.1  mcuesta-.42.fr" | sudo tee -a /etc/hosts
```

### 5. TLS certificates

TLS certificates are generated automatically by the NGINX container's entrypoint script using `openssl`. They are self-signed and valid for the configured `DOMAIN_NAME`. No manual certificate generation is required.

If you need to regenerate them manually:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/nginx.key \
  -out certs/nginx.crt \
  -subj "/CN=mcuesta-.42.fr"
```

---

## 🔨 Building and Launching the Project

### Full build and start

```bash
make
```

This runs `docker compose up --build -d` under the hood, building all images from their respective Dockerfiles and starting every service in detached mode.

### Makefile targets reference

| Target | Command | Description |
|---|---|---|
| `make` | `docker compose up --build -d` | Build images and start all containers |
| `make down` | `docker compose down` | Stop and remove containers (volumes intact) |
| `make clean` | `docker compose down -v` | Stop containers and delete volumes |
| `make fclean` | `docker compose down -v --rmi all` | Full teardown: containers, volumes, images |
| `make re` | `fclean` → `make` | Complete rebuild from scratch |
| `make logs` | `docker compose logs -f` | Stream logs from all containers |

### Building a single service

```bash
docker compose build nginx
docker compose build wordpress
docker compose build mariadb
```

### Restarting a single service without full rebuild

```bash
docker compose restart wordpress
```

---

## 🐳 Managing Containers and Volumes

### View running containers

```bash
docker compose ps
```

### Execute a command inside a running container

```bash
docker compose exec wordpress bash
docker compose exec mariadb bash
docker compose exec nginx sh
```

### View logs for a specific service

```bash
docker compose logs -f nginx
docker compose logs -f wordpress
docker compose logs -f mariadb
```

### Inspect a container's environment

```bash
docker inspect inception_wordpress | grep -A 20 '"Env"'
```

### List all Docker volumes

```bash
docker volume ls
```

### Inspect a volume (find its mount point on the host)

```bash
docker volume inspect inception_wordpress_data
docker volume inspect inception_mariadb_data
```

### Manually access volume data on the host

```bash
# Volume data is typically stored at:
/var/lib/docker/volumes/inception_wordpress_data/_data
/var/lib/docker/volumes/inception_mariadb_data/_data
```

> On Linux, this path requires root privileges to access directly. Prefer using `docker compose exec` to interact with data from inside the container.

---

## 💾 Data Persistence — Where It Lives and How It Works

### Named volumes

The stack uses two **named Docker volumes** to persist data across container restarts:

| Volume name | Mounted in container | Contains |
|---|---|---|
| `inception_wordpress_data` | `/var/www/html` (wordpress) | WordPress core files, themes, plugins, uploads |
| `inception_mariadb_data` | `/var/lib/mysql` (mariadb) | MariaDB database files |

Named volumes are managed by Docker and stored under `/var/lib/docker/volumes/` on the host. They are **not** deleted on `make down` — only on `make clean` or `make fclean`.

### Volume lifecycle

```text
make down     → containers removed, volumes KEPT   ✅
make clean    → containers removed, volumes DELETED ❌
make fclean   → containers, volumes, images DELETED ❌
```

### First-boot provisioning

On the very first startup, the following happens automatically:

1. **MariaDB** entrypoint script creates the database, user, and grants privileges using the values from `.env`.
2. **WordPress** entrypoint script waits for MariaDB to be ready, then uses **WP-CLI** to download WordPress core, generate `wp-config.php`, run the installer, and create admin and editor accounts — all without any manual web interaction.
3. **Redis** object cache plugin is activated automatically via WP-CLI.

On subsequent startups, the entrypoint scripts detect that data already exists in the volumes and skip the initialization steps.

### Backup and restore

To back up the database:

```bash
docker compose exec mariadb \
  mysqldump -u root -p"$DB_ROOT_PASSWORD" wordpress > backup.sql
```

To restore:

```bash
docker compose exec -T mariadb \
  mysql -u root -p"$DB_ROOT_PASSWORD" wordpress < backup.sql
```

To back up WordPress files:

```bash
docker run --rm \
  -v inception_wordpress_data:/data \
  -v $(pwd):/backup \
  debian:bookworm \
  tar czf /backup/wordpress_backup.tar.gz -C /data .
```