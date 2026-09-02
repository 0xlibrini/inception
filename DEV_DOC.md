# DEV_DOC.md — Developer Documentation

This document provides technical instructions for developers to set up, build, manage, debug, and inspect the **Inception** multi-container infrastructure architecture.

---

## 1. Setting Up the Environment from Scratch

### Prerequisites
* **Operating System**: Linux (Debian 12, Ubuntu 22.04+, or 42 School VM).
* **System Dependencies**: `docker.io` / `docker-ce`, `docker-compose-v2` (or `docker compose`), `make`, `curl`, `git`.
* **User Privileges**: User must belong to the `docker` group (`sudo usermod -aG docker $USER`).

### 1. Host Domain Configuration
Map your designated local domain to `127.0.0.1` in `/etc/hosts`:
```bash
sudo sh -c 'echo "127.0.0.1 anas.42.fr" >> /etc/hosts'
```

### 2. Environment Configuration (`srcs/.env`)
Create the file `srcs/.env` at the root of `srcs/`. This file stores configuration variables and secrets used by Docker Compose:

```env
# Domain & General Config
DOMAIN_NAME=anas.42.fr

# MariaDB Secrets & Config
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=wppassword123
MYSQL_ROOT_PASSWORD=rootpassword123

# WordPress Setup Config
WP_TITLE=Inception_Website
WP_ADMIN_USER=siteadmin
WP_ADMIN_PASSWORD=adminpass123
WP_ADMIN_EMAIL=admin@anas.42.fr
WP_USER=regularuser
WP_USER_PASSWORD=userpass123
WP_USER_EMAIL=user@anas.42.fr
```

> [!IMPORTANT]
> The `srcs/.env` file contains sensitive credentials and is strictly excluded from version control via `srcs/.gitignore`. Never commit `.env` files to git repositories.

---

## 2. Building & Launching the Project

The infrastructure build and deployment pipeline is automated via `Makefile` calling `docker compose`.

### Core Development Commands

```bash
# 1. Build images and start infrastructure in detached mode
make

# 2. Stop running containers and remove networks
make down

# 3. Force rebuild of all containers from scratch
make re
```

### Underlying Docker Compose Commands
Developers can also interact directly with `docker compose` using the configuration file path:

```bash
# Build images without starting
docker compose -f ./srcs/docker-compose.yml build

# Start services and view live output in foreground
docker compose -f ./srcs/docker-compose.yml up --build

# Stop and remove containers, networks, and orphan containers
docker compose -f ./srcs/docker-compose.yml down -v --remove-orphans
```

---

## 3. Container & Volume Management Commands

### Managing & Debugging Containers

```bash
# View active running containers
docker ps

# Inspect detailed configuration of a container
docker inspect mariadb

# Stream live container logs
docker logs -f wordpress
docker logs -f nginx
docker logs -f mariadb

# Access an interactive bash shell inside a container
docker exec -it wordpress bash
docker exec -it mariadb bash
docker exec -it nginx bash
```

### Managing Networks & Volumes

```bash
# List Docker networks
docker network ls

# Inspect internal bridge network connections and IP assignments
docker network inspect srcs_inception

# List Docker volumes
docker volume ls

# Inspect volume binding specifications
docker volume inspect srcs_db_data
docker volume inspect srcs_wp_data
```

### Deep Cleanup (Prune Everything)

```bash
# Remove all stopped containers, unused networks, images, and volume caches
docker system prune -a --volumes -f
```

---

## 4. Data Persistence & Storage Architecture

Data persistence in this project is handled via custom **Docker Local Bind Mount Volumes** configured in `srcs/docker-compose.yml`.

### Storage Locations on Host Machine

| Service | Container Directory | Host Storage Path | Volume Name |
| :--- | :--- | :--- | :--- |
| **MariaDB** | `/var/lib/mysql` | `/home/${USER}/data/mariadb` | `db_data` |
| **WordPress** | `/var/www/html` | `/home/${USER}/data/wordpress` | `wp_data` |

### How Data Persistence Works

1. **Automatic Directory Provisioning**: The `Makefile` automatically executes `mkdir -p /home/$(USER)/data/mariadb` and `mkdir -p /home/$(USER)/data/wordpress` prior to launching `docker compose`.
2. **Bind-Mount Specification**: `docker-compose.yml` mounts host folders directly into container filesystems using `driver_opts`:
   ```yaml
   volumes:
     db_data:
       driver: local
       driver_opts:
         type: none
         device: /home/${USER}/data/mariadb
         o: bind
     wp_data:
       driver: local
       driver_opts:
         type: none
         device: /home/${USER}/data/wordpress
         o: bind
   ```
3. **Lifecycle Independence**: Executing `make down` or removing Docker containers (`docker rm`) destroys container instances, but leaves `/home/${USER}/data/mariadb` and `/home/${USER}/data/wordpress` untouched. When `make` is executed again, MariaDB and WordPress reconnect to the existing data files on disk without data loss.
