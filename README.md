*This project has been created as part of the 42 curriculum by mcuesta-.*

# 🐳 Inception — Multi-Container Infrastructure & DevOps Architecture

<p align="center">
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/badge/Docker__Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Compose">
  <img src="https://img.shields.io/badge/Debian_12_(Bookworm)-D10A27?style=for-the-badge&logo=debian&logoColor=white" alt="Debian">
  <img src="https://img.shields.io/badge/NGINX-009639?style=for-the-badge&logo=nginx&logoColor=white" alt="Nginx">
  <img src="https://img.shields.io/badge/WordPress_6.x-21759B?style=for-the-badge&logo=wordpress&logoColor=white" alt="WordPress">
  <img src="https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white" alt="MariaDB">
</p>

---

## 📝 Description

**Inception** is a System Administration and Infrastructure project that marks the transition into microservices virtualization. The goal is to design and build a robust, fully isolated multi-container network from scratch, without utilizing pre-built automated images from Docker Hub.

Every single service in this repository runs its own custom configuration over a raw **Debian Bookworm** base, ensuring strict compliance with enterprise-grade security protocols, data persistence, and service decoupling.

---

## 🏗️ Project Architecture & Deep Flow

Unlike basic setups, this infrastructure separates the web server (`NGINX`), the application processor (`WordPress`), and the storage layer (`MariaDB`) into standalone microservices that talk to each other through a private, secured virtual bridge.

```text
       [ Public Client ]
               │ (Port 443 - HTTPS / TLSv1.3)
               ▼
   ┌───────────────────────┐
   │        NGINX          │ ◄─── (Static Portfolio Site)
   └───────────┬───────────┘
               │ (FastCGI Protocol / Port 9000)
               ▼
   ┌───────────────────────┐          ┌───────────────────────┐
   │   WordPress-FPM       │ ◄──────► │      Redis Cache      │
   └───────────┬───────────┘          └───────────────────────┘
               │ (SQL Protocol / Port 3306)
               ▼
   ┌───────────────────────┐          ┌───────────────────────┐
   │        MariaDB        │ ◄──────► │        Adminer        │
   └───────────────────────┘          └───────────────────────┘
               ▲                                  ▲
               │ (Shared Volume Data)             │ (Shared Network)
   ┌───────────────────────┐          ┌───────────────────────┐
   │      FTP Server       │          │       Portainer       │
   └───────────────────────┘          └───────────────────────┘
```

## 🛰️ Core Component Breakdown

- 🔒 **`NGINX` (The Shield):** The absolute and only entry point from the outside world. It strictly listens on port 443 using modern TLSv1.2/TLSv1.3 encryption keys. It directly hosts the static bonus site and routes dynamic PHP requests to WordPress using the FastCGI protocol.
- ⚙️ **`WordPress` + `PHP 8.2`:** Stripped of any web server overhead, it runs purely as a PHP-FPM background daemon. On its initial boot, a custom entrypoint script injects WP-CLI to download, provision, and install the WordPress core instantly, bypassing any manual web wizards.
- 🗄️ **`MariaDB`:** The relational database instance. It is completely blind to the host machine and external internet. It communicates strictly through the private inception network on port 3306.
- 🚀 **`Premium Bonus Stack`:**
  - **`Portainer`:** Graphical administration deck mapped directly to the local Docker socket to audit container states in real-time.
  - **`Redis Cache`:** In-memory object caching layer that reduces MariaDB query workloads, boosting performance.
  - **`FTP Server`:** Dedicated file transfer protocol securely mapped over the WordPress runtime folder for direct assets management.
  - **`Adminer`:** Lightweight, single-file database management dashboard.

---

## 🔬 Project Description — Design Choices & Technical Comparisons

### Why Docker?

This project uses **Docker** to containerize each service in strict isolation. Instead of deploying everything on a single machine or virtual environment, each component (NGINX, WordPress, MariaDB, etc.) lives in its own container with its own filesystem, process space, and network interface. This guarantees that a failure or misconfiguration in one service does not cascade to others, and that the entire stack can be reproduced identically on any host.

All images are built from a raw **Debian Bookworm** base — no pre-built images from Docker Hub — to maximize control over the software stack and enforce security best practices.

---

### ⚙️ Virtual Machines vs Docker

| Feature | Virtual Machines | Docker Containers |
|---|---|---|
| **Isolation** | Full OS-level isolation (hypervisor) | Process-level isolation (kernel namespaces) |
| **Boot time** | Minutes | Milliseconds |
| **Resource usage** | Heavy (full OS per VM) | Lightweight (shared kernel) |
| **Portability** | Low (large disk images) | High (layered images, registries) |
| **Use case** | Full system emulation, legacy OS support | Microservice deployment, CI/CD pipelines |

VMs virtualize entire hardware stacks and run a complete OS per instance, which provides stronger isolation but at a significantly higher resource cost. Docker containers share the host kernel, making them far more efficient — a perfect fit for a microservices architecture where dozens of services may need to coexist on a single machine.

---

### 🔐 Secrets vs Environment Variables

| Feature | Docker Secrets | Environment Variables |
|---|---|---|
| **Storage** | Encrypted at rest (Swarm) / tmpfs in container | Plaintext in compose file or shell |
| **Exposure risk** | Not visible via `docker inspect` | Visible in process list and `docker inspect` |
| **Use case** | Passwords, tokens, private keys | Non-sensitive configuration (ports, hostnames) |
| **Scope** | Injected as files into `/run/secrets/` | Available as process environment variables |

This project uses a `.env` file at the Makefile level for non-sensitive configuration (e.g., domain, usernames) and keeps actual credentials out of the Docker Compose file. In a production Swarm setup, Docker Secrets would replace even those, as they are encrypted in transit and at rest, and never appear in container metadata.

---

### 🌐 Docker Network vs Host Network

| Feature | Docker Bridge Network | Host Network |
|---|---|---|
| **Isolation** | Containers in a private virtual network | Containers share the host's network stack |
| **Port mapping** | Explicit (`-p host:container`) | Direct access to all host ports |
| **Security** | High — services invisible to the outside by default | Low — no network boundary |
| **DNS** | Automatic service discovery by container name | No built-in DNS |

This project uses a **custom bridge network** (`inception`) so that all containers can communicate by service name (e.g., `wordpress`, `mariadb`) while remaining completely hidden from the host machine. Only NGINX exposes port 443 to the outside, acting as the single controlled gateway.

---

### 💾 Docker Volumes vs Bind Mounts

| Feature | Docker Volumes | Bind Mounts |
|---|---|---|
| **Managed by** | Docker engine | Host filesystem |
| **Portability** | High (no host path dependency) | Low (tied to host directory structure) |
| **Performance** | Optimized for containers | Depends on host OS and filesystem |
| **Use case** | Persistent data (databases, uploads) | Development (live code reloading) |
| **Inspection** | Via `docker volume inspect` | Direct host path access |

This project uses **named volumes** for both the MariaDB data directory and the WordPress files, ensuring data persists across container restarts without coupling the stack to a specific host directory structure. Bind mounts were deliberately avoided in production paths to maintain portability.

---

## 🚀 Instructions

### Prerequisites

- **Docker** `>= 24.x` and **Docker Compose** `>= 2.x` installed on your machine.
- A Unix-based system (Linux or macOS). On Linux, ensure your user belongs to the `docker` group.
- Port `443` must be free on the host machine.

### 1. Clone the repository

```bash
git clone https://github.com/mcuesta-/inception.git
cd inception
```

### 2. Configure environment variables

Copy the example environment file and fill in your credentials:

```bash
cp .env.example .env
```

Edit `.env` with your values:

```env
# Domain
DOMAIN_NAME=mcuesta-.42.fr

# MariaDB
DB_NAME=wordpress
DB_USER=wpuser
DB_PASSWORD=your_db_password
DB_ROOT_PASSWORD=your_root_password

# WordPress admin
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=your_wp_admin_password
WP_ADMIN_EMAIL=admin@mcuesta-.42.fr

# WordPress user
WP_USER=editor
WP_USER_PASSWORD=your_wp_user_password
WP_USER_EMAIL=editor@mcuesta-.42.fr
```

### 3. Add the domain to `/etc/hosts`

```bash
echo "127.0.0.1  mcuesta-.42.fr" | sudo tee -a /etc/hosts
```

### 4. Build and start the stack

```bash
make
```

This will build all Docker images from scratch and start every service in detached mode. The Makefile targets available are:

| Command | Description |
|---|---|
| `make` | Build images and start all containers |
| `make down` | Stop and remove all containers |
| `make clean` | Stop containers and remove volumes |
| `make fclean` | Full cleanup: containers, volumes, and images |
| `make re` | Full rebuild from scratch |
| `make logs` | Stream logs from all containers |

### 5. Access the services

Once running, the following endpoints are available:

| Service | URL |
|---|---|
| WordPress site | `https://mcuesta-.42.fr` |
| Portainer | `https://mcuesta-.42.fr:9443` |
| Adminer | `https://mcuesta-.42.fr:8080` |
| FTP Server | `ftp://mcuesta-.42.fr:21` |

> **Note:** Since TLS certificates are self-signed, your browser will show a security warning on first access. Accept the exception to proceed.

---

## 📚 Resources

### Official Documentation

- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress CLI (WP-CLI)](https://wp-cli.org/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
- [Redis Documentation](https://redis.io/docs/)

### Articles & Tutorials

- [Docker Networking Deep Dive](https://docs.docker.com/network/)
- [Docker Volumes vs Bind Mounts](https://docs.docker.com/storage/volumes/)
- [Understanding Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)
- [TLS/SSL with NGINX](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [PHP-FPM and NGINX FastCGI](https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/)
- [WordPress Object Cache with Redis](https://developer.wordpress.org/reference/classes/wp_object_cache/)

### AI Usage

During the development of this project, AI assistance (Claude by Anthropic) was used for the following tasks:

- **Dockerfile debugging:** Identifying misconfigurations in entrypoint scripts, environment variable propagation, and service startup ordering.
- **NGINX configuration:** Generating and validating TLS configuration blocks, FastCGI pass directives, and virtual host rules.
- **WP-CLI scripting:** Drafting the WordPress automated provisioning script to bypass the web installation wizard.
- **README writing:** Structuring and drafting sections of this document, including the technical comparison tables.
