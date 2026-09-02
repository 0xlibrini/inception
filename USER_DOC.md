# USER_DOC.md — User & Administrator Documentation

Welcome to the **Inception** stack documentation! This guide explains in clear, simple terms how to operate, access, manage, and verify the multi-container web infrastructure.

---

## 1. Services Provided by the Stack

The infrastructure is composed of three isolated, dedicated services:

1. **NGINX Web Server** (`nginx` container):
   * Serves as the sole public gateway to your infrastructure.
   * Encrypts all traffic using **TLS v1.2 / v1.3** on port **443** (HTTPS).
   * Forwards dynamic PHP requests to WordPress via the FastCGI protocol.

2. **WordPress CMS** (`wordpress` container):
   * Powers the website content, user management, and blog administration.
   * Runs **PHP-FPM 8.2** on port **9000** without a public web server interface.

3. **MariaDB Database** (`mariadb` container):
   * Stores all site data, posts, user profiles, and system settings securely.
   * Operates internally on port **3306**, isolated inside the private container network.

---

## 2. Starting and Stopping the Project

All operational controls are automated using `make` commands from the repository root directory (`/home/${USER}/Desktop/inception`).

### To Start the Project:
Run the following command in your terminal:
```bash
make
```
* **What happens**: Creates local data storage folders (`/home/${USER}/data/mariadb` and `/home/${USER}/data/wordpress`), builds custom Docker container images, and starts all services in the background.

### To Stop the Project:
Run the following command:
```bash
make down
```
* **What happens**: Safely stops and removes all running containers and networks. Your website and database data remain safely preserved on the host disk.

---

## 3. Accessing the Website and Administration Panel

### Frontend Website
* **URL**: `https://login.42.fr` (or your configured `DOMAIN_NAME` / `https://localhost`)
* Open your browser and navigate to the address. Since the SSL certificate is self-signed, accept the browser security warning to proceed.

### WordPress Administration Panel
* **URL**: `https://login.42.fr/wp-admin`
* Use this panel to manage site content, plugins, themes, and users.

---

## 4. Locating and Managing Credentials

All secret keys, database credentials, and admin user logins are stored centrally in the environment configuration file:

📁 **Location**: `srcs/.env`

### Credentials Reference Table:

| Parameter | Environment Variable | Default / Description |
| :--- | :--- | :--- |
| **Domain Name** | `DOMAIN_NAME` | Website domain (e.g. `login.42.fr`) |
| **Database Name** | `MYSQL_DATABASE` | MariaDB database name (e.g. `wordpress`) |
| **Database User** | `MYSQL_USER` | WordPress database user account |
| **Database Password** | `MYSQL_PASSWORD` | Password for the database user |
| **Database Root Password** | `MYSQL_ROOT_PASSWORD` | Administrative password for MariaDB |
| **WP Admin Username** | `WP_ADMIN_USER` | WordPress Super Administrator username |
| **WP Admin Password** | `WP_ADMIN_PASSWORD` | Password for WP Admin login |
| **WP Admin Email** | `WP_ADMIN_EMAIL` | Email associated with Administrator account |
| **WP Regular User** | `WP_USER` | Second non-admin WordPress user |
| **WP Regular Password** | `WP_USER_PASSWORD` | Password for second WordPress user |

### How to Change Credentials:
1. Stop the running project: `make down`
2. Edit the variables in `srcs/.env`.
3. If changing database passwords or database names for a fresh setup, clear the host data folder (`rm -rf /home/${USER}/data/mariadb/* /home/${USER}/data/wordpress/*`).
4. Restart the stack: `make`

---

## 5. Checking Service Health & Status

You can verify that all components of the stack are working properly using standard Docker commands:

### 1. Check Running Containers
Execute:
```bash
docker ps
```
**Expected Result**: You should see 3 containers listed (`nginx`, `wordpress`, `mariadb`) with the status `Up`.

### 2. View Service Logs
To inspect logs or debug a specific container:
```bash
# View NGINX logs
docker logs nginx

# View WordPress logs
docker logs wordpress

# View MariaDB logs
docker logs mariadb
```

### 3. Test Database Connection
To test if MariaDB is responding to requests:
```bash
docker exec mariadb mariadb-admin -u root -p$(grep MYSQL_ROOT_PASSWORD srcs/.env | cut -d'=' -f2) ping
```
**Expected Result**: `mysqld is alive`
