# 📖 User Documentation — Inception Stack

This document is intended for **end users and administrators** who want to interact with the Inception stack without necessarily understanding the underlying infrastructure. No prior Docker knowledge is required.

---

## 🧩 What Services Are Provided?

The Inception stack runs several services, each with a specific role:

| Service | What it does | How you access it |
|---|---|---|
| **WordPress** | The main website and blog platform | `https://mcuesta-.42.fr` |
| **WordPress Admin** | Administration panel to manage content, users, and settings | `https://mcuesta-.42.fr/wp-admin` |
| **Adminer** | Lightweight interface to browse and manage the database | `https://mcuesta-.42.fr:8080` |
| **Portainer** | Visual dashboard to monitor the status of all running containers | `https://mcuesta-.42.fr:9443` |
| **FTP Server** | File transfer access to the WordPress media and files directory | `ftp://mcuesta-.42.fr:21` |

> All web interfaces use **HTTPS** with a self-signed TLS certificate. Your browser will show a security warning on first visit — click **Advanced → Accept the risk and continue** to proceed.

---

## ▶️ Starting and Stopping the Project

All commands must be run from the **root of the repository**.

### Start the stack

```bash
make
```

This builds all the services (if not already built) and starts them in the background. The first run may take a few minutes while Docker downloads base images and compiles the configuration.

### Stop the stack (keep data)

```bash
make down
```

Stops and removes all running containers. Your data (database, uploaded files) is **preserved** on disk and will be available next time you start the stack.

### Stop the stack and delete all data

```bash
make fclean
```

⚠️ **Warning:** This removes containers, volumes, and images. All database content and uploaded files will be permanently deleted. Only use this if you want a completely fresh start.

---

## 🌐 Accessing the Website and Admin Panel

### Public website

Open your browser and go to:

```
https://mcuesta-.42.fr
```

### WordPress administration panel

```
https://mcuesta-.42.fr/wp-admin
```

Log in with the **WordPress admin credentials** (see the section below). From here you can:

- Write and publish posts and pages.
- Install and manage themes and plugins.
- Create and manage user accounts.
- Configure site settings.

### Database management (Adminer)

```
https://mcuesta-.42.fr:8080
```

Adminer gives you a graphical interface to inspect and edit the database. Log in with:

- **System:** MySQL
- **Server:** `mariadb`
- **Username / Password / Database:** See credentials section below.

### Container monitoring (Portainer)

```
https://mcuesta-.42.fr:9443
```

Portainer lets you see all running containers, their status, logs, and resource usage — without using the command line.

---

## 🔑 Locating and Managing Credentials

All credentials are stored in the `.env` file at the root of the repository. Open it with any text editor:

```bash
nano .env
```

The file contains the following credentials:

| Variable | Description |
|---|---|
| `WP_ADMIN_USER` | WordPress administrator username |
| `WP_ADMIN_PASSWORD` | WordPress administrator password |
| `WP_ADMIN_EMAIL` | WordPress administrator email |
| `WP_USER` | Secondary WordPress user (editor role) |
| `WP_USER_PASSWORD` | Secondary user password |
| `DB_USER` | MariaDB user for WordPress |
| `DB_PASSWORD` | MariaDB user password |
| `DB_ROOT_PASSWORD` | MariaDB root password (for Adminer access) |

> ⚠️ **Never share the `.env` file** or commit it to a public repository. It contains sensitive credentials.

### Changing a password

1. Edit the `.env` file with the new value.
2. Restart the stack:

```bash
make down
make
```

For a WordPress password change, you can also use the WordPress Admin panel under **Users → Your Profile**.

---

## ✅ Checking That Services Are Running Correctly

### Quick status check

```bash
docker compose ps
```

All services should show a status of `running`. If any container shows `exited` or `restarting`, something went wrong.

### View live logs

```bash
make logs
```

This streams the output from all containers in real time. Press `Ctrl+C` to stop viewing logs without stopping the services.

### Check a specific service

```bash
docker compose logs nginx
docker compose logs wordpress
docker compose logs mariadb
```

Replace the service name with whichever one you want to inspect.

### Verify the website is responding

```bash
curl -k https://mcuesta-.42.fr
```

If you get an HTML response, NGINX and WordPress are working correctly. The `-k` flag is needed because the TLS certificate is self-signed.