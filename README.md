# ISP Box Installers

Installation and removal scripts for an Ubuntu-based ISP service box.

## Included installers

| Script | Purpose |
|---|---|
| [install-accel-ppp.sh](install-accel-ppp.sh) | Builds and installs Accel-PPP, FRR, FRR Python tools, and iptables. Enables IPv4/IPv6 forwarding. |
| [install-freeradius-3.2-jammy.sh](install-freeradius-3.2-jammy.sh) | Installs FreeRADIUS 3.2 from the InkBridge Networks repository on Ubuntu Jammy 22.04 amd64. |
| [install-acs-server.sh](install-acs-server.sh) | Downloads, converts, and runs the ACS/GenieACS setup installer. |
| [install-acs-server-setup.sh](install-acs-server-setup.sh) | Full GenieACS, MongoDB, Node.js, and service installation script. |
| [install-billing-server.sh](install-billing-server.sh) | Installs the Laravel/PHP billing application, dependencies, frontend builds, and Nginx configuration. |

## Requirements

- Ubuntu 22.04 Jammy
- amd64 architecture
- Root or sudo access
- Internet access
- A current kernel with matching Linux headers
- A server backup before installing or uninstalling network services

The Accel-PPP installer compiles from the upstream Git repository and may take several minutes.

## Install Accel-PPP, FRR, and iptables

```bash
wget -O install-accel-ppp.sh https://raw.githubusercontent.com/kevindb23/install-isp-box/main/install-accel-ppp.sh
chmod +x install-accel-ppp.sh
sudo ./install-accel-ppp.sh
```

The installer:

- Builds Accel-PPP with IPoE, VLAN monitoring, and Lua support.
- Installs the generated Debian package.
- Installs FRR and `frr-pythontools` from the official FRR repository.
- Installs `iptables`.
- Enables IPv4 and IPv6 forwarding.
- Enables and starts the Accel-PPP and FRR services.
- Preserves an existing `/etc/accel-ppp.conf`.

Review and customize the Accel-PPP configuration before production use:

```bash
sudo nano /etc/accel-ppp.conf
sudo systemctl status accel-ppp frr
```

FRR protocols such as BGP and OSPF are not enabled automatically. Configure `/etc/frr/daemons`, then restart FRR.

## Install FreeRADIUS 3.2

This installer is specifically for Ubuntu Jammy 22.04 amd64:

```bash
wget -O install-freeradius-3.2-jammy.sh https://raw.githubusercontent.com/kevindb23/install-isp-box/main/install-freeradius-3.2-jammy.sh
chmod +x install-freeradius-3.2-jammy.sh
sudo ./install-freeradius-3.2-jammy.sh
```

It installs `freeradius` and `freeradius-utils` from InkBridge Networks and preserves existing FreeRADIUS configuration.

## Install the ACS server

The wrapper installs `dos2unix`, downloads the full setup script, converts it to Unix line endings, and runs it:

```bash
wget -O install-acs-server.sh https://raw.githubusercontent.com/kevindb23/install-isp-box/main/install-acs-server.sh
chmod +x install-acs-server.sh
sudo ./install-acs-server.sh
```

The ACS setup creates GenieACS services for CWMP, NBI, FS, and UI, plus MongoDB and log rotation. Review the attached setup assumptions before using it on a production server.

## Uninstalling

Accel-PPP:

```bash
wget -O uninstall-accel-ppp.sh https://raw.githubusercontent.com/kevindb23/install-isp-box/main/uninstall-accel-ppp.sh
chmod +x uninstall-accel-ppp.sh
sudo ./uninstall-accel-ppp.sh
```

Use `--purge-config` to also remove `/etc/accel-ppp.conf` and FRR configuration.

FreeRADIUS:

```bash
wget -O uninstall-freeradius-3.2-jammy.sh https://raw.githubusercontent.com/kevindb23/install-isp-box/main/uninstall-freeradius-3.2-jammy.sh
chmod +x uninstall-freeradius-3.2-jammy.sh
sudo ./uninstall-freeradius-3.2-jammy.sh
```

Use `--purge-config` to remove `/etc/freeradius` and FreeRADIUS logs.

ACS/GenieACS:

```bash
wget -O uninstall-acs-server.sh https://raw.githubusercontent.com/kevindb23/install-isp-box/main/uninstall-acs-server.sh
chmod +x uninstall-acs-server.sh
sudo ./uninstall-acs-server.sh
```

The ACS uninstaller removes GenieACS, MongoDB, ACS data, services, users, logs, and related repository files. It preserves shared Node.js, npm, and `libssl1.1` packages because other software may use them.

## Safety notes

- Read each script before running it on a production server.
- The ACS uninstaller permanently removes the GenieACS/MongoDB installation and its data.
- Do not run uninstallers while active subscribers or routing sessions depend on the services.
- The scripts are intended for Ubuntu Jammy; newer Ubuntu releases may require repository or package changes.

## License

These scripts are provided as-is for operational use. Accel-PPP, FreeRADIUS, FRR, MongoDB, Node.js, and GenieACS remain under their respective licenses.


## Install the billing server

The billing server installer clones a Laravel/PHP application into **/var/www/billing-server**, installs Nginx, MySQL, PHP 8.1+, Composer, Node.js 18+, npm, Python 3, and project dependencies, then builds the root frontend and optional **frontend-next** frontend.

Set the application repository URL when running it:

    wget -O install-billing-server.sh https://raw.githubusercontent.com/kevindb23/install-isp-box/main/install-billing-server.sh
    chmod +x install-billing-server.sh
    sudo REPOSITORY_URL=https://github.com/owner/your-billing-app.git ./install-billing-server.sh

Options include **--skip-build** and **--setup-database**. The **BRANCH**, **APP_DIR**, and **SERVER_NAME** environment variables are also configurable.

The Nginx web root is **/var/www/billing-server/public**. Repeat runs update an existing checkout and do not overwrite an existing **.env** file.

## Uninstall the billing server

The uninstaller removes the cloned application and billing-specific Nginx configuration, but preserves shared MySQL, PHP, Node.js, Composer, and Nginx packages. The MySQL database is preserved unless explicitly purged.

    wget -O uninstall-billing-server.sh https://raw.githubusercontent.com/kevindb23/install-isp-box/main/uninstall-billing-server.sh
    chmod +x uninstall-billing-server.sh
    sudo ./uninstall-billing-server.sh

To also drop the database and local MySQL user, provide **DB_NAME** and **DB_USER** and use **--purge-database**.

