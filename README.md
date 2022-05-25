# aptly-automation-scripts

Collection of scripts and configurations for automated maintenance of aptly debian repositories

## Getting started

### Prepare System

1. Install incron on target system, e.g. `apt install incron`.
2. Clone this repository to target system.
3. Copy scripts and make executable:

    ```bash
    cp aptly-automation-scripts/repo_cleanup.sh /usr/local/bin/repo_cleanup && chmod +x /usr/local/bin/repo_cleanup
    cp aptly-automation-scripts/repo_update.sh /usr/local/bin/repo_update && chmod +x /usr/local/bin/repo_update
    cp aptly-automation-scripts/snapshot_cleanup.sh /usr/local/bin/snapshot_cleanup && chmod +x /usr/local/bin/snapshot_cleanup
    ```

4. Add root to `/etc/incron.allow`. (Example in this repo - configs/incron.allow)
5. Make log directory and copy logrotate config:

    ```bash
    mkdir /var/log/aptly
    cp aptly-automation-scripts/configs/logrotate.d/aptly /etc/logrotate.d/aptly
    ```

### Configure Jobs

Specify debian package location, repository name and distribution in `aptly-automation-scripts/configs/repo_cleanup.cron` & `aptly-automation-scripts/configs/repo_maintenance.incron`. Additionally, set timing for when snapshots are considered old e.g.

#### **`repo_cleanup.cron`**

```bash
15 */24 * * * /bin/bash -c "repo_cleanup /srv/repo/packages(debian package location) devops(repository name) && repo_update /srv/repo/packages(debian package location) devops(repository name) all(distribution)"
30 */12 * * * /usr/local/bin/snapshot_cleanup "-1 day"
```

#### **`repo_maintenance.incron`**

```bash
/srv/repo/packages(debian package location) IN_CREATE,IN_DELETE,IN_MOVE,IN_ONLYDIR /bin/bash -c "repo_cleanup $@ devops(repository name) && repo_update $@ devops(repository name) all(distribution)"
```

Add cronjob and incronjob from files `repo_cleanup.cron` & `repo_maintenance.incron`:

```bash
crontab aptly-automation-scripts/configs/repo_cleanup.cron
incrontab aptly-automation-scripts/configs/repo_maintenance.incron
```

## Done

### Copy Packages

Save your debian packages in the location you passed to the scripts in the jobs, e.g. `/srv/repo/packages`.

### Log Location

#### Directory

Log files will be located at:

- `/var/log/aptly/`

#### Files

Following log files will be available:

- `/var/log/aptly/repo_maintenance.log`
  - contains logs for repo_update & repo_cleanup
- `/var/log/aptly/snapshot_cleanup.log`
  - contains logs for snapshot_cleanup
