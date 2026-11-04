# roboshop-ansible

Ansible project to deploy RoboShop components on existing AWS servers (RHEL 9, `us-east-1`).

## Prerequisites

- Ansible installed on the control node (this workstation)
- Network access from the control node to the application servers
- SSH as `ec2-user` (password `DevOps321`) with sudo

## Inventory

Each component runs against its private DNS name:

| Component | Inventory host |
| --------- | -------------- |
| Frontend  | `frontend.hdevops09.online` |
| MySQL     | `mysql.hdevops09.online` |
| Catalogue | `catalogue.hdevops09.online` |

## Deployment order

Follow the setup order from `00-overview.md` (UI journey):

1. **Frontend** — Nginx and static UI; the storefront loads in the browser, but API calls fail until backend services are running
2. **MySQL** — shared database required by Catalogue (and other services later)
3. **Catalogue** — product listings; `/api/catalogue/` begins working once this service and MySQL are up

## Usage

```bash
chmod +x run.sh
./run.sh frontend
./run.sh mysql
./run.sh catalogue
```

Each command runs `roboshop.yml` with `component_name` set to the argument and connects to the matching `*.hdevops09.online` host.

## Known limitations

- **MySQL root bootstrap:** The play verifies login with `mysql -u root -pRoboShop@1` first. If that fails, the rescue block runs only when passwordless `mysql -u root` (typically local socket auth) still works. It uses `CREATE USER IF NOT EXISTS` for `root@'%'`, then `ALTER USER` for both `root@'%'` and `root@'localhost'` to enforce `RoboShop@1`, followed by `GRANT` and `FLUSH PRIVILEGES`. A normal re-run skips rescue when verify succeeds. If neither verify nor passwordless local root works, the play fails and must be fixed manually. The manual doc shows `CREATE USER` without `IF NOT EXISTS`; first install matches the doc’s intent.
- **Catalogue schema load:** `schema.sql` and `app-user.sql` run only when probes show the database or user is missing. `master-data.sql` runs on every catalogue deploy (`INSERT IGNORE` in the artifact). If `schema.sql` stops after creating the `catalogue` database but before all objects exist, a re-run skips `schema.sql` because `USE catalogue` succeeds—partial schema may require manual repair. Other SQL files in `schema_files` would need matching probe logic if added later.
- **Environment hostnames:** MySQL host `mysql.hdevops09.online` is set in `roles/catalogue/templates/catalogue.service` and in `roles/common/tasks/mysql-schema.yml` per this environment’s private DNS (not in `catalogue/vars`).
- **Nginx upstreams:** `nginx.conf` uses `<component>.hdevops09.online` hostnames for all API paths per the mentor hostname correction. Only Frontend, MySQL, and Catalogue are deployed by this project; other upstream hostnames must resolve and services must exist before those API routes work.
