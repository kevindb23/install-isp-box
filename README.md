# ISP Box Installers

Operational installers and uninstallers for Ubuntu/Debian ISP servers.

## Included installers

| Script | Purpose |
|---|---|
| [install-accel-ppp.sh](install-accel-ppp.sh) | Builds and installs Accel-PPP with IPoE, VLAN monitoring, Lua, FRR, and iptables. |
| [install-freeradius-3.2-jammy.sh](install-freeradius-3.2-jammy.sh) | Installs FreeRADIUS 3.2 for Ubuntu Jammy from InkBridge Networks. |
| [install-acs-server.sh](install-acs-server.sh) | Downloads and runs the ACS/GenieACS setup installer. |
| [install-acs-server-setup.sh](install-acs-server-setup.sh) | Installs GenieACS, MongoDB, Node.js, and ACS services. |
| [install-billing-system.sh](install-billing-system.sh) | Fresh-server bootstrap for the ISP-Box billing system. |
| [install-billing-server.sh](install-billing-server.sh) | Installs or updates the billing application and Nginx site. |

## Requirements

- Ubuntu 22.04 Jammy or supported Debian
- amd64 architecture
- Root or sudo access
- Internet access

## Install the billing system

The bootstrap downloads the billing installer and database dump into a temporary directory, then removes the temporary files automatically.

```bash
wget -O install-billing-system.sh https://raw.githubusercontent.com/kevindb23/install-isp-box/main/install-billing-system.sh
chmod +x install-billing-system.sh
sudo ./install-billing-system.sh
```

The default application repository is [kevindb23/ISP-Box](https://github.com/kevindb23/ISP-Box), installed at:

```text
/var/www/billing-server
```

The installer installs Nginx, MySQL, PHP 8.1+, Composer, Node.js 18+, Python 3, and project dependencies. It builds the root frontend and optional `frontend-next` frontend, then configures Nginx to serve `public/`.

Options:

```bash
sudo ./install-billing-system.sh --skip-build
sudo ./install-billing-system.sh --setup-database
```

The bootstrap imports [billing.sql](billing.sql) into the `portal` database and creates the configured billing database user. Change default credentials immediately after the first login.

To use another application repository:

```bash
sudo REPOSITORY_URL=https://github.com/owner/app.git ./install-billing-system.sh
```

Useful variables include `REPOSITORY_URL`, `BRANCH`, `APP_DIR`, `SERVER_NAME`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, and `SQL_URL`.

## Uninstall the billing system

This removes the billing application, generated dependencies/build artifacts, and billing-specific Nginx configuration. Shared packages remain installed and the database is preserved by default.

```bash
wget -O uninstall-billing-system.sh https://raw.githubusercontent.com/kevindb23/install-isp-box/main/uninstall-billing-system.sh
chmod +x uninstall-billing-system.sh
sudo ./uninstall-billing-system.sh
```

Use `--yes` for automation. Use `--purge-database` only when you intentionally want to remove the configured billing database and MySQL user.

## Other installers

Each installer has its own `--help` output. Review scripts and back up production systems before installing or uninstalling network, routing, ACS, or database services.

## License

These scripts are provided as-is for operational use. Third-party components retain their respective licenses.
