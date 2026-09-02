# Inception - Infrastructure & Containerization

## 1. Project Description

**Inception** is a System Administration and DevOps project designed to deepen understanding of virtualization, containerization, and service orchestration using **Docker** and **Docker Compose**.

The goal of the project is to set up a small-scale, multi-container web infrastructure operating in a fully isolated, secure environment. Every service runs inside its dedicated container, built from scratch using custom `Dockerfile`s based on `debian:12` (Debian Bookworm).

### Sources & Directory Structure

The project is structured according to strict organizational requirements:

```text
inception/
├── Makefile
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── conf/50-server.cnf
        │   ├── tools/setup.sh
        │   └── Dockerfile
        ├── nginx/
        │   ├── conf/nginx.conf
        │   ├── tools/setup.sh
        │   └── Dockerfile
        └── wordpress/
            ├── conf/www.conf
            ├── tools/setup.sh
            └── Dockerfile
```

* **`Makefile`**: Automates environment creation (`/home/${USER}/data/mariadb`, `/home/${USER}/data/wordpress`), building images, and starting/stopping services using `docker compose`.
* **`srcs/docker-compose.yml`**: Orchestrates the service containers, networks, and persistent volume definitions.
* **`srcs/.env`**: Centralized configuration file containing environment variables (database credentials, domain names, user accounts).
* **`srcs/requirements/mariadb/`**: Contains custom build context for MariaDB 10.11 database server.
* **`srcs/requirements/wordpress/`**: Contains custom build context for WordPress running PHP-FPM (PHP 8.2) and configured using WP-CLI.
* **`srcs/requirements/nginx/`**: Contains custom build context for NGINX HTTP web server, configured exclusively for TLS v1.2/v1.3 on port 443.

---

## 2. Instructions

### Prerequisites
* **Operating System**: Linux (Debian/Ubuntu recommended).
* **Software**: `docker`, `docker-compose-v2` (or `docker compose`), `make`.
* **Domain Name Resolution**: Map your domain name (e.g. `login.42.fr`) to `127.0.0.1` in `/etc/hosts`:
  ```bash
  sudo echo "127.0.0.1 login.42.fr" >> /etc/hosts
  ```
* **Environment Configuration**: Create the `srcs/.env` file with required variables (`MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `DOMAIN_NAME`, `WP_TITLE`, `WP_ADMIN_USER`, `WP_ADMIN_PASSWORD`, `WP_ADMIN_EMAIL`, etc.).

### Execution & Compilation Commands

| Command | Description |
| :--- | :--- |
| `make` / `make up` | Creates data directories (`/home/${USER}/data/...`), builds container images, and starts services in detached mode (`docker compose up --build -d`). |
| `make down` | Gracefully stops and removes all running containers and networks. |
| `docker ps` | Verifies that all 3 containers (`nginx`, `wordpress`, `mariadb`) are active and healthy. |
| `docker logs <container_name>` | Views live logs for a specific service (`mariadb`, `wordpress`, or `nginx`). |

### Verification & Testing
1. Access the web application via HTTPS in your browser: `https://login.42.fr` (or your configured domain name).
2. Accept the self-signed SSL/TLS certificate warning.
3. Test database persistence by stopping services (`make down`), restarting them (`make`), and verifying that existing WordPress data remains intact.

---

## 3. Main Design Choices

1. **Base Operating System (`debian:12`)**:
   All services are built using `debian:12` (Bookworm) as the common base image. This ensures a uniform operating system layer, glibc consistency, and reliable package resolution via `apt`.

2. **Single Responsibility Principle (1 Container per Service)**:
   - **`nginx`**: Acts as the single entry point to the infrastructure, handling HTTPS traffic over port 443 with self-signed SSL/TLS certificates.
   - **`wordpress`**: Runs PHP-FPM 8.2 without its own HTTP web server, listening on port 9000 to process FastCGI requests from NGINX.
   - **`mariadb`**: Database server running on port 3306, inaccessible to the outside world, storing all WordPress data.

3. **Isolated Network Topology**:
   - A dedicated Docker bridge network (`inception`) connects all three containers.
   - Only NGINX exposes port `443` to the host system. `wordpress` (port 9000) and `mariadb` (port 3306) are not exposed to the host machine or external internet.

4. **Persistent Storage**:
   - Database files (`/var/lib/mysql`) and WordPress website files (`/var/www/html`) are persisted on the host file system under `/home/${USER}/data/mariadb` and `/home/${USER}/data/wordpress` using bind-mounted Docker local volumes.

---

## 4. Core Technical Comparisons

### ◦ Virtual Machines vs Docker

| Feature | Virtual Machines (VMs) | Docker Containers |
| :--- | :--- | :--- |
| **Architecture** | Includes a full Guest OS on top of a Hypervisor (Type 1 or Type 2). | Shares the host kernel; isolates processes using Linux `namespaces` and `cgroups`. |
| **Startup Time** | Slow (minutes) due to complete OS boot sequence. | Near-instantaneous (seconds/milliseconds). |
| **Resource Utilization**| High CPU, memory, and disk overhead due to duplicate OS kernels. | Lightweight, highly efficient memory and CPU consumption. |
| **Isolation Level** | Hard hardware-level isolation via hypervisor. | OS-level isolation (process separation sharing host kernel). |
| **Portability** | Heavy VM images (GBs). | Small image layers (MBs), easily distributed via registries. |

---

### ◦ Secrets vs Environment Variables

| Feature | Environment Variables (`.env`) | Docker Secrets |
| :--- | :--- | :--- |
| **Storage & Exposure** | Injected into process environment as plain text; visible via `docker inspect` or `/proc/<pid>/environ`. | Encrypted at rest (in Docker Swarm) and mounted as temporary files in `in-memory tmpfs`. |
| **Use Case** | General configuration options (hostnames, ports, non-sensitive settings). | High-security credentials (private keys, passwords, API tokens, DB credentials). |
| **Lifecycle** | Static during container lifecycle unless re-created. | Can be updated and rotated dynamically without re-building container images. |
| **Access Control** | Available to any script or process running inside the container environment. | Restricted to specific services and files within `/run/secrets/`. |

---

### ◦ Docker Network vs Host Network

| Feature | Docker Network (Bridge) | Host Network (`network_mode: host`) |
| :--- | :--- | :--- |
| **Isolation** | Creates a virtual bridge network insulating containers from host network interface. | Disables network isolation; container shares host network stack directly. |
| **Port Mapping** | Explicit port mapping required (`-p 443:443`). | Ports opened by container bind directly to host interface (no mapping needed). |
| **Security** | High. Services communicate using container names via internal DNS; ports can stay hidden. | Low. Services can collide on host ports and expose internal ports directly to public network. |
| **DNS Resolution** | Built-in embedded DNS server resolves service names (e.g. `mariadb:3306`). | Relies strictly on host `/etc/hosts` and system DNS. |

---

### ◦ Docker Volumes vs Bind Mounts

| Feature | Docker Volumes | Bind Mounts |
| :--- | :--- | :--- |
| **Management** | Fully managed by Docker (stored in `/var/lib/docker/volumes/`). | Bound directly to any user-specified host directory path (e.g. `/home/user/data`). |
| **Host System Dependency**| Independent of host directory structure and file system permissions. | Dependent on host directory paths and host OS permissions/UIDs. |
| **Performance** | Optimized performance across platforms (Linux, macOS, Windows). | Excellent performance on Linux, but can suffer latency on non-native OS wrappers. |
| **Use Case** | Database storage, persistent container state managed by Docker CLI. | Host-to-container code sharing, dev hot-reloading, explicit directory binding. |

---

## 5. Resources & AI Usage

### References & Documentation
* [Docker Official Documentation](https://docs.docker.com/) — Reference for `Dockerfile` syntax, Docker CLI commands, network drivers, and volume drivers.
* [Docker Compose Specification](https://docs.docker.com/compose/) — Reference for multi-container orchestration syntax and service declarations.
* [MariaDB Official Knowledge Base](https://mariadb.com/kb/en/documentation/) — Reference for MariaDB server configuration (`50-server.cnf`) and database initialization (`mariadb-install-db`).
* [NGINX Core Documentation](https://nginx.org/en/docs/) — Directives reference for TLS/SSL configuration (`ssl_protocols`, `ssl_certificate`) and FastCGI proxying (`fastcgi_pass`).
* [WP-CLI Command Line Interface](https://developer.wordpress.org/cli/commands/) — Command-line interface reference for automated WordPress installation and user setup (`wp core install`, `wp user create`).

### Use of Artificial Intelligence (AI)
In accordance with project guidelines, AI assistance (Antigravity AI coding assistant powered by Gemini) was used during the project lifecycle for the following tasks:

1. **Diagnostic & Troubleshooting Support**:
   - Diagnosed MariaDB container startup crash resulting from stale/corrupted InnoDB redo log files (`ib_logfile0`) leftover from an older MariaDB version.
   - Identified permission requirements (`chown -R mysql:mysql /var/lib/mysql`) and initial system database table creation needs on empty bind-mounted host volumes.

2. **Documentation Authoring & Structuring**:
   - Formatted and generated structured Markdown documentation (`README.md`, `USER_DOC.md`, `DEV_DOC.md`).
   - Created comparative technical analysis tables (Virtual Machines vs Docker, Secrets vs Environment Variables, Docker Network vs Host Network, Docker Volumes vs Bind Mounts).
